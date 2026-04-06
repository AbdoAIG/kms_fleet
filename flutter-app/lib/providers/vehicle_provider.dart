import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  List<Vehicle> get vehicles => _filteredVehicles;
  List<Vehicle> get allVehicles => _vehicles;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get typeFilter => _typeFilter;

  VehicleProvider();

  Future<void> loadVehicles() async {
    _isLoading = true;
    notifyListeners();
    try {
      _vehicles = await DatabaseService.getAllVehicles();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchVehicles(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _applyFilters();
      return;
    }
    try {
      final results = await DatabaseService.searchVehicles(query);
      _filteredVehicles = results
          .where((v) =>
              (_statusFilter == 'all' || v.status == _statusFilter) &&
              (_typeFilter == 'all' || v.vehicleType == _typeFilter))
          .toList();
    } catch (e) {
      debugPrint('Error searching vehicles: $e');
    }
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    _applyFilters();
  }

  void _applyFilters() {
    var result = _vehicles;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((v) =>
              v.plateNumber.toLowerCase().contains(q) ||
              v.make.toLowerCase().contains(q) ||
              v.model.toLowerCase().contains(q) ||
              (v.driverName != null && v.driverName!.toLowerCase().contains(q)))
          .toList();
    }
    if (_statusFilter != 'all') {
      result = result.where((v) => v.status == _statusFilter).toList();
    }
    if (_typeFilter != 'all') {
      result = result.where((v) => v.vehicleType == _typeFilter).toList();
    }
    _filteredVehicles = result;
    notifyListeners();
  }

  Future<int> addVehicle(Vehicle vehicle) async {
    final id = await DatabaseService.insertVehicle(vehicle);
    await loadVehicles();
    return id;
  }

  Future<bool> updateVehicle(Vehicle vehicle) async {
    final rows = await DatabaseService.updateVehicle(vehicle);
    await loadVehicles();
    return rows > 0;
  }

  Future<bool> deleteVehicle(int id) async {
    final rows = await DatabaseService.deleteVehicle(id);
    await loadVehicles();
    return rows > 0;
  }
}
