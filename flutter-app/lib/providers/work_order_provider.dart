import 'package:flutter/foundation.dart';
import '../models/work_order.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

class WorkOrderProvider extends ChangeNotifier {
  List<WorkOrder> _orders = [];
  List<WorkOrder> _filteredOrders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  List<WorkOrder> get orders => _filteredOrders;
  List<WorkOrder> get allOrders => _orders;
  bool get isLoading => _isLoading;

  int get openCount => _orders.where((o) => o.status == 'open').length;
  int get inProgressCount => _orders.where((o) => o.status == 'in_progress').length;
  int get completedCount => _orders.where((o) => o.status == 'completed').length;
  int get overBudgetCount => _orders.where((o) => o.isOverBudget).length;

  double get totalEstimated {
    double sum = 0;
    for (final o in _orders) { sum += o.estimatedCost ?? 0; }
    return sum;
  }

  double get totalActual {
    double sum = 0;
    for (final o in _orders) { sum += o.actualCost ?? 0; }
    return sum;
  }

  WorkOrderProvider();

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await DatabaseService.getAllWorkOrders();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading work orders: $e');
    }
    _isLoading = false;
    notifyListeners();
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

  void _applyFilters() {
    var result = _orders;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((o) =>
          (o.description?.toLowerCase().contains(q) ?? false) ||
          (o.technicianName?.toLowerCase().contains(q) ?? false) ||
          (o.vehicle?.plateNumber.toLowerCase().contains(q) ?? false) ||
          (o.vehicle?.make.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    if (_statusFilter != 'all') {
      result = result.where((o) => o.status == _statusFilter).toList();
    }

    if (_typeFilter != 'all') {
      result = result.where((o) => o.type == _typeFilter).toList();
    }

    _filteredOrders = result;
    notifyListeners();
  }

  Future<int> addOrder(WorkOrder order) async {
    final id = await DatabaseService.insertWorkOrder(order);
    await loadOrders();
    ConnectivityService.onWriteOperation('work_order');
    return id;
  }

  Future<bool> updateOrder(WorkOrder order) async {
    final rows = await DatabaseService.updateWorkOrder(order);
    await loadOrders();
    ConnectivityService.onWriteOperation('work_order');
    return rows > 0;
  }

  Future<bool> deleteOrder(int id) async {
    final rows = await DatabaseService.deleteWorkOrder(id);
    await loadOrders();
    ConnectivityService.onWriteOperation('work_order');
    return rows > 0;
  }

  Future<bool> advanceStatus(WorkOrder order) async {
    String newStatus;
    switch (order.status) {
      case 'open':
        newStatus = 'in_progress';
        break;
      case 'in_progress':
        newStatus = 'completed';
        break;
      default:
        return false;
    }

    final updated = order.copyWith(
      status: newStatus,
      startDate: newStatus == 'in_progress' && order.startDate == null ? DateTime.now() : order.startDate,
      completedDate: newStatus == 'completed' ? DateTime.now() : order.completedDate,
    );
    return updateOrder(updated);
  }
}
