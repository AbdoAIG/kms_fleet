import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import 'database_service.dart';

/// خدمة مزامنة البيانات مع Firebase Firestore
/// البيانات محفوظة محلياً في Hive + سحابياً في Firestore
class SyncService {
  static DateTime? _lastSyncTime;
  static String _lastError = '';
  static bool _isSyncing = false;

  SyncService._();

  static bool get isSyncing => _isSyncing;
  static DateTime? get lastSyncTime => _lastSyncTime;
  static String get lastError => _lastError;

  /// مرجع Firestore - بيانات المدير فقط (UID كمفتاح)
  static CollectionReference? _vehiclesRef;
  static CollectionReference? _recordsRef;

  static void _initRefs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _vehiclesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vehicles');
    _recordsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('maintenance_records');
  }

  /// التحقق من اتصال الإنترنت
  static Future<bool> _hasInternet() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// مزامنة ثنائية الاتجاه
  /// 1. رفع البيانات المحلية للسحابة
  /// 2. تحميل البيانات السحابية ودمجها
  static Future<SyncResult> bidirectionalSync() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'مزامنة جارية بالفعل...');
    }

    _lastError = '';
    _isSyncing = true;

    try {
      // التحقق من تسجيل الدخول
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return SyncResult(
          success: false,
          message: 'غير مسجل الدخول - لا يمكن المزامنة',
        );
      }

      // التحقق من الإنترنت
      if (!await _hasInternet()) {
        return SyncResult(
          success: false,
          message: 'لا يوجد اتصال بالإنترنت',
        );
      }

      _initRefs();
      if (_vehiclesRef == null || _recordsRef == null) {
        return SyncResult(success: false, message: 'خطأ في تهيئة Firestore');
      }

      int uploadedVehicles = 0;
      int uploadedRecords = 0;
      int downloadedVehicles = 0;
      int downloadedRecords = 0;

      // === الخطوة 1: رفع المركبات المحلية ===
      final localVehicles = await DatabaseService.getAllVehicles();
      for (final vehicle in localVehicles) {
        try {
          final map = vehicle.toMap();
          // تحويل التواريخ لـ Timestamp
          map['created_at'] = FieldValue.serverTimestamp();
          map['updated_at'] = vehicle.updatedAt;

          await _vehiclesRef!.doc('${vehicle.id}').set(map, SetOptions(merge: true));
          uploadedVehicles++;
        } catch (e) {
          debugPrint('⚠️ Failed to upload vehicle ${vehicle.id}: $e');
        }
      }

      // === الخطوة 2: رفع سجلات الصيانة المحلية ===
      final localRecords = await DatabaseService.getAllMaintenanceRecords();
      for (final record in localRecords) {
        try {
          final map = record.toMap();
          map['created_at'] = FieldValue.serverTimestamp();
          map['updated_at'] = record.updatedAt;

          await _recordsRef!.doc('${record.id}').set(map, SetOptions(merge: true));
          uploadedRecords++;
        } catch (e) {
          debugPrint('⚠️ Failed to upload record ${record.id}: $e');
        }
      }

      // === الخطوة 3: تحميل البيانات من السحابة ودمجها ===
      // تحميل المركبات السحابية
      final cloudVehiclesSnap = await _vehiclesRef!.get();
      for (final doc in cloudVehiclesSnap.docs) {
        try {
          final map = Map<String, dynamic>.from(doc.data());
          map['id'] = doc.id;

          // تحويل Timestamp → DateTime
          if (map['created_at'] is Timestamp) {
            map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
          }
          if (map['updated_at'] is Timestamp) {
            map['updated_at'] = (map['updated_at'] as Timestamp).toDate().toIso8601String();
          }

          final cloudVehicle = Vehicle.fromMap(map);

          // البحث عن المركبة محلياً
          final localVehicle = await DatabaseService.getVehicleById(cloudVehicle.id);

          if (localVehicle == null) {
            // غير موجودة محلياً → إضافتها
            await DatabaseService.insertVehicle(cloudVehicle);
            downloadedVehicles++;
          } else if (cloudVehicle.updatedAt.isAfter(localVehicle.updatedAt)) {
            // السحابية أحدث → تحديث المحلية
            await DatabaseService.updateVehicle(cloudVehicle);
            downloadedVehicles++;
          }
        } catch (e) {
          debugPrint('⚠️ Failed to process cloud vehicle ${doc.id}: $e');
        }
      }

      // تحميل سجلات الصيانة السحابية
      final cloudRecordsSnap = await _recordsRef!.get();
      for (final doc in cloudRecordsSnap.docs) {
        try {
          final map = Map<String, dynamic>.from(doc.data());

          if (map['created_at'] is Timestamp) {
            map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
          }
          if (map['updated_at'] is Timestamp) {
            map['updated_at'] = (map['updated_at'] as Timestamp).toDate().toIso8601String();
          }
          if (map['maintenance_date'] is Timestamp) {
            map['maintenance_date'] = (map['maintenance_date'] as Timestamp).toDate().toIso8601String();
          }

          final cloudRecord = MaintenanceRecord.fromMap(map);

          // إضافة/تحديث السجل المحلي
          final existingRecords = await DatabaseService.getMaintenanceByVehicleId(cloudRecord.vehicleId);
          final localRecord = existingRecords.where((r) => r.id == cloudRecord.id).firstOrNull;

          if (localRecord == null) {
            await DatabaseService.insertMaintenanceRecord(cloudRecord);
            downloadedRecords++;
          } else if (cloudRecord.updatedAt.isAfter(localRecord.updatedAt)) {
            await DatabaseService.updateMaintenanceRecord(cloudRecord);
            downloadedRecords++;
          }
        } catch (e) {
          debugPrint('⚠️ Failed to process cloud record ${doc.id}: $e');
        }
      }

      // === نجاح ===
      _lastSyncTime = DateTime.now();

      return SyncResult(
        success: true,
        message: 'تمت المزامنة بنجاح\n'
            '⬆️ رُفع: $uploadedVehicles مركبة + $uploadedRecords سجل\n'
            '⬇️ نُزّل: $downloadedVehicles مركبة + $downloadedRecords سجل',
        vehiclesCount: uploadedVehicles + downloadedVehicles,
        recordsCount: uploadedRecords + downloadedRecords,
      );
    } on FirebaseException catch (e) {
      _lastError = 'Firebase: ${e.code} - ${e.message}';
      debugPrint('❌ Sync Firebase error: ${e.code} - ${e.message}');
      return SyncResult(
        success: false,
        message: _translateFirestoreError(e),
      );
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Sync error: $e');
      return SyncResult(
        success: false,
        message: 'فشل في المزامنة: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// تحميل كل البيانات من السحابة (استبدال المحلية)
  static Future<SyncResult> fullSyncFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return SyncResult(success: false, message: 'غير مسجل الدخول');
    }

    if (!await _hasInternet()) {
      return SyncResult(success: false, message: 'لا يوجد اتصال بالإنترنت');
    }

    _isSyncing = true;
    try {
      _initRefs();

      // تحميل المركبات
      final vSnap = await _vehiclesRef!.get();
      for (final doc in vSnap.docs) {
        final map = Map<String, dynamic>.from(doc.data());
        map['id'] = doc.id;
        if (map['created_at'] is Timestamp) {
          map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
        }
        if (map['updated_at'] is Timestamp) {
          map['updated_at'] = (map['updated_at'] as Timestamp).toDate().toIso8601String();
        }
        final vehicle = Vehicle.fromMap(map);
        final existing = await DatabaseService.getVehicleById(vehicle.id);
        if (existing != null) {
          await DatabaseService.updateVehicle(vehicle);
        } else {
          await DatabaseService.insertVehicle(vehicle);
        }
      }

      // تحميل السجلات
      final rSnap = await _recordsRef!.get();
      for (final doc in rSnap.docs) {
        final map = Map<String, dynamic>.from(doc.data());
        if (map['created_at'] is Timestamp) {
          map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
        }
        if (map['updated_at'] is Timestamp) {
          map['updated_at'] = (map['updated_at'] as Timestamp).toDate().toIso8601String();
        }
        if (map['maintenance_date'] is Timestamp) {
          map['maintenance_date'] = (map['maintenance_date'] as Timestamp).toDate().toIso8601String();
        }
        final record = MaintenanceRecord.fromMap(map);
        await DatabaseService.insertMaintenanceRecord(record);
      }

      _lastSyncTime = DateTime.now();
      return SyncResult(
        success: true,
        message: 'تم تحميل ${vSnap.docs.length} مركبة و ${rSnap.docs.length} سجل صيانة',
        vehiclesCount: vSnap.docs.length,
        recordsCount: rSnap.docs.length,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'فشل: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// رفع كل البيانات المحلية للسحابة
  static Future<SyncResult> uploadAllToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return SyncResult(success: false, message: 'غير مسجل الدخول');
    }

    if (!await _hasInternet()) {
      return SyncResult(success: false, message: 'لا يوجد اتصال بالإنترنت');
    }

    _isSyncing = true;
    try {
      _initRefs();

      final vehicles = await DatabaseService.getAllVehicles();
      final records = await DatabaseService.getAllMaintenanceRecords();

      // رفع المركبات
      for (final v in vehicles) {
        final map = v.toMap();
        map['updated_at'] = v.updatedAt;
        await _vehiclesRef!.doc('${v.id}').set(map, SetOptions(merge: true));
      }

      // رفع السجلات
      for (final r in records) {
        final map = r.toMap();
        map['updated_at'] = r.updatedAt;
        await _recordsRef!.doc('${r.id}').set(map, SetOptions(merge: true));
      }

      _lastSyncTime = DateTime.now();
      return SyncResult(
        success: true,
        message: 'تم رفع ${vehicles.length} مركبة و ${records.length} سجل',
        vehiclesCount: vehicles.length,
        recordsCount: records.length,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'فشل في الرفع: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// ترجمة أخطاء Firestore للعربية
  static String _translateFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'ليس لديك صلاحية الوصول للبيانات. تأكد من إعدادات Firestore Security Rules.';
      case 'not-found':
        return 'لم يتم العثور على البيانات في السحابة.';
      case 'unavailable':
        return 'الخدمة غير متوفرة حالياً. حاول لاحقاً.';
      case 'deadline-exceeded':
        return 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مرة أخرى.';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت.';
      case 'unauthenticated':
        return 'جلسة تسجيل الدخول منتهية. سجّل الدخول مرة أخرى.';
      case 'already-exists':
        return 'البيانات موجودة بالفعل.';
      default:
        return 'خطأ في المزامنة [${e.code}]: ${e.message ?? "غير معروف"}';
    }
  }
}

/// نتيجة عملية المزامنة
class SyncResult {
  final bool success;
  final String message;
  final int vehiclesCount;
  final int recordsCount;

  const SyncResult({
    required this.success,
    required this.message,
    this.vehiclesCount = 0,
    this.recordsCount = 0,
  });
}
