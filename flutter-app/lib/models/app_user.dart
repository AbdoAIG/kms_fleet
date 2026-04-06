class AppUser {
  final int? id;
  final String email;
  final String displayName;
  final String role; // 'admin', 'supervisor', 'driver'
  final String phone;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.phone = '',
    this.isActive = true,
    this.lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ── Role helpers ──
  bool get isAdmin => role == 'admin';
  bool get isSupervisor => role == 'supervisor';
  bool get isDriver => role == 'driver';

  // ── Role-based permissions ──
  bool hasPermission(String permission) {
    switch (role) {
      case 'admin':
        return true; // admin has all permissions
      case 'supervisor':
        return _supervisorPermissions.contains(permission);
      case 'driver':
        return _driverPermissions.contains(permission);
      default:
        return false;
    }
  }

  /// Permissions for supervisor role:
  /// - Can view all data
  /// - Can add/edit maintenance, fuel, checklists
  /// - Cannot manage users
  /// - Cannot delete vehicles
  static const _supervisorPermissions = {
    'view_all',
    'add_maintenance',
    'edit_maintenance',
    'add_fuel',
    'edit_fuel',
    'add_checklist',
    'edit_checklist',
    'view_reports',
    'add_expense',
    'edit_expense',
  };

  /// Permissions for driver role:
  /// - Can only view assigned vehicle
  /// - Can add fuel records and checklists for assigned vehicle
  /// - Cannot view reports
  /// - Cannot manage anything
  static const _driverPermissions = {
    'view_assigned_vehicle',
    'add_fuel',
    'add_checklist',
  };

  // ── copyWith ──
  AppUser copyWith({
    int? id,
    String? email,
    String? displayName,
    String? role,
    String? phone,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Serialization ──
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role,
      'phone': phone,
      'is_active': isActive ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      role: map['role'] as String? ?? 'driver',
      phone: map['phone'] as String? ?? '',
      isActive: (map['is_active'] as int?) == 1 ||
          (map['is_active'] as bool?) == true,
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
