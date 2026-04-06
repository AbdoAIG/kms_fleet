// ─────────────────────────────────────────────────────────────────────────────
// supabase_sync_service.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// Bidirectional sync between the local SQLite database and Supabase PostgreSQL.
//
// Data is stored in Supabase tables: vehicles, maintenance_records, checklists,
// fuel_records, work_orders, driver_violations, expenses, trip_trackings —
// each scoped to the authenticated user via user_id column.
//
// The sync strategy is "last-write-wins" based on updated_at timestamps.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/checklist.dart';
import '../models/fuel_record.dart';
import '../models/work_order.dart';
import '../models/driver_violation.dart';
import '../models/expense.dart';
import '../models/trip_tracking.dart';
import 'database_service.dart';
import 'supabase_service.dart';

class SupabaseSyncService {
  SupabaseSyncService._();

  static const String _lastSyncKey = 'last_supabase_sync';

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns the currently signed-in user's ID, or null.
  static String? get _uid => currentUserId;

  // ── Last-sync timestamp ──────────────────────────────────────────────────

  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return null;
      final millis = prefs.getInt(_lastSyncKey);
      if (millis == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (e) {
      debugPrint('SyncService: error reading last sync time: $e');
      return null;
    }
  }

  static Future<void> _setLastSyncTime() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('SyncService: error writing last sync time: $e');
    }
  }

  static Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  // ── Vehicles ─────────────────────────────────────────────────────────────

  static Future<void> syncVehicles() async {
    try {
      if (_uid == null) {
        debugPrint('SyncService: cannot sync vehicles – user not signed in');
        return;
      }

      // 1. Local → Supabase
      final localVehicles = await DatabaseService.getAllVehicles();
      for (final v in localVehicles) {
        final map = _vehicleToMap(v);
        if (v.id != null) {
          // Upsert: use id as the key
          await supabase.from('vehicles').upsert(
            map,
            onConflict: 'id',
          );
        }
      }

      // 2. Supabase → Local
      final response = await supabase
          .from('vehicles')
          .select()
          .eq('user_id', _uid!)
          .order('updated_at', ascending: false);

      for (final row in response) {
        final vehicle = _vehicleFromRow(row);
        final existing = await DatabaseService.getVehicleById(vehicle.id!);
        if (existing != null) {
          if (vehicle.updatedAt.isAfter(existing.updatedAt)) {
            await DatabaseService.updateVehicle(vehicle);
          }
        } else {
          await DatabaseService.insertVehicle(vehicle);
        }
      }

      debugPrint('SyncService: vehicles synced (${localVehicles.length} local)');
    } catch (e) {
      debugPrint('SyncService: error syncing vehicles: $e');
    }
  }

  /// Delete a vehicle from Supabase by ID.
  static Future<void> deleteVehicleFromSupabase(int id) async {
    try {
      if (_uid == null) return;
      await supabase.from('vehicles').delete().eq('id', id).eq('user_id', _uid!);
      debugPrint('SyncService: deleted vehicle $id from Supabase');
    } catch (e) {
      debugPrint('SyncService: error deleting vehicle from Supabase: $e');
    }
  }

  // ── Maintenance Records ──────────────────────────────────────────────────

  static Future<void> syncMaintenance() async {
    try {
      if (_uid == null) {
        debugPrint('SyncService: cannot sync maintenance – user not signed in');
        return;
      }

      final localRecords = await DatabaseService.getAllMaintenanceRecords();
      for (final r in localRecords) {
        final map = _maintenanceToMap(r);
        await supabase.from('maintenance_records').upsert(
          map,
          onConflict: 'id',
        );
      }

      final response = await supabase
          .from('maintenance_records')
          .select()
          .eq('user_id', _uid!)
          .order('updated_at', ascending: false);

      for (final row in response) {
        final record = _maintenanceFromRow(row);
        try {
          await DatabaseService.insertMaintenanceRecord(record);
        } catch (_) {
          await DatabaseService.updateMaintenanceRecord(record);
        }
      }

      debugPrint('SyncService: maintenance synced (${localRecords.length} local)');
    } catch (e) {
      debugPrint('SyncService: error syncing maintenance: $e');
    }
  }

  /// Delete a maintenance record from Supabase by ID.
  static Future<void> deleteMaintenanceFromSupabase(int id) async {
    try {
      if (_uid == null) return;
      await supabase.from('maintenance_records').delete().eq('id', id).eq('user_id', _uid!);
      debugPrint('SyncService: deleted maintenance record $id from Supabase');
    } catch (e) {
      debugPrint('SyncService: error deleting maintenance from Supabase: $e');
    }
  }

  // ── Checklists ───────────────────────────────────────────────────────────

  static Future<void> syncChecklists() async {
    try {
      if (_uid == null) {
        debugPrint('SyncService: cannot sync checklists – user not signed in');
        return;
      }

      final localChecklists = await DatabaseService.getAllChecklists();
      for (final c in localChecklists) {
        final map = _checklistToMap(c);
        await supabase.from('checklists').upsert(
          map,
          onConflict: 'id',
        );
      }

      final response = await supabase
          .from('checklists')
          .select()
          .eq('user_id', _uid!)
          .order('updated_at', ascending: false);

      for (final row in response) {
        final checklist = _checklistFromRow(row);
        try {
          await DatabaseService.insertChecklist(checklist);
        } catch (_) {
          await DatabaseService.updateChecklist(checklist);
        }
      }

      debugPrint('SyncService: checklists synced (${localChecklists.length} local)');
    } catch (e) {
      debugPrint('SyncService: error syncing checklists: $e');
    }
  }

  /// Delete a checklist from Supabase by ID.
  static Future<void> deleteChecklistFromSupabase(int id) async {
    try {
      if (_uid == null) return;
      await supabase.from('checklists').delete().eq('id', id).eq('user_id', _uid!);
      debugPrint('SyncService: deleted checklist $id from Supabase');
    } catch (e) {
      debugPrint('SyncService: error deleting checklist from Supabase: $e');
    }
  }

  // ── Fuel Records ─────────────────────────────────────────────────────────

  static Future<void> syncFuel() async {
    try {
      if (_uid == null) {
        debugPrint('SyncService: cannot sync fuel – user not signed in');
        return;
      }

      final localFuel = await DatabaseService.getAllFuelRecords();
      for (final f in localFuel) {
        final map = _fuelToMap(f);
        await supabase.from('fuel_records').upsert(
          map,
          onConflict: 'id',
        );
      }

      final response = await supabase
          .from('fuel_records')
          .select()
          .eq('user_id', _uid!)
          .order('updated_at', ascending: false);

      for (final row in response) {
        final fuelRecord = _fuelFromRow(row);
        try {
          await DatabaseService.insertFuelRecord(fuelRecord);
        } catch (_) {
          await DatabaseService.updateFuelRecord(fuelRecord);
        }
      }

      debugPrint('SyncService: fuel synced (${localFuel.length} local)');
    } catch (e) {
      debugPrint('SyncService: error syncing fuel: $e');
    }
  }

  /// Delete a fuel record from Supabase by ID.
  static Future<void> deleteFuelFromSupabase(int id) async {
    try {
      if (_uid == null) return;
      await supabase.from('fuel_records').delete().eq('id', id).eq('user_id', _uid!);
      debugPrint('SyncService: deleted fuel record $id from Supabase');
    } catch (e) {
      debugPrint('SyncService: error deleting fuel from Supabase: $e');
    }
  }

  // ── Work Orders ────────────────────────────────────────────────────────

  static Future<void> syncWorkOrders() async {
    try {
      if (_uid == null) {
        debugPrint('SyncService: cannot sync work orders – user not signed in');
        return;
      }

      final localWorkOrders = await DatabaseService.getAllWorkOrders();
      for (final w in localWorkOrders) {
        final map = _workOrderToMap(w);
        await supabase.from('work_orders').upsert(
          map,
          onConflict: 'id',
        );
      }

      final response = await supabase
          .from('work_orders')
          .select()
          .eq('user_id', _uid!)
          .order('updated_at', ascending: false);

      for (final row in response) {
        final workOrder = _workOrderFromRow(row);
        try {
          await DatabaseService.insertWorkOrder(workOrder);
        } catch (_) {
          await DatabaseService.updateWorkOrder(workOrder);
        }
      }

      debugPrint('SyncService: work orders synced (${localWorkOrders.length} local)');
    } catch (e) {
      debugPrint('SyncService: error syncing work orders: $e');
    }
  }

  /// Delete a work order from Supabase by ID.
  static Future<void> deleteWorkOrderFromSupabase(int id) async {
    try {
      if (_uid == null) return;
      await supabase.from('work_orders').delete().eq('id', id).eq('user_id', _uid!);
      debugPrint('SyncService: deleted work order $id from Supabase');
    } catch (e) {
      debugPrint('SyncService: error deleting work order from Supabase: $e');
    }
  }

  // ── Driver Violations ────────────────────────────────────────────────────

  static Future<void> syncViolations() async {
    try {
      if (_uid == null) {
        debugPrint('SyncService: cannot sync violations – user not signed in');
        return;
      }

      final localViolations = await DatabaseService.getAllViolations();
      for (final v in localViolations) {
        final map = _violationToMap(v);
        await supabase.from('driver_violations').upsert(
          map,
          onConflict: 'id',
        );
      }

      final response = await supabase
          .from('driver_violations')
          .select()
          .eq('user_id', _uid!)
          .order('updated_at', ascending: false);

      for (final row in response) {
        final violation = _violationFromRow(row);
        try {
          await DatabaseService.insertViolation(violation);
        } catch (_) {
          await DatabaseService.updateViolation(violation);
        }
      }

      debugPrint('SyncService: violations synced (${localViolations.length} local)');
    } catch (e) {
      debugPrint('SyncService: error syncing violations: $e');
    }
  }

  /// Delete a driver violation from Supabase by ID.
  static Future<void> deleteViolationFromSupabase(int id) async {
    try {
      if (_uid == null) return;
      await supabase.from('driver_violations').delete().eq('id', id).eq('user_id', _uid!);
      debugPrint('SyncService: deleted violation $id from Supabase');
    } catch (e) {
      debugPrint('SyncService: error deleting violation from Supabase: $e');
    }
  }

  // ── Expenses ─────────────────────────────────────────────────────────────

  static Future<void> syncExpenses() async {
    try {
      if (_uid == null) {
        debugPrint('SyncService: cannot sync expenses – user not signed in');
        return;
      }

      final localExpenses = await DatabaseService.getAllExpenses();
      for (final e in localExpenses) {
        final map = _expenseToMap(e);
        await supabase.from('expenses').upsert(
          map,
          onConflict: 'id',
        );
      }

      final response = await supabase
          .from('expenses')
          .select()
          .eq('user_id', _uid!)
          .order('updated_at', ascending: false);

      for (final row in response) {
        final expense = _expenseFromRow(row);
        try {
          await DatabaseService.insertExpense(expense);
        } catch (_) {
          await DatabaseService.updateExpense(expense);
        }
      }

      debugPrint('SyncService: expenses synced (${localExpenses.length} local)');
    } catch (e) {
      debugPrint('SyncService: error syncing expenses: $e');
    }
  }

  /// Delete an expense from Supabase by ID.
  static Future<void> deleteExpenseFromSupabase(int id) async {
    try {
      if (_uid == null) return;
      await supabase.from('expenses').delete().eq('id', id).eq('user_id', _uid!);
      debugPrint('SyncService: deleted expense $id from Supabase');
    } catch (e) {
      debugPrint('SyncService: error deleting expense from Supabase: $e');
    }
  }

  // ── Trip Trackings ───────────────────────────────────────────────────────

  static Future<void> syncTrips() async {
    try {
      if (_uid == null) {
        debugPrint('SyncService: cannot sync trips – user not signed in');
        return;
      }

      final localTrips = await DatabaseService.getAllTrips();
      for (final t in localTrips) {
        final map = _tripToMap(t);
        await supabase.from('trip_trackings').upsert(
          map,
          onConflict: 'id',
        );
      }

      final response = await supabase
          .from('trip_trackings')
          .select()
          .eq('user_id', _uid!)
          .order('updated_at', ascending: false);

      for (final row in response) {
        final trip = _tripFromRow(row);
        try {
          await DatabaseService.insertTrip(trip);
        } catch (_) {
          await DatabaseService.updateTrip(trip);
        }
      }

      debugPrint('SyncService: trips synced (${localTrips.length} local)');
    } catch (e) {
      debugPrint('SyncService: error syncing trips: $e');
    }
  }

  /// Delete a trip from Supabase by ID.
  static Future<void> deleteTripFromSupabase(int id) async {
    try {
      if (_uid == null) return;
      await supabase.from('trip_trackings').delete().eq('id', id).eq('user_id', _uid!);
      debugPrint('SyncService: deleted trip $id from Supabase');
    } catch (e) {
      debugPrint('SyncService: error deleting trip from Supabase: $e');
    }
  }

  // ── Sync All ─────────────────────────────────────────────────────────────

  static Future<void> syncAll() async {
    try {
      await syncVehicles();
      await syncMaintenance();
      await syncChecklists();
      await syncFuel();
      await syncWorkOrders();
      await syncViolations();
      await syncExpenses();
      await syncTrips();
      await _setLastSyncTime();
      debugPrint('SyncService: full sync completed');
    } catch (e) {
      debugPrint('SyncService: error during full sync: $e');
    }
  }

  static Future<void> syncNow() => syncAll();

  // ═════════════════════════════════════════════════════════════════════════
  //  Map converters
  // ═════════════════════════════════════════════════════════════════════════

  // ── Vehicle ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _vehicleToMap(Vehicle v) {
    final map = v.toMap();
    map['user_id'] = _uid;
    if (map['id'] == null) map.remove('id');
    return map;
  }

  static Vehicle _vehicleFromRow(Map<String, dynamic> row) {
    return Vehicle.fromMap(row);
  }

  // ── Maintenance ──────────────────────────────────────────────────────────

  static Map<String, dynamic> _maintenanceToMap(MaintenanceRecord r) {
    final map = r.toMap();
    map['user_id'] = _uid;
    if (map['id'] == null) map.remove('id');
    return map;
  }

  static MaintenanceRecord _maintenanceFromRow(Map<String, dynamic> row) {
    return MaintenanceRecord.fromMap(row);
  }

  // ── Checklist ────────────────────────────────────────────────────────────

  static Map<String, dynamic> _checklistToMap(Checklist c) {
    final map = c.toMap();
    map['user_id'] = _uid;

    // Convert JSON-encoded items string to a native List for Supabase JSON column
    final rawItems = map['items'];
    if (rawItems is String && rawItems.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawItems) as List<dynamic>;
        map['items'] = decoded.map((e) => e as Map<String, dynamic>).toList();
      } catch (_) {}
    }
    if (map['id'] == null) map.remove('id');
    return map;
  }

  static Checklist _checklistFromRow(Map<String, dynamic> row) {
    // Supabase may return items as a List or as a parsed JSON
    final rawItems = row['items'];
    if (rawItems is List) {
      try {
        final list = rawItems
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
            .toList();
        row['items'] = jsonEncode(list);
      } catch (_) {
        row['items'] = '[]';
      }
    } else if (rawItems == null) {
      row['items'] = '[]';
    }
    return Checklist.fromMap(row);
  }

  // ── Fuel ─────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _fuelToMap(FuelRecord f) {
    final map = f.toMap();
    map['user_id'] = _uid;

    // Convert int booleans to real booleans for Supabase
    if (map['full_tank'] is int) {
      map['full_tank'] = (map['full_tank'] as int) != 0;
    }
    if (map['is_abnormal'] is int) {
      map['is_abnormal'] = (map['is_abnormal'] as int) != 0;
    }
    if (map['id'] == null) map.remove('id');
    return map;
  }

  static FuelRecord _fuelFromRow(Map<String, dynamic> row) {
    // Convert boolean back to int for local DB schema
    if (row['full_tank'] is bool) {
      row['full_tank'] = (row['full_tank'] as bool) ? 1 : 0;
    }
    if (row['is_abnormal'] is bool) {
      row['is_abnormal'] = (row['is_abnormal'] as bool) ? 1 : 0;
    }
    return FuelRecord.fromMap(row);
  }

  // ── Work Order ───────────────────────────────────────────────────────────

  static Map<String, dynamic> _workOrderToMap(WorkOrder w) {
    final map = w.toMap();
    map['user_id'] = _uid;
    if (map['id'] == null) map.remove('id');
    return map;
  }

  static WorkOrder _workOrderFromRow(Map<String, dynamic> row) {
    return WorkOrder.fromMap(row);
  }

  // ── Driver Violation ─────────────────────────────────────────────────────

  static Map<String, dynamic> _violationToMap(DriverViolation v) {
    final map = v.toMap();
    map['user_id'] = _uid;
    if (map['id'] == null) map.remove('id');
    return map;
  }

  static DriverViolation _violationFromRow(Map<String, dynamic> row) {
    return DriverViolation.fromMap(row);
  }

  // ── Expense ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _expenseToMap(Expense e) {
    final map = e.toMap();
    map['user_id'] = _uid;
    if (map['id'] == null) map.remove('id');
    return map;
  }

  static Expense _expenseFromRow(Map<String, dynamic> row) {
    return Expense.fromMap(row);
  }

  // ── Trip Tracking ────────────────────────────────────────────────────────

  static Map<String, dynamic> _tripToMap(TripTracking t) {
    final map = t.toMap();
    map['user_id'] = _uid;

    // Convert JSON-encoded trip points string to a native List for Supabase JSON column
    final rawPoints = map['trip_points_json'];
    if (rawPoints is String && rawPoints.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPoints) as List<dynamic>;
        map['trip_points_json'] = decoded.map((e) => e as Map<String, dynamic>).toList();
      } catch (_) {}
    }
    if (map['id'] == null) map.remove('id');
    return map;
  }

  static TripTracking _tripFromRow(Map<String, dynamic> row) {
    // Supabase may return trip_points_json as a List or as a parsed JSON
    final rawPoints = row['trip_points_json'];
    if (rawPoints is List) {
      try {
        final list = rawPoints
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
            .toList();
        row['trip_points_json'] = jsonEncode(list);
      } catch (_) {
        row['trip_points_json'] = '[]';
      }
    } else if (rawPoints == null) {
      row['trip_points_json'] = '[]';
    }
    return TripTracking.fromMap(row);
  }
}
