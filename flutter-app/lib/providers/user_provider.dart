import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class UserProvider extends ChangeNotifier {
  // ── In-memory user list (mirrors DatabaseService pattern) ──
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _roleFilter = 'all';
  String? _currentRole;

  List<AppUser> get users => _filteredUsers;
  List<AppUser> get allUsers => _users;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get roleFilter => _roleFilter;

  /// The role of the currently logged-in user.
  String? get currentRole => _currentRole;

  // ── Role label map (Arabic) ──
  static const Map<String, String> roleLabels = {
    'admin': 'مدير النظام',
    'supervisor': 'مشرف',
    'driver': 'سائق',
  };

  static String getRoleLabel(String role) {
    return roleLabels[role] ?? role;
  }

  // ── Role icon map ──
  static const Map<String, String> roleIcons = {
    'admin': 'shield',
    'supervisor': 'supervisor',
    'driver': 'drive',
  };

  UserProvider() {
    _loadCurrentRole();
    _seedUsers();
  }

  // ── SharedPreferences: current user role ──

  Future<void> _loadCurrentRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentRole = prefs.getString('current_user_role');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading current role: $e');
    }
  }

  /// Set the current user role (called on login).
  Future<void> setCurrentRole(String role) async {
    _currentRole = role;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_role', role);
    } catch (e) {
      debugPrint('Error saving current role: $e');
    }
    notifyListeners();
  }

  /// Clear the current user role (called on logout).
  Future<void> clearCurrentRole() async {
    _currentRole = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_role');
    } catch (e) {
      debugPrint('Error clearing current role: $e');
    }
    notifyListeners();
  }

  // ── Seed default users ──

  void _seedUsers() {
    final now = DateTime.now();
    _users = [
      AppUser(
        id: 1,
        email: 'admin@kms.com',
        displayName: 'مدير النظام',
        role: 'admin',
        phone: '0500000001',
        isActive: true,
        lastLogin: now,
        createdAt: now,
        updatedAt: now,
      ),
      AppUser(
        id: 2,
        email: 'supervisor@kms.com',
        displayName: 'أحمد المشرف',
        role: 'supervisor',
        phone: '0500000002',
        isActive: true,
        lastLogin: now.subtract(const Duration(hours: 3)),
        createdAt: now,
        updatedAt: now,
      ),
      AppUser(
        id: 3,
        email: 'driver@kms.com',
        displayName: 'محمد السائق',
        role: 'driver',
        phone: '0500000003',
        isActive: true,
        lastLogin: now.subtract(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      ),
    ];
    _filteredUsers = List.from(_users);
  }

  // ── Load users ──

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    // Simulate async load (uses in-memory store)
    await Future.delayed(const Duration(milliseconds: 200));
    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  // ── CRUD ──

  Future<int> addUser(AppUser user) async {
    final maxId = _users.isEmpty
        ? 0
        : _users.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
    final newUser = user.copyWith(id: maxId + 1);
    _users.insert(0, newUser);
    _applyFilters();
    notifyListeners();
    return maxId + 1;
  }

  Future<bool> updateUser(AppUser user) async {
    for (int i = 0; i < _users.length; i++) {
      if (_users[i].id == user.id) {
        _users[i] = user.copyWith(updatedAt: DateTime.now());
        _applyFilters();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<bool> deleteUser(int id) async {
    final removed = _users.length;
    _users.removeWhere((u) => u.id == id);
    if (_users.length < removed) {
      _applyFilters();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> toggleUserActive(int id) async {
    for (int i = 0; i < _users.length; i++) {
      if (_users[i].id == id) {
        _users[i] = _users[i].copyWith(
          isActive: !_users[i].isActive,
          updatedAt: DateTime.now(),
        );
        _applyFilters();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Update last login timestamp for a user.
  Future<bool> updateLastLogin(int id) async {
    for (int i = 0; i < _users.length; i++) {
      if (_users[i].id == id) {
        _users[i] = _users[i].copyWith(lastLogin: DateTime.now());
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Find user by email.
  AppUser? getUserByEmail(String email) {
    for (final u in _users) {
      if (u.email.toLowerCase() == email.toLowerCase()) return u;
    }
    return null;
  }

  /// Find user by id.
  AppUser? getUserById(int id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  // ── Search & Filter ──

  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    _applyFilters();
  }

  void setRoleFilter(String role) {
    _roleFilter = role;
    _applyFilters();
  }

  void _applyFilters() {
    var result = _users;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((u) =>
              u.displayName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.phone.contains(q))
          .toList();
    }

    if (_roleFilter != 'all') {
      result = result.where((u) => u.role == _roleFilter).toList();
    }

    _filteredUsers = result;
    notifyListeners();
  }

  // ── Permission helpers (based on current role) ──

  bool get canManageUsers =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('manage_users');

  bool get canDeleteVehicles =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('delete_vehicles');

  bool get canAddMaintenance =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('add_maintenance');

  bool get canEditMaintenance =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('edit_maintenance');

  bool get canAddFuel =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('add_fuel');

  bool get canEditFuel =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('edit_fuel');

  bool get canAddChecklist =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('add_checklist');

  bool get canEditChecklist =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('edit_checklist');

  bool get canViewReports =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('view_reports');

  bool get canAddExpense =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('add_expense');

  bool get canEditExpense =>
      _currentRole == 'admin' ||
      AppUser(role: _currentRole ?? 'driver').hasPermission('edit_expense');

  bool get isAdmin => _currentRole == 'admin';
  bool get isSupervisor => _currentRole == 'supervisor';
  bool get isDriver => _currentRole == 'driver';

  /// Check a specific permission against the current role.
  bool hasCurrentPermission(String permission) {
    return AppUser(role: _currentRole ?? 'driver').hasPermission(permission);
  }

  // ── Stats ──
  int get totalUsers => _users.length;
  int get activeUsers => _users.where((u) => u.isActive).length;
  int get adminCount => _users.where((u) => u.role == 'admin').length;
  int get supervisorCount => _users.where((u) => u.role == 'supervisor').length;
  int get driverCount => _users.where((u) => u.role == 'driver').length;
}
