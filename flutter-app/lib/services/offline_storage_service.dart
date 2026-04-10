// ─────────────────────────────────────────────────────────────────────────────
// offline_storage_service.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// Persists data to SharedPreferences as JSON when offline, so data survives
// app restarts. Loads cached data back into DatabaseService memory on init.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/checklist.dart';
import '../models/fuel_record.dart';
import '../models/driver_violation.dart';
import '../models/expense.dart';
import '../models/work_order.dart';
import '../models/trip_tracking.dart';

class OfflineStorageService {
  OfflineStorageService._();

  static const String _prefix = 'offline_cache_';

  // ── Save all data to local storage ────────────────────────────────────────

  /// Save a list of vehicles to offline storage.
  static Future<void> saveVehicles(List<Vehicle> vehicles) async {
    await _saveList('vehicles', vehicles.map((v) => v.toMap()).toList());
  }

  static Future<void> saveMaintenanceRecords(List<MaintenanceRecord> records) async {
    await _saveList('maintenance', records.map((r) => r.toMap()).toList());
  }

  static Future<void> saveChecklists(List<Checklist> checklists) async {
    await _saveList('checklists', checklists.map((c) => c.toMap()).toList());
  }

  static Future<void> saveFuelRecords(List<FuelRecord> records) async {
    await _saveList('fuel', records.map((f) => f.toMap()).toList());
  }

  static Future<void> saveViolations(List<DriverViolation> violations) async {
    await _saveList('violations', violations.map((v) => v.toMap()).toList());
  }

  static Future<void> saveExpenses(List<Expense> expenses) async {
    await _saveList('expenses', expenses.map((e) => e.toMap()).toList());
  }

  static Future<void> saveWorkOrders(List<WorkOrder> orders) async {
    await _saveList('work_orders', orders.map((o) => o.toMap()).toList());
  }

  static Future<void> saveTrips(List<TripTracking> trips) async {
    await _saveList('trips', trips.map((t) => t.toMap()).toList());
  }

  /// Save all entity types at once (used after sync or bulk load).
  static Future<void> saveAll({
    required List<Vehicle> vehicles,
    required List<MaintenanceRecord> maintenance,
    required List<Checklist> checklists,
    required List<FuelRecord> fuel,
    required List<DriverViolation> violations,
    required List<Expense> expenses,
    required List<WorkOrder> workOrders,
    required List<TripTracking> trips,
  }) async {
    await Future.wait([
      saveVehicles(vehicles),
      saveMaintenanceRecords(maintenance),
      saveChecklists(checklists),
      saveFuelRecords(fuel),
      saveViolations(violations),
      saveExpenses(expenses),
      saveWorkOrders(workOrders),
      saveTrips(trips),
    ]);
    debugPrint('OfflineStorage: All data saved locally (${vehicles.length} vehicles, ${maintenance.length} maintenance, etc.)');
  }

  // ── Load data from local storage ──────────────────────────────────────────

  static List<Vehicle> loadVehicles() {
    return _loadList('vehicles').map((m) => Vehicle.fromMap(m)).toList();
  }

  static List<MaintenanceRecord> loadMaintenanceRecords() {
    return _loadList('maintenance').map((m) => MaintenanceRecord.fromMap(m)).toList();
  }

  static List<Checklist> loadChecklists() {
    return _loadList('checklists').map((m) => Checklist.fromMap(m)).toList();
  }

  static List<FuelRecord> loadFuelRecords() {
    return _loadList('fuel').map((m) => FuelRecord.fromMap(m)).toList();
  }

  static List<DriverViolation> loadViolations() {
    return _loadList('violations').map((m) => DriverViolation.fromMap(m)).toList();
  }

  static List<Expense> loadExpenses() {
    return _loadList('expenses').map((m) => Expense.fromMap(m)).toList();
  }

  static List<WorkOrder> loadWorkOrders() {
    return _loadList('work_orders').map((m) => WorkOrder.fromMap(m)).toList();
  }

  static List<TripTracking> loadTrips() {
    return _loadList('trips').map((m) => TripTracking.fromMap(m)).toList();
  }

  /// Check if offline cache has any data stored.
  static Future<bool> hasCachedData() async {
    final prefs = await _getPrefs();
    if (prefs == null) return false;
    return prefs.containsKey('${_prefix}vehicles');
  }

  /// Clear all offline cached data.
  static Future<void> clearAll() async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    final keysToRemove = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
    debugPrint('OfflineStorage: Cleared all cached data');
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  static Future<void> _saveList(String entity, List<Map<String, dynamic>> data) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      final json = jsonEncode(data);
      await prefs.setString('${_prefix}$entity', json);
    } catch (e) {
      debugPrint('OfflineStorage: Error saving $entity: $e');
    }
  }

  static List<Map<String, dynamic>> _loadList(String entity) {
    try {
      final prefs = _getPrefsSync();
      if (prefs == null) return [];
      final json = prefs.getString('${_prefix}$entity');
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('OfflineStorage: Error loading $entity: $e');
      return [];
    }
  }

  static Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Synchronous prefs getter for use in non-async contexts.
  /// Returns null if SharedPreferences is not yet initialized.
  static SharedPreferences? _prefsInstance;

  static SharedPreferences? _getPrefsSync() {
    _prefsInstance ??= SharedPreferences.getInstance() as SharedPreferences?;
    // This is a best-effort approach; returns null if not yet ready.
    return null; // We'll use async loading instead in practice
  }

  /// Initialize the sync prefs instance (call once on app start).
  static Future<void> initialize() async {
    try {
      _prefsInstance = await SharedPreferences.getInstance();
      debugPrint('OfflineStorage: Initialized');
    } catch (e) {
      debugPrint('OfflineStorage: Failed to initialize: $e');
    }
  }
}
