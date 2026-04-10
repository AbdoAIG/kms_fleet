import 'package:flutter/foundation.dart';
import '../models/fuel_record.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

class FuelProvider extends ChangeNotifier {
  List<FuelRecord> _fuelRecords = [];
  List<FuelRecord> _filteredFuelRecords = [];
  Map<int, Map<String, dynamic>> _stats = {};
  bool _isLoading = false;
  int? _vehicleFilter;

  List<FuelRecord> get fuelRecords => _filteredFuelRecords;
  List<FuelRecord> get allFuelRecords => _fuelRecords;
  Map<int, Map<String, dynamic>> get stats => _stats;
  bool get isLoading => _isLoading;
  int? get vehicleFilter => _vehicleFilter;

  FuelProvider();

  Future<void> loadFuelRecords() async {
    _isLoading = true;
    notifyListeners();
    try {
      _fuelRecords = await DatabaseService.getAllFuelRecords();
      _stats = await DatabaseService.getFuelConsumptionStats();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading fuel records: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadFuelRecordsForVehicle(int vehicleId) async {
    _isLoading = true;
    _vehicleFilter = vehicleId;
    notifyListeners();
    try {
      _fuelRecords = await DatabaseService.getFuelRecordsByVehicleId(vehicleId);
      _stats = await DatabaseService.getFuelConsumptionStats();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading vehicle fuel records: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void resetFilters() {
    _vehicleFilter = null;
    loadFuelRecords();
  }

  void setVehicleFilter(int? vehicleId) {
    _vehicleFilter = vehicleId;
    _applyFilters();
  }

  void _applyFilters() {
    var result = _fuelRecords;

    if (_vehicleFilter != null) {
      result = result.where((f) => f.vehicleId == _vehicleFilter).toList();
    }

    _filteredFuelRecords = result;
    notifyListeners();
  }

  Future<int> addFuelRecord(FuelRecord record) async {
    final id = await DatabaseService.insertFuelRecord(record);
    await loadFuelRecords();
    ConnectivityService.onWriteOperation('fuel');
    return id;
  }

  Future<bool> updateFuelRecord(FuelRecord record) async {
    final rows = await DatabaseService.updateFuelRecord(record);
    await loadFuelRecords();
    ConnectivityService.onWriteOperation('fuel');
    return rows > 0;
  }

  Future<bool> deleteFuelRecord(int id) async {
    final rows = await DatabaseService.deleteFuelRecord(id);
    await loadFuelRecords();
    ConnectivityService.onWriteOperation('fuel');
    return rows > 0;
  }

  Future<Map<int, Map<String, dynamic>>> getStats() async {
    _stats = await DatabaseService.getFuelConsumptionStats();
    notifyListeners();
    return _stats;
  }

  Future<List<FuelRecord>> getFuelRecordsByVehicle(int vehicleId) async {
    return DatabaseService.getFuelRecordsByVehicleId(vehicleId);
  }
}
