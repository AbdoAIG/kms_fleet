import 'package:flutter/foundation.dart';
import '../models/driver.dart';
import '../models/driver_violation.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import '../services/supabase_sync_service.dart';

class DriverProvider extends ChangeNotifier {
  List<Driver> _drivers = [];
  List<Driver> _filteredDrivers = [];
  List<DriverViolation> _driverViolations = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Driver> get drivers => _filteredDrivers;
  List<Driver> get allDrivers => _drivers;
  List<DriverViolation> get driverViolations => _driverViolations;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // ── Computed Stats ──
  int get activeCount {
    int count = 0;
    for (final d in _drivers) {
      if (d.status == 'active') count++;
    }
    return count;
  }

  int get suspendedCount {
    int count = 0;
    for (final d in _drivers) {
      if (d.status == 'suspended') count++;
    }
    return count;
  }

  int get nearExpiryCount {
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));
    int count = 0;
    for (final d in _drivers) {
      if (d.licenseExpiryDate != null &&
          d.licenseExpiryDate!.isAfter(now) &&
          d.licenseExpiryDate!.isBefore(thirtyDaysLater)) {
        count++;
      }
    }
    return count;
  }

  int get expiredCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int count = 0;
    for (final d in _drivers) {
      if (d.licenseExpiryDate != null) {
        final expiry = DateTime(
          d.licenseExpiryDate!.year,
          d.licenseExpiryDate!.month,
          d.licenseExpiryDate!.day,
        );
        if (expiry.isBefore(today)) count++;
      }
    }
    return count;
  }

  DriverProvider();

  // ── Driver CRUD ──

  Future<void> loadDrivers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _drivers = await DatabaseService.getAllDrivers();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading drivers: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchDrivers(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _applyFilters();
      return;
    }
    try {
      final results = await DatabaseService.searchDrivers(query);
      _filteredDrivers = results;
    } catch (e) {
      debugPrint('Error searching drivers: $e');
    }
    notifyListeners();
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredDrivers = List.from(_drivers);
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredDrivers = _drivers
          .where((d) =>
              d.name.toLowerCase().contains(q) ||
              d.phone.contains(q) ||
              d.licenseNumber.toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }

  Future<int> addDriver(Driver driver) async {
    final id = await DatabaseService.insertDriver(driver);
    await loadDrivers();
    SupabaseSyncService.syncNow();
    return id;
  }

  Future<bool> updateDriver(Driver driver) async {
    final rows = await DatabaseService.updateDriver(driver);
    await loadDrivers();
    SupabaseSyncService.syncNow();
    return rows > 0;
  }

  Future<bool> deleteDriver(int id) async {
    final rows = await DatabaseService.deleteDriver(id);
    await loadDrivers();
    SupabaseSyncService.syncNow();
    return rows > 0;
  }

  // ── Violation CRUD ──

  Future<void> loadViolationsByDriver(int driverId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _driverViolations =
          await DatabaseService.getViolationsByDriverId(driverId);
    } catch (e) {
      debugPrint('Error loading violations: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addViolation(DriverViolation violation) async {
    final id = await DatabaseService.insertViolation(violation);
    if (violation.driverId > 0) {
      await loadViolationsByDriver(violation.driverId);
    }
    SupabaseSyncService.syncNow();
    return id;
  }

  Future<bool> deleteViolation(int id, int driverId) async {
    final rows = await DatabaseService.deleteViolation(id);
    await loadViolationsByDriver(driverId);
    SupabaseSyncService.syncNow();
    return rows > 0;
  }

  // ── Vehicle lookup helper ──

  Future<Vehicle?> getVehicleById(int vehicleId) async {
    return DatabaseService.getVehicleById(vehicleId);
  }
}
