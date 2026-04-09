import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../utils/constants.dart';

class DatabaseService {
  static Box? _vehicleBox;
  static Box? _maintenanceBox;
  static bool _initialized = false;

  static const String _vehicleBoxName = 'kms_vehicles';
  static const String _maintenanceBoxName = 'kms_maintenance';
  static const String _metaBoxName = 'kms_meta';
  static const String _seededKey = 'seeded_v6';

  DatabaseService._();

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      _vehicleBox = await Hive.openBox(_vehicleBoxName);
      _maintenanceBox = await Hive.openBox(_maintenanceBoxName);

      final metaBox = await Hive.openBox(_metaBoxName);
      final seeded = metaBox.get(_seededKey, defaultValue: false) as bool;
      final hasVehicles = _vehicleBox!.isNotEmpty;

      // إعادة الزراعة إذا لم يكن هناك بيانات حتى لو كانت العلامة موجودة
      if (!seeded || !hasVehicles) {
        if (hasVehicles) {
          await _vehicleBox!.clear();
          await _maintenanceBox!.clear();
        }
        await _seedData();
        await metaBox.put(_seededKey, true);
        debugPrint('✅ Database seeded with ${_vehicleBox!.length} vehicles');
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Hive init error: $e');
      rethrow;
    }
  }

  static Future<void> _seedData() async {
    final now = DateTime.now().toIso8601String();
    final vehicles = _seedVehicles();
    final records = _seedRecords();

    for (int i = 0; i < vehicles.length; i++) {
      final v = vehicles[i];
      final map = v.toMap();
      map['created_at'] = now;
      map['updated_at'] = now;
      await _vehicleBox!.put(v.id, jsonEncode(map));
    }

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final map = r.toMap();
      map['created_at'] = now;
      map['updated_at'] = now;
      await _maintenanceBox!.put(r.id, jsonEncode(map));
    }
  }

  static List<Vehicle> _seedVehicles() {
    final n = DateTime.now();
    return [
      // === جامبو (Jumbo trucks) x3 ===
      Vehicle(id: 1, plateNumber: 'أ ب ج 1234', make: 'مان', model: 'جامبو', year: 2019, color: 'white', fuelType: 'diesel', currentOdometer: 185000, status: 'active', vin: 'WMA12345678901234', engineNumber: 'MAN-D2676-001', vehicleCategory: 'heavy', department: 'إدارة التوزيع', driverName: 'أحمد محمد علي', driverPhone: '01012345678', driverLicense: 'A12345678', driverLicenseExpiry: '2026-03-15', insuranceNumber: 'INS-2024-001', insuranceExpiry: '2025-06-20', registrationExpiry: '2025-12-01', createdAt: n, updatedAt: n),
      Vehicle(id: 2, plateNumber: 'د ه و 5678', make: 'إيفيكو', model: 'جامبو', year: 2021, color: 'white', fuelType: 'diesel', currentOdometer: 120000, status: 'active', vin: 'ZFA34567890123456', engineNumber: 'IVECO-CURSOR-002', vehicleCategory: 'heavy', department: 'إدارة النقل', driverName: 'محمود حسن سعيد', driverPhone: '01098765432', driverLicense: 'B23456789', driverLicenseExpiry: '2025-08-10', insuranceNumber: 'INS-2024-002', insuranceExpiry: '2025-09-15', registrationExpiry: '2025-10-20', createdAt: n, updatedAt: n),
      Vehicle(id: 3, plateNumber: 'ز ح ط 9012', make: 'مرسيدس', model: 'جامبو', year: 2020, color: 'silver', fuelType: 'diesel', currentOdometer: 210000, status: 'maintenance', vin: 'WDB56789012345678', engineNumber: 'MB-OM457-003', vehicleCategory: 'heavy', department: 'إدارة التوزيع', driverName: 'حسن إبراهيم عبدالله', driverPhone: '01155544433', driverLicense: 'C34567890', driverLicenseExpiry: '2025-11-05', insuranceNumber: 'INS-2024-003', insuranceExpiry: '2025-07-30', registrationExpiry: '2025-08-25', createdAt: n, updatedAt: n),
      // === عربية دبابة (Tanker trucks) x3 ===
      Vehicle(id: 4, plateNumber: 'ي ك ل 3456', make: 'تويوتا', model: 'دبابة', year: 2018, color: 'white', fuelType: 'diesel', currentOdometer: 250000, status: 'active', vin: 'JTE67890123456789', engineNumber: 'TOYOTA-15B-004', vehicleCategory: 'heavy', department: 'إدارة التوزيع', driverName: 'خالد حسين أحمد', driverPhone: '01234567890', driverLicense: 'D45678901', driverLicenseExpiry: '2026-01-20', insuranceNumber: 'INS-2024-004', insuranceExpiry: '2025-11-10', registrationExpiry: '2026-01-15', createdAt: n, updatedAt: n),
      Vehicle(id: 5, plateNumber: 'م ن س 7890', make: 'تويوتا', model: 'دبابة', year: 2022, color: 'white', fuelType: 'diesel', currentOdometer: 95000, status: 'active', vin: 'JTE78901234567890', engineNumber: 'TOYOTA-15B-005', vehicleCategory: 'heavy', department: 'إدارة النقل', driverName: 'عمر فاروق سليمان', driverPhone: '01077788999', driverLicense: 'E56789012', driverLicenseExpiry: '2025-05-30', insuranceNumber: 'INS-2024-005', insuranceExpiry: '2025-04-15', registrationExpiry: '2025-05-20', createdAt: n, updatedAt: n),
      Vehicle(id: 6, plateNumber: 'ع ف ق 2345', make: 'تويوتا', model: 'دبابة', year: 2020, color: 'silver', fuelType: 'diesel', currentOdometer: 175000, status: 'maintenance', vin: 'JTE89012345678901', engineNumber: 'TOYOTA-15B-006', vehicleCategory: 'heavy', department: 'إدارة التوزيع', driverName: 'سعيد عبدالله محمد', driverPhone: '01122233344', driverLicense: 'F67890123', driverLicenseExpiry: '2025-12-22', insuranceNumber: 'INS-2024-006', insuranceExpiry: '2025-08-18', registrationExpiry: '2025-09-30', createdAt: n, updatedAt: n),
      // === كلارك (Forklifts) x3 ===
      Vehicle(id: 7, plateNumber: 'ر ش ت 6789', make: 'تويوتا', model: 'كلارك', year: 2021, color: 'orange', fuelType: 'diesel', currentOdometer: 12000, status: 'active', vin: 'TKF90123456789012', engineNumber: 'TOYOTA-4Y-007', vehicleCategory: 'special', department: 'المستودعات', driverName: 'محمد حسن عادل', driverPhone: '01288877766', driverLicense: 'G78901234', driverLicenseExpiry: '2027-02-14', insuranceNumber: 'INS-2024-007', insuranceExpiry: '2026-01-05', registrationExpiry: '2026-02-28', createdAt: n, updatedAt: n),
      Vehicle(id: 8, plateNumber: 'ث خ ذ 0123', make: 'نيسان', model: 'كلارك', year: 2019, color: 'yellow', fuelType: 'diesel', currentOdometer: 8500, status: 'active', vin: 'NSK01234567890123', engineNumber: 'NISSAN-TD27-008', vehicleCategory: 'special', department: 'المستودعات', driverName: 'علي أشرف إبراهيم', driverPhone: '01044455566', driverLicense: 'H89012345', driverLicenseExpiry: '2025-06-18', insuranceNumber: 'INS-2024-008', insuranceExpiry: '2025-03-12', registrationExpiry: '2025-04-25', createdAt: n, updatedAt: n),
      Vehicle(id: 9, plateNumber: 'ض ظ غ 4567', make: 'تويوتا', model: 'كلارك', year: 2023, color: 'orange', fuelType: 'diesel', currentOdometer: 3500, status: 'active', vin: 'TKF23456789012345', engineNumber: 'TOYOTA-4Y-009', vehicleCategory: 'special', department: 'قسم الصيانة', driverName: 'يوسف كامل حسن', driverPhone: '01199988877', driverLicense: 'I90123456', driverLicenseExpiry: '2026-07-25', insuranceNumber: 'INS-2024-009', insuranceExpiry: '2025-10-08', registrationExpiry: '2025-11-30', createdAt: n, updatedAt: n),
      // === أوتوبيسات (Buses) x3 ===
      Vehicle(id: 10, plateNumber: 'ج ث ب 8901', make: 'مرسيدس', model: 'أوتوبيس', year: 2017, color: 'white', fuelType: 'diesel', currentOdometer: 320000, status: 'active', vin: 'WDB45678901234567', engineNumber: 'MB-OM457-010', vehicleCategory: 'heavy', department: 'الموارد البشرية', driverName: 'حسام مجدي أحمد', driverPhone: '01266655544', driverLicense: 'J01234567', driverLicenseExpiry: '2025-09-30', insuranceNumber: 'INS-2024-010', insuranceExpiry: '2025-07-22', registrationExpiry: '2025-08-15', createdAt: n, updatedAt: n),
      Vehicle(id: 11, plateNumber: 'ن ح ي 2468', make: 'كاسبر', model: 'أوتوبيس', year: 2020, color: 'white', fuelType: 'diesel', currentOdometer: 195000, status: 'active', vin: 'CSP56789012345678', engineNumber: 'CASCER-CUMMINS-011', vehicleCategory: 'heavy', department: 'الموارد البشرية', driverName: 'طارق إبراهيم حسن', driverPhone: '01555544433', driverLicense: 'K12345678', driverLicenseExpiry: '2025-04-12', insuranceNumber: 'INS-2024-011', insuranceExpiry: '2025-05-18', registrationExpiry: '2025-06-30', createdAt: n, updatedAt: n),
      Vehicle(id: 12, plateNumber: 'و ك م 1357', make: 'هيونداي', model: 'أوتوبيس', year: 2022, color: 'white', fuelType: 'diesel', currentOdometer: 78000, status: 'active', vin: 'HYN67890123456789', engineNumber: 'HYUNDAI-D6CB-012', vehicleCategory: 'heavy', department: 'الموارد البشرية', driverName: 'كريم أحمد سالم', driverPhone: '01033322211', driverLicense: 'L23456789', driverLicenseExpiry: '2026-06-08', insuranceNumber: 'INS-2024-012', insuranceExpiry: '2026-02-14', registrationExpiry: '2026-03-20', createdAt: n, updatedAt: n),
    ];
  }

  static List<MaintenanceRecord> _seedRecords() {
    final n = DateTime.now();
    return [
      // جامبو #1 - MAN
      MaintenanceRecord(id: 1, vehicleId: 1, maintenanceDate: n, description: 'تغيير زيت المحرك وفلتر الزيت', type: 'oil_change', odometerReading: 180000, cost: 1200, laborCost: 300, serviceProvider: 'ورشة النيل للشاحنات', invoiceNumber: 'INV-001', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 2, vehicleId: 1, maintenanceDate: n, description: 'تبديل الإطارات الخلفية', type: 'tires', odometerReading: 175000, cost: 4800, laborCost: 400, serviceProvider: 'مركز الخليج للإطارات', invoiceNumber: 'INV-002', priority: 'high', status: 'completed', createdAt: n, updatedAt: n),
      // جامبو #2 - إيفيكو
      MaintenanceRecord(id: 3, vehicleId: 2, maintenanceDate: n, description: 'صيانة دورية شاملة - فحص الفرامل والتعليق', type: 'inspection', odometerReading: 115000, cost: 800, laborCost: 500, serviceProvider: 'وكالة إيفيكو مصر', invoiceNumber: 'INV-003', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      // جامبو #3 - مرسيدس (في الصيانة)
      MaintenanceRecord(id: 4, vehicleId: 3, maintenanceDate: n, description: 'إصلاح عطل في ناقل الحركة', type: 'transmission', odometerReading: 205000, cost: 8500, laborCost: 2500, serviceProvider: 'الوكالة العربية للمرسيدس', invoiceNumber: 'INV-004', priority: 'urgent', status: 'in_progress', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 5, vehicleId: 3, maintenanceDate: n, description: 'تغيير بطاريات جديدة', type: 'battery', odometerReading: 200000, cost: 3500, serviceProvider: 'مركز الفراعين للبطاريات', invoiceNumber: 'INV-005', priority: 'high', status: 'pending', createdAt: n, updatedAt: n),
      // دبابة #1
      MaintenanceRecord(id: 6, vehicleId: 4, maintenanceDate: n, description: 'تغيير فلاتر الهواء والوقود والزيت', type: 'filter', odometerReading: 245000, cost: 600, laborCost: 200, serviceProvider: 'ورشة النيل للشاحنات', invoiceNumber: 'INV-006', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      // دبابة #2
      MaintenanceRecord(id: 7, vehicleId: 5, maintenanceDate: n, description: 'تغيير زيت وفلاتر أول صيانة كبرى', type: 'oil_change', odometerReading: 90000, cost: 900, laborCost: 250, serviceProvider: 'ورشة فيصل الميكانيكية', invoiceNumber: 'INV-007', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      // دبابة #3 (في الصيانة)
      MaintenanceRecord(id: 8, vehicleId: 6, maintenanceDate: n, description: 'إصلاح تسريب في خزان المياه', type: 'mechanical', odometerReading: 170000, cost: 2200, laborCost: 800, serviceProvider: 'ورشة النيل للشاحنات', invoiceNumber: 'INV-008', priority: 'urgent', status: 'in_progress', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 9, vehicleId: 6, maintenanceDate: n, description: 'تبديل الإطارات الأربعة', type: 'tires', odometerReading: 168000, cost: 3200, laborCost: 300, serviceProvider: 'مركز الخليج للإطارات', invoiceNumber: 'INV-009', priority: 'high', status: 'pending', createdAt: n, updatedAt: n),
      // كلارك #1
      MaintenanceRecord(id: 10, vehicleId: 7, maintenanceDate: n, description: 'صيانة دورية - تغيير زيت وفلتر', type: 'oil_change', odometerReading: 11500, cost: 350, laborCost: 150, serviceProvider: 'ورشة الأمل للرافعات', invoiceNumber: 'INV-010', priority: 'low', status: 'completed', createdAt: n, updatedAt: n),
      // كلارك #2
      MaintenanceRecord(id: 11, vehicleId: 8, maintenanceDate: n, description: 'إصلاح نظام الهيدروليك', type: 'mechanical', odometerReading: 8000, cost: 1800, laborCost: 600, serviceProvider: 'وكالة نيسان مصر', invoiceNumber: 'INV-011', priority: 'high', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 12, vehicleId: 8, maintenanceDate: n, description: 'تغيير سلسلة الرفع', type: 'mechanical', odometerReading: 8200, cost: 2500, laborCost: 700, serviceProvider: 'ورشة الأمل للرافعات', invoiceNumber: 'INV-012', priority: 'high', status: 'pending', createdAt: n, updatedAt: n),
      // كلارك #3
      MaintenanceRecord(id: 13, vehicleId: 9, maintenanceDate: n, description: 'فحص أولي - جديد', type: 'inspection', odometerReading: 3000, cost: 200, laborCost: 100, serviceProvider: 'ورشة الأمل للرافعات', invoiceNumber: 'INV-013', priority: 'low', status: 'completed', createdAt: n, updatedAt: n),
      // أوتوبيس #1 - مرسيدس
      MaintenanceRecord(id: 14, vehicleId: 10, maintenanceDate: n, description: 'تغيير زيت وفلاتر المحرك', type: 'oil_change', odometerReading: 310000, cost: 1500, laborCost: 400, serviceProvider: 'الوكالة العربية للمرسيدس', invoiceNumber: 'INV-014', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 15, vehicleId: 10, maintenanceDate: n, description: 'إصلاح التكييف', type: 'ac', odometerReading: 315000, cost: 2200, laborCost: 600, serviceProvider: 'ورشة الأمل الكهربائية', invoiceNumber: 'INV-015', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      // أوتوبيس #2 - كاسبر
      MaintenanceRecord(id: 16, vehicleId: 11, maintenanceDate: n, description: 'تغيير فرامل هوائية', type: 'brakes', odometerReading: 190000, cost: 1800, laborCost: 500, serviceProvider: 'ورشة فيصل الميكانيكية', invoiceNumber: 'INV-016', priority: 'high', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 17, vehicleId: 11, maintenanceDate: n, description: 'إصلاح كهربائي - إنارة داخلية', type: 'electrical', odometerReading: 192000, cost: 650, laborCost: 250, serviceProvider: 'ورشة الأمل الكهربائية', invoiceNumber: 'INV-017', priority: 'medium', status: 'pending', createdAt: n, updatedAt: n),
      // أوتوبيس #3 - هيونداي
      MaintenanceRecord(id: 18, vehicleId: 12, maintenanceDate: n, description: 'صيانة أولى - فحص شامل', type: 'inspection', odometerReading: 75000, cost: 400, laborCost: 200, serviceProvider: 'وكالة هيونداي مصر', invoiceNumber: 'INV-018', priority: 'low', status: 'completed', createdAt: n, updatedAt: n),
    ];
  }

  // ===== Helper: Decode JSON from Hive =====
  static Map<String, dynamic> _decode(dynamic value) {
    if (value == null) return {};
    if (value is String) return jsonDecode(value) as Map<String, dynamic>;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  // ===== Backup & Restore =====
  static Future<String> backupDatabase() async {
    final vehicles = await getAllVehicles();
    final records = await getAllMaintenanceRecords();
    final data = {
      'vehicles': vehicles.map((v) => v.toMap()).toList(),
      'maintenance_records': records.map((r) => r.toMap()).toList(),
      'backup_date': DateTime.now().toIso8601String(),
      'version': AppConstants.dbVersion,
    };
    return jsonEncode(data);
  }

  static Future<void> restoreDatabase(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final vehicleMaps = (data['vehicles'] as List?) ?? [];
    final recordMaps = (data['maintenance_records'] as List?) ?? [];

    try {
      await _vehicleBox!.clear();
      await _maintenanceBox!.clear();

      for (final m in vehicleMaps) {
        final map = Map<String, dynamic>.from(m as Map);
        final id = map['id'] as int? ?? 0;
        await _vehicleBox!.put(id, jsonEncode(map));
      }
      for (final m in recordMaps) {
        final map = Map<String, dynamic>.from(m as Map);
        final id = map['id'] as int? ?? 0;
        await _maintenanceBox!.put(id, jsonEncode(map));
      }
    } catch (e) {
      debugPrint('Restore error: $e');
    }
  }

  // ===== Vehicle CRUD =====
  static Future<List<Vehicle>> getAllVehicles() async {
    try {
      final box = _vehicleBox;
      if (box == null) return [];
      final vehicles = <Vehicle>[];
      final keys = box.keys.toList();
      for (final key in keys) {
        final map = _decode(box.get(key));
        if (map.isNotEmpty) {
          vehicles.add(Vehicle.fromMap(map));
        }
      }
      vehicles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return vehicles;
    } catch (e) {
      debugPrint('getAllVehicles error: $e');
      return [];
    }
  }

  static Future<Vehicle?> getVehicleById(int id) async {
    try {
      final box = _vehicleBox;
      if (box == null) return null;
      final value = box.get(id);
      if (value == null) return null;
      final map = _decode(value);
      if (map.isEmpty) return null;
      return Vehicle.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Vehicle>> searchVehicles(String query) async {
    final all = await getAllVehicles();
    final q = query.toLowerCase();
    return all.where((v) =>
        v.plateNumber.toLowerCase().contains(q) ||
        v.make.toLowerCase().contains(q) ||
        v.model.toLowerCase().contains(q) ||
        (v.driverName ?? '').toLowerCase().contains(q) ||
        (v.vin ?? '').toLowerCase().contains(q)).toList();
  }

  static Future<int> _getNextVehicleId() async {
    final box = _vehicleBox;
    if (box == null || box.isEmpty) return 1;
    int maxId = 0;
    for (final key in box.keys) {
      if (key is int && key > maxId) maxId = key;
    }
    return maxId + 1;
  }

  static Future<int> insertVehicle(Vehicle v) async {
    try {
      final box = _vehicleBox;
      if (box == null) return -1;
      final id = await _getNextVehicleId();
      final now = DateTime.now().toIso8601String();
      final map = v.copyWith(id: id).toMap();
      map['created_at'] = now;
      map['updated_at'] = now;
      await box.put(id, jsonEncode(map));
      return id;
    } catch (e) {
      debugPrint('insertVehicle error: $e');
      return -1;
    }
  }

  static Future<int> updateVehicle(Vehicle v) async {
    try {
      final box = _vehicleBox;
      if (box == null) return 0;
      final now = DateTime.now().toIso8601String();
      final map = v.copyWith(updatedAt: DateTime.now()).toMap();
      map['updated_at'] = now;
      await box.put(v.id, jsonEncode(map));
      return 1;
    } catch (e) {
      debugPrint('updateVehicle error: $e');
      return 0;
    }
  }

  static Future<int> deleteVehicle(int id) async {
    try {
      final vBox = _vehicleBox;
      final mBox = _maintenanceBox;
      if (vBox == null || mBox == null) return 0;
      await vBox.delete(id);
      final keysToDelete = <dynamic>[];
      for (final key in mBox.keys) {
        final map = _decode(mBox.get(key));
        if ((map['vehicle_id'] as int?) == id) {
          keysToDelete.add(key);
        }
      }
      if (keysToDelete.isNotEmpty) {
        await mBox.deleteAll(keysToDelete);
      }
      return 1;
    } catch (e) {
      debugPrint('deleteVehicle error: $e');
      return 0;
    }
  }

  // ===== Maintenance CRUD =====
  static Future<List<MaintenanceRecord>> getAllMaintenanceRecords() async {
    try {
      final box = _maintenanceBox;
      if (box == null) return [];
      final vehicles = await getAllVehicles();
      final records = <MaintenanceRecord>[];
      final keys = box.keys.toList();
      for (final key in keys) {
        final map = _decode(box.get(key));
        if (map.isEmpty) continue;
        final vid = (map['vehicle_id'] as int?) ?? 0;
        Vehicle? veh;
        for (final v in vehicles) {
          if (v.id == vid) { veh = v; break; }
        }
        records.add(MaintenanceRecord.fromMap(map).copyWith(vehicle: veh));
      }
      records.sort((a, b) => b.maintenanceDate.compareTo(a.maintenanceDate));
      return records;
    } catch (e) {
      debugPrint('getAllMaintenanceRecords error: $e');
      return [];
    }
  }

  static Future<List<MaintenanceRecord>> getMaintenanceByVehicleId(int vid) async {
    try {
      final box = _maintenanceBox;
      if (box == null) return [];
      final v = await getVehicleById(vid);
      final records = <MaintenanceRecord>[];
      for (final key in box.keys) {
        final map = _decode(box.get(key));
        if (map.isEmpty) continue;
        if ((map['vehicle_id'] as int?) == vid) {
          records.add(MaintenanceRecord.fromMap(map).copyWith(vehicle: v));
        }
      }
      records.sort((a, b) => b.maintenanceDate.compareTo(a.maintenanceDate));
      return records;
    } catch (e) {
      debugPrint('getMaintenanceByVehicleId error: $e');
      return [];
    }
  }

  static Future<int> _getNextRecordId() async {
    final box = _maintenanceBox;
    if (box == null || box.isEmpty) return 1;
    int maxId = 0;
    for (final key in box.keys) {
      if (key is int && key > maxId) maxId = key;
    }
    return maxId + 1;
  }

  static Future<int> insertMaintenanceRecord(MaintenanceRecord r) async {
    try {
      final box = _maintenanceBox;
      if (box == null) return -1;
      final id = await _getNextRecordId();
      final now = DateTime.now().toIso8601String();
      final map = r.copyWith(id: id).toMap();
      map['created_at'] = now;
      map['updated_at'] = now;
      await box.put(id, jsonEncode(map));
      return id;
    } catch (e) {
      debugPrint('insertMaintenanceRecord error: $e');
      return -1;
    }
  }

  static Future<int> updateMaintenanceRecord(MaintenanceRecord r) async {
    try {
      final box = _maintenanceBox;
      if (box == null) return 0;
      final now = DateTime.now().toIso8601String();
      final map = r.copyWith(updatedAt: DateTime.now()).toMap();
      map['updated_at'] = now;
      await box.put(r.id, jsonEncode(map));
      return 1;
    } catch (e) {
      debugPrint('updateMaintenanceRecord error: $e');
      return 0;
    }
  }

  static Future<int> deleteMaintenanceRecord(int id) async {
    try {
      final box = _maintenanceBox;
      if (box == null) return 0;
      await box.delete(id);
      return 1;
    } catch (e) {
      debugPrint('deleteMaintenanceRecord error: $e');
      return 0;
    }
  }

  // ===== Statistics (pure Dart) =====
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final vehicles = await getAllVehicles();
    final records = await getAllMaintenanceRecords();
    final completed = records.where((r) => r.status == 'completed').toList();
    double totalCost = 0;
    for (final r in completed) { totalCost += r.totalCost; }
    int pendingCount = 0;
    int inProgressCount = 0;
    int urgentCount = 0;
    for (final r in records) {
      if (r.status == 'pending') pendingCount++;
      if (r.status == 'in_progress') inProgressCount++;
      if (r.priority == 'urgent' && r.status != 'completed' && r.status != 'cancelled') urgentCount++;
    }
    int activeCount = 0;
    int maintCount = 0;
    for (final v in vehicles) {
      if (v.status == 'active') activeCount++;
      if (v.status == 'maintenance') maintCount++;
    }
    return {
      'vehicleCount': vehicles.length,
      'activeVehicles': activeCount,
      'maintenanceVehicles': maintCount,
      'totalCost': totalCost,
      'thisMonthCost': 0.0,
      'lastMonthCost': 0.0,
      'pendingRecords': pendingCount,
      'inProgressRecords': inProgressCount,
      'urgentRecords': urgentCount,
    };
  }

  static Future<List<Map<String, dynamic>>> getMaintenanceByType() async {
    final records = await getAllMaintenanceRecords();
    final Map<String, List<double>> typeCosts = {};
    for (final r in records) {
      if (r.status != 'completed') continue;
      typeCosts.putIfAbsent(r.type, () => []);
      typeCosts[r.type]!.add(r.totalCost);
    }
    final list = <Map<String, dynamic>>[];
    typeCosts.forEach((type, costs) {
      double total = 0;
      for (final c in costs) { total += c; }
      list.add({'type': type, 'count': costs.length, 'total_cost': total});
    });
    list.sort((a, b) => ((b['total_cost'] as double?) ?? 0).compareTo((a['total_cost'] as double?) ?? 0));
    return list;
  }

  static Future<List<Map<String, dynamic>>> getMonthlyCosts() async {
    final records = await getAllMaintenanceRecords();
    final Map<String, List<double>> monthCosts = {};
    for (final r in records) {
      if (r.status != 'completed') continue;
      final key = r.maintenanceDate.toIso8601String().substring(0, 7);
      monthCosts.putIfAbsent(key, () => []);
      monthCosts[key]!.add(r.totalCost);
    }
    final list = <Map<String, dynamic>>[];
    monthCosts.forEach((month, costs) {
      double total = 0;
      for (final c in costs) { total += c; }
      list.add({'month': month, 'total_cost': total, 'count': costs.length});
    });
    list.sort((a, b) => ((a['month'] as String?) ?? '').compareTo((b['month'] as String?) ?? ''));
    return list.reversed.toList();
  }

  static Future<List<Map<String, dynamic>>> getVehicleMaintenanceCosts() async {
    final vehicles = await getAllVehicles();
    final records = await getAllMaintenanceRecords();
    final completed = records.where((r) => r.status == 'completed').toList();
    final list = <Map<String, dynamic>>[];
    for (final v in vehicles) {
      double total = 0;
      int count = 0;
      for (final r in completed) {
        if (r.vehicleId == v.id) { total += r.totalCost; count++; }
      }
      list.add({
        'plate_number': v.plateNumber,
        'make': v.make,
        'model': v.model,
        'record_count': count,
        'total_cost': total,
      });
    }
    list.sort((a, b) => ((b['total_cost'] as double?) ?? 0).compareTo((a['total_cost'] as double?) ?? 0));
    if (list.length > 10) return list.sublist(0, 10);
    return list;
  }

  // ===== Hive Cleanup =====
  static Future<void> close() async {
    await _vehicleBox?.close();
    await _maintenanceBox?.close();
    await Hive.close();
    _initialized = false;
  }

  static Future<void> clearAllData() async {
    await _vehicleBox?.clear();
    await _maintenanceBox?.clear();
    final metaBox = await Hive.openBox(_metaBoxName);
    await metaBox.put(_seededKey, false);
    await _seedData();
    await metaBox.put(_seededKey, true);
  }
}
