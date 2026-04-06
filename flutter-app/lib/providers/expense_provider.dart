import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _typeFilter = 'all';

  List<Expense> get expenses => _filteredExpenses;
  List<Expense> get allExpenses => _expenses;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;

  ExpenseProvider();

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _expenses = await DatabaseService.getAllExpenses();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void searchExpenses(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    _applyFilters();
  }

  void _applyFilters() {
    var result = _expenses;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) {
        final desc = (e.description ?? '').toLowerCase();
        final provider = (e.serviceProvider ?? '').toLowerCase();
        final invoice = (e.invoiceNumber ?? '').toLowerCase();
        return desc.contains(q) || provider.contains(q) || invoice.contains(q);
      }).toList();
    }
    if (_typeFilter != 'all') {
      result = result.where((e) => e.type == _typeFilter).toList();
    }
    _filteredExpenses = result;
    notifyListeners();
  }

  Future<int> addExpense(Expense expense) async {
    final id = await DatabaseService.insertExpense(expense);
    await loadExpenses();
    return id;
  }

  Future<bool> updateExpense(Expense expense) async {
    final rows = await DatabaseService.updateExpense(expense);
    await loadExpenses();
    return rows > 0;
  }

  Future<bool> deleteExpense(int id) async {
    final rows = await DatabaseService.deleteExpense(id);
    await loadExpenses();
    return rows > 0;
  }
}
