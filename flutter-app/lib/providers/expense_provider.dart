import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String _filterType = 'all';

  List<Expense> get expenses => _filteredExpenses;
  bool get isLoading => _isLoading;
  String get filterType => _filterType;

  List<Expense> get _filteredExpenses {
    if (_filterType == 'all') return _expenses;
    return _expenses.where((e) => e.type == _filterType).toList();
  }

  double get totalExpenses {
    double sum = 0;
    for (final e in _expenses) { sum += e.amount; }
    return sum;
  }

  double get fuelCost {
    double sum = 0;
    for (final e in _expenses.where((e) => e.type == 'fuel')) { sum += e.amount; }
    return sum;
  }

  double get maintenanceCost {
    double sum = 0;
    for (final e in _expenses.where((e) => e.type == 'maintenance')) { sum += e.amount; }
    return sum;
  }

  double get tollCost {
    double sum = 0;
    for (final e in _expenses.where((e) => e.type == 'toll')) { sum += e.amount; }
    return sum;
  }

  double get violationCost {
    double sum = 0;
    for (final e in _expenses.where((e) => e.type == 'violation')) { sum += e.amount; }
    return sum;
  }

  double get insuranceCost {
    double sum = 0;
    for (final e in _expenses.where((e) => e.type == 'insurance')) { sum += e.amount; }
    return sum;
  }

  double get miscCost {
    double sum = 0;
    for (final e in _expenses.where((e) => e.type == 'miscellaneous')) { sum += e.amount; }
    return sum;
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _expenses = await DatabaseService.getAllExpenses();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadExpensesByVehicle(int vehicleId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _expenses = await DatabaseService.getExpensesByVehicleId(vehicleId);
    } catch (e) {
      debugPrint('Error loading vehicle expenses: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String type) {
    _filterType = type;
    notifyListeners();
  }

  Future<int> addExpense(Expense expense) async {
    final id = await DatabaseService.insertExpense(expense);
    await loadExpenses();
    ConnectivityService.onWriteOperation('expense');
    return id;
  }

  Future<int> updateExpense(Expense expense) async {
    final result = await DatabaseService.updateExpense(expense);
    if (result > 0) await loadExpenses();
    ConnectivityService.onWriteOperation('expense');
    return result;
  }

  Future<int> deleteExpense(int id) async {
    final result = await DatabaseService.deleteExpense(id);
    if (result > 0) await loadExpenses();
    ConnectivityService.onWriteOperation('expense');
    return result;
  }
}
