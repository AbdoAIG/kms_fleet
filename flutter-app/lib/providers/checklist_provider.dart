import 'package:flutter/foundation.dart';
import '../models/checklist.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

class ChecklistProvider extends ChangeNotifier {
  List<Checklist> _checklists = [];
  List<Checklist> _filteredChecklists = [];
  bool _isLoading = false;
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  int? _vehicleFilter;

  List<Checklist> get checklists => _filteredChecklists;
  List<Checklist> get allChecklists => _checklists;
  bool get isLoading => _isLoading;
  String get typeFilter => _typeFilter;
  String get statusFilter => _statusFilter;
  int? get vehicleFilter => _vehicleFilter;

  ChecklistProvider();

  Future<void> loadChecklists() async {
    _isLoading = true;
    notifyListeners();
    try {
      _checklists = await DatabaseService.getAllChecklists();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading checklists: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadChecklistsForVehicle(int vehicleId) async {
    _isLoading = true;
    _vehicleFilter = vehicleId;
    notifyListeners();
    try {
      _checklists = await DatabaseService.getChecklistsByVehicleId(vehicleId);
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading vehicle checklists: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void resetFilters() {
    _typeFilter = 'all';
    _statusFilter = 'all';
    _vehicleFilter = null;
    loadChecklists();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    _applyFilters();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setVehicleFilter(int? vehicleId) {
    _vehicleFilter = vehicleId;
    _applyFilters();
  }

  void _applyFilters() {
    var result = _checklists;

    if (_vehicleFilter != null) {
      result = result.where((c) => c.vehicleId == _vehicleFilter).toList();
    }

    if (_typeFilter != 'all') {
      result = result.where((c) => c.type == _typeFilter).toList();
    }

    if (_statusFilter != 'all') {
      result = result.where((c) => c.status == _statusFilter).toList();
    }

    _filteredChecklists = result;
    notifyListeners();
  }

  Future<int> addChecklist(Checklist checklist) async {
    final id = await DatabaseService.insertChecklist(checklist);
    await loadChecklists();
    ConnectivityService.onWriteOperation('checklist');
    return id;
  }

  Future<bool> updateChecklist(Checklist checklist) async {
    final rows = await DatabaseService.updateChecklist(checklist);
    await loadChecklists();
    ConnectivityService.onWriteOperation('checklist');
    return rows > 0;
  }

  Future<bool> deleteChecklist(int id) async {
    final rows = await DatabaseService.deleteChecklist(id);
    await loadChecklists();
    ConnectivityService.onWriteOperation('checklist');
    return rows > 0;
  }

  Future<List<Checklist>> getChecklistsByVehicle(int vehicleId) async {
    return DatabaseService.getChecklistsByVehicleId(vehicleId);
  }
}
