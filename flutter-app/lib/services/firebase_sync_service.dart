import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/checklist.dart';
import '../models/fuel_record.dart';
import 'database_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirebaseSyncService
// ─────────────────────────────────────────────────────────────────────────────
//
// Bidirectional sync between the local SQLite database and Firebase Realtime
// Database.  Data is stored under  users/{uid}/vehicles,  users/{uid}/maintenance,
// users/{uid}/checklists,  and  users/{uid}/fuel.
//
// The sync is "last-write-wins" – local data is pushed first, then remote data
// is pulled and upserted into the local DB.  A timestamp of the last successful
// sync is persisted in SharedPreferences.

class FirebaseSyncService {
  FirebaseSyncService._();

  static const String _lastSyncKey = 'last_firebase_sync';

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns the currently signed-in user's UID, or null if unavailable.
  static String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Returns a DatabaseReference rooted at  users/{uid}/{path}  or null
  /// when the user is not authenticated.
  static DatabaseReference? _ref(String path) {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseDatabase.instance.ref('users/$uid/$path');
  }

  // ── Last-sync timestamp ──────────────────────────────────────────────────

  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_lastSyncKey);
      if (millis == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (e) {
      debugPrint('FirebaseSyncService: error reading last sync time: $e');
      return null;
    }
  }

  static Future<void> _setLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('FirebaseSyncService: error writing last sync time: $e');
    }
  }

  // ── Vehicles ─────────────────────────────────────────────────────────────

  /// Push local vehicles to Firebase, then pull Firebase data into the local DB.
  static Future<void> syncVehicles() async {
    try {
      final ref = _ref('vehicles');
      if (ref == null) {
        debugPrint('FirebaseSyncService: cannot sync vehicles – user not signed in');
        return;
      }

      // 1. Local → Firebase
      final localVehicles = await DatabaseService.getAllVehicles();
      final Map<String, Map<String, dynamic>> firebaseBatch = {};
      for (final v in localVehicles) {
        final key = v.id != null ? '${v.id}' : ref.push().key!;
        firebaseBatch[key] = _vehicleToFirebaseMap(v);
      }
      await ref.update(firebaseBatch);

      // 2. Firebase → Local
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          final raw = entry.value;
          if (raw is Map<dynamic, dynamic>) {
            final map = _dynamicToMap(raw);
            final vehicle = _vehicleFromFirebaseMap(map);
            final existing = await DatabaseService.getVehicleById(vehicle.id!);
            if (existing != null) {
              // Upsert: keep whichever was updated more recently
              if (vehicle.updatedAt.isAfter(existing.updatedAt)) {
                await DatabaseService.updateVehicle(vehicle);
              }
            } else {
              await DatabaseService.insertVehicle(vehicle);
            }
          }
        }
      }

      debugPrint('FirebaseSyncService: vehicles synced (${localVehicles.length} local)');
    } catch (e) {
      debugPrint('FirebaseSyncService: error syncing vehicles: $e');
    }
  }

  // ── Maintenance Records ──────────────────────────────────────────────────

  static Future<void> syncMaintenance() async {
    try {
      final ref = _ref('maintenance');
      if (ref == null) {
        debugPrint('FirebaseSyncService: cannot sync maintenance – user not signed in');
        return;
      }

      // 1. Local → Firebase
      final localRecords = await DatabaseService.getAllMaintenanceRecords();
      final Map<String, Map<String, dynamic>> firebaseBatch = {};
      for (final r in localRecords) {
        final key = r.id != null ? '${r.id}' : ref.push().key!;
        firebaseBatch[key] = _maintenanceToFirebaseMap(r);
      }
      await ref.update(firebaseBatch);

      // 2. Firebase → Local
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          final raw = entry.value;
          if (raw is Map<dynamic, dynamic>) {
            final map = _dynamicToMap(raw);
            final record = _maintenanceFromFirebaseMap(map);
            try {
              await DatabaseService.insertMaintenanceRecord(record);
            } catch (_) {
              // If insert fails (duplicate), try update
              await DatabaseService.updateMaintenanceRecord(record);
            }
          }
        }
      }

      debugPrint('FirebaseSyncService: maintenance synced (${localRecords.length} local)');
    } catch (e) {
      debugPrint('FirebaseSyncService: error syncing maintenance: $e');
    }
  }

  // ── Checklists ───────────────────────────────────────────────────────────

  static Future<void> syncChecklists() async {
    try {
      final ref = _ref('checklists');
      if (ref == null) {
        debugPrint('FirebaseSyncService: cannot sync checklists – user not signed in');
        return;
      }

      // 1. Local → Firebase
      final localChecklists = await DatabaseService.getAllChecklists();
      final Map<String, Map<String, dynamic>> firebaseBatch = {};
      for (final c in localChecklists) {
        final key = c.id != null ? '${c.id}' : ref.push().key!;
        firebaseBatch[key] = _checklistToFirebaseMap(c);
      }
      await ref.update(firebaseBatch);

      // 2. Firebase → Local
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          final raw = entry.value;
          if (raw is Map<dynamic, dynamic>) {
            final map = _dynamicToMap(raw);
            final checklist = _checklistFromFirebaseMap(map);
            try {
              await DatabaseService.insertChecklist(checklist);
            } catch (_) {
              await DatabaseService.updateChecklist(checklist);
            }
          }
        }
      }

      debugPrint('FirebaseSyncService: checklists synced (${localChecklists.length} local)');
    } catch (e) {
      debugPrint('FirebaseSyncService: error syncing checklists: $e');
    }
  }

  // ── Fuel Records ─────────────────────────────────────────────────────────

  static Future<void> syncFuel() async {
    try {
      final ref = _ref('fuel');
      if (ref == null) {
        debugPrint('FirebaseSyncService: cannot sync fuel – user not signed in');
        return;
      }

      // 1. Local → Firebase
      final localFuel = await DatabaseService.getAllFuelRecords();
      final Map<String, Map<String, dynamic>> firebaseBatch = {};
      for (final f in localFuel) {
        final key = f.id != null ? '${f.id}' : ref.push().key!;
        firebaseBatch[key] = _fuelToFirebaseMap(f);
      }
      await ref.update(firebaseBatch);

      // 2. Firebase → Local
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          final raw = entry.value;
          if (raw is Map<dynamic, dynamic>) {
            final map = _dynamicToMap(raw);
            final fuelRecord = _fuelFromFirebaseMap(map);
            try {
              await DatabaseService.insertFuelRecord(fuelRecord);
            } catch (_) {
              await DatabaseService.updateFuelRecord(fuelRecord);
            }
          }
        }
      }

      debugPrint('FirebaseSyncService: fuel synced (${localFuel.length} local)');
    } catch (e) {
      debugPrint('FirebaseSyncService: error syncing fuel: $e');
    }
  }

  // ── Sync All ─────────────────────────────────────────────────────────────

  /// Runs every individual sync method sequentially, then records the timestamp.
  static Future<void> syncAll() async {
    try {
      await syncVehicles();
      await syncMaintenance();
      await syncChecklists();
      await syncFuel();
      await _setLastSyncTime();
      debugPrint('FirebaseSyncService: full sync completed');
    } catch (e) {
      debugPrint('FirebaseSyncService: error during full sync: $e');
    }
  }

  /// Convenience static method that triggers a full sync.
  static Future<void> syncNow() => syncAll();

  // ═════════════════════════════════════════════════════════════════════════
  //  Map converters – bridge between SQLite-friendly and Firebase-friendly
  //  representations.
  // ═════════════════════════════════════════════════════════════════════════

  // ── Vehicle converters ───────────────────────────────────────────────────

  /// Convert a Vehicle to a map suitable for Firebase.
  ///
  /// Mostly delegates to [Vehicle.toMap] but forces the id to int so that it
  /// round-trips cleanly (Firebase keys are strings).
  static Map<String, dynamic> _vehicleToFirebaseMap(Vehicle v) {
    final map = v.toMap();
    // Ensure id is serialised as an int (not null when stored under key)
    if (v.id != null) map['id'] = v.id;
    return map;
  }

  /// Convert a raw Firebase map into a Vehicle.
  ///
  /// Handles the case where Firebase may have stored the id as a String key.
  static Vehicle _vehicleFromFirebaseMap(Map<String, dynamic> map) {
    return Vehicle.fromMap(map);
  }

  // ── Maintenance converters ───────────────────────────────────────────────

  static Map<String, dynamic> _maintenanceToFirebaseMap(MaintenanceRecord r) {
    final map = r.toMap();
    if (r.id != null) map['id'] = r.id;
    return map;
  }

  static MaintenanceRecord _maintenanceFromFirebaseMap(Map<String, dynamic> map) {
    return MaintenanceRecord.fromMap(map);
  }

  // ── Checklist converters ─────────────────────────────────────────────────
  //
  // The local SQLite schema stores checklist items as a JSON-encoded string.
  // Firebase prefers native Lists, so we encode/decode between the two.

  static Map<String, dynamic> _checklistToFirebaseMap(Checklist c) {
    final map = c.toMap();
    if (c.id != null) map['id'] = c.id;

    // Convert the JSON-encoded items string into a native List for Firebase.
    final rawItems = map['items'];
    if (rawItems is String && rawItems.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawItems) as List<dynamic>;
        map['items'] = decoded
            .map((e) => e as Map<String, dynamic>)
            .toList();
      } catch (_) {
        // If parsing fails, keep the string – better than losing data.
      }
    }
    return map;
  }

  static Checklist _checklistFromFirebaseMap(Map<String, dynamic> map) {
    // Firebase may store items as a List<dynamic> of Maps.  Convert back to
    // the JSON string format expected by [Checklist.fromMap].
    final rawItems = map['items'];
    if (rawItems is List) {
      try {
        final list = rawItems
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
            .toList();
        map['items'] = jsonEncode(list);
      } catch (_) {
        map['items'] = '[]';
      }
    } else if (rawItems == null) {
      map['items'] = '[]';
    }
    return Checklist.fromMap(map);
  }

  // ── Fuel converters ──────────────────────────────────────────────────────
  //
  // The local SQLite schema stores booleans as integers (0/1).  Firebase can
  // store native booleans, so we normalise during conversion.

  static Map<String, dynamic> _fuelToFirebaseMap(FuelRecord f) {
    final map = f.toMap();
    if (f.id != null) map['id'] = f.id;

    // Convert int booleans to real booleans for Firebase.
    if (map['full_tank'] is int) {
      map['full_tank'] = (map['full_tank'] as int) != 0;
    }
    if (map['is_abnormal'] is int) {
      map['is_abnormal'] = (map['is_abnormal'] as int) != 0;
    }

    return map;
  }

  static FuelRecord _fuelFromFirebaseMap(Map<String, dynamic> map) {
    // Convert boolean back to int for the local DB schema.
    if (map['full_tank'] is bool) {
      map['full_tank'] = (map['full_tank'] as bool) ? 1 : 0;
    }
    if (map['is_abnormal'] is bool) {
      map['is_abnormal'] = (map['is_abnormal'] as bool) ? 1 : 0;
    }

    return FuelRecord.fromMap(map);
  }

  // ── Utility ──────────────────────────────────────────────────────────────

  /// Recursively converts a `Map<dynamic, dynamic>` (as returned by Firebase)
  /// into a `Map<String, dynamic>` that the model factories expect.
  static Map<String, dynamic> _dynamicToMap(Map<dynamic, dynamic> source) {
    final result = <String, dynamic>{};
    source.forEach((key, value) {
      if (value is Map<dynamic, dynamic>) {
        result[key.toString()] = _dynamicToMap(value);
      } else if (value is List) {
        result[key.toString()] = value.map((e) {
          if (e is Map<dynamic, dynamic>) return _dynamicToMap(e);
          return e;
        }).toList();
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }
}
