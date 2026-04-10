import 'package:flutter/foundation.dart';
import '../models/maintenance_record.dart';
import '../services/database_service.dart';
import '../services/supabase_sync_service.dart';

class MaintenanceProvider extends ChangeNotifier {
  List<MaintenanceRecord> _records = [];
  List<MaintenanceRecord> _filteredRecords = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  int? _vehicleFilter;

  List<MaintenanceRecord> get records => _filteredRecords;
  List<MaintenanceRecord> get allRecords => _records;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get typeFilter => _typeFilter;
  int? get vehicleFilter => _vehicleFilter;

  MaintenanceProvider();

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();
    try {
      _records = await DatabaseService.getAllMaintenanceRecords();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading records: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecordsForVehicle(int vehicleId) async {
    _isLoading = true;
    _vehicleFilter = vehicleId;
    notifyListeners();
    try {
      _records = await DatabaseService.getMaintenanceByVehicleId(vehicleId);
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading vehicle records: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _typeFilter = 'all';
    _vehicleFilter = null;
    loadRecords();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    _applyFilters();
  }

  void setVehicleFilter(int? vehicleId) {
    _vehicleFilter = vehicleId;
    _applyFilters();
  }

  void _applyFilters() {
    var result = _records;

    if (_vehicleFilter != null) {
      result = result.where((r) => r.vehicleId == _vehicleFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((r) =>
              r.description.toLowerCase().contains(q) ||
              (r.serviceProvider?.toLowerCase().contains(q) ?? false) ||
              (r.invoiceNumber?.toLowerCase().contains(q) ?? false) ||
              (r.vehicle?.plateNumber.toLowerCase().contains(q) ?? false))
          .toList();
    }

    if (_statusFilter != 'all') {
      result = result.where((r) => r.status == _statusFilter).toList();
    }

    if (_typeFilter != 'all') {
      result = result.where((r) => r.type == _typeFilter).toList();
    }

    _filteredRecords = result;
    notifyListeners();
  }

  Future<int> addRecord(MaintenanceRecord record) async {
    final id = await DatabaseService.insertMaintenanceRecord(record);
    await loadRecords();
    SupabaseSyncService.syncNow();
    return id;
  }

  Future<bool> updateRecord(MaintenanceRecord record) async {
    final rows = await DatabaseService.updateMaintenanceRecord(record);
    await loadRecords();
    SupabaseSyncService.syncNow();
    return rows > 0;
  }

  Future<bool> deleteRecord(int id) async {
    final rows = await DatabaseService.deleteMaintenanceRecord(id);
    await loadRecords();
    SupabaseSyncService.syncNow();
    return rows > 0;
  }

  Future<List<MaintenanceRecord>> getRecordsByVehicle(int vehicleId) async {
    return DatabaseService.getMaintenanceByVehicleId(vehicleId);
  }
}
