import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/work_order.dart';
import '../models/fuel_record.dart';
import '../models/driver_violation.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';

// ── Notification Model ───────────────────────────────────────────────────

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type; // 'maintenance', 'license', 'fuel', 'work_order', 'violation', 'vehicle_status'
  final IconData icon;
  final Color color;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.icon,
    required this.color,
    required this.time,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      icon: icon,
      color: color,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}

// ── Notification Provider ────────────────────────────────────────────────

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  static const String _readIdsKey = 'notification_read_ids';

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Deterministic ID Generation ────────────────────────────────────────
  // Uses a simple DJB2 hash so the same notification always gets the same ID
  // even after regeneration, allowing SharedPreferences read-state to persist.

  static int _djb2Hash(String str) {
    int hash = 5381;
    for (int i = 0; i < str.length; i++) {
      hash = ((hash << 5) + hash) + str.codeUnitAt(i);
    }
    return hash.abs();
  }

  // ── Periodic Refresh ───────────────────────────────────────────────────

  void _startPeriodicRefresh() {
    generateNotifications();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      generateNotifications();
    });
  }

  // ── Read State Persistence ─────────────────────────────────────────────

  Future<Set<int>> _getReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsString = prefs.getStringList(_readIdsKey);
      if (idsString != null) {
        return idsString
            .map((s) => int.tryParse(s) ?? -1)
            .where((id) => id > 0)
            .toSet();
      }
    } catch (_) {}
    return <int>{};
  }

  Future<void> _saveReadId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = await _getReadIds();
      readIds.add(id);
      await prefs.setStringList(
        _readIdsKey,
        readIds.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  Future<void> _saveAllReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _notifications.map((n) => n.id.toString()).toList();
      await prefs.setStringList(_readIdsKey, ids);
    } catch (_) {}
  }

  Future<void> _clearReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_readIdsKey);
    } catch (_) {}
  }

  // ── Public Actions ─────────────────────────────────────────────────────

  Future<void> markAsRead(int id) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].id == id && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        await _saveReadId(id);
        notifyListeners();
        break;
      }
    }
  }

  Future<void> markAllAsRead() async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      await _saveAllReadIds();
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _notifications = [];
    await _clearReadIds();
    notifyListeners();
  }

  // ── Generate Notifications from Real Data ──────────────────────────────

  Future<void> generateNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final readIds = await _getReadIds();
      final List<AppNotification> newNotifications = [];

      // Fetch all data sources in parallel
      final results = await Future.wait([
        DatabaseService.getAllVehicles(),
        DatabaseService.getAllMaintenanceRecords(),
        DatabaseService.getAllWorkOrders(),
        DatabaseService.getAllFuelRecords(),
        DatabaseService.getAllViolations(),
      ]);

      final vehicles = results[0] as List<Vehicle>;
      final maintenanceRecords = results[1] as List<MaintenanceRecord>;
      final workOrders = results[2] as List<WorkOrder>;
      final fuelRecords = results[3] as List<FuelRecord>;
      final violations = results[4] as List<DriverViolation>;

      final now = DateTime.now();

      // ── 1. Maintenance notifications: pending for more than 3 days ──
      for (final record in maintenanceRecords) {
        if (record.status == 'pending') {
          final daysSince = now.difference(record.createdAt).inDays;
          if (daysSince > 3) {
            final vehicleName = _getVehicleName(vehicles, record.vehicleId);
            final id = _djb2Hash('maint_${record.id}');
            newNotifications.add(AppNotification(
              id: id,
              title: 'صيانة معلقة منذ $daysSince يوم',
              body: '$vehicleName - ${record.description}',
              type: 'maintenance',
              icon: Icons.build_circle_outlined,
              color: AppColors.warning,
              time: record.createdAt,
              isRead: readIds.contains(id),
            ));
          }
        }
      }

      // ── 2. License expiry: within 30 days or already expired ──
      for (final vehicle in vehicles) {
        if (vehicle.driverLicenseExpiry != null) {
          final expiry = vehicle.driverLicenseExpiry!;
          final today = DateTime(now.year, now.month, now.day);
          final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
          final daysRemaining = expiryDay.difference(today).inDays;

          if (daysRemaining < 0) {
            // Already expired
            final driver = vehicle.driverName ?? 'سائق غير محدد';
            final id = _djb2Hash('license_expired_${vehicle.id}');
            newNotifications.add(AppNotification(
              id: id,
              title: 'رخصة سائق منتهية الصلاحية',
              body:
                  '$driver - انتهت منذ ${-daysRemaining} يوم (${vehicle.plateNumber})',
              type: 'license',
              icon: Icons.card_membership,
              color: AppColors.error,
              time: expiry,
              isRead: readIds.contains(id),
            ));
          } else if (daysRemaining <= 30) {
            // Expiring within 30 days
            final driver = vehicle.driverName ?? 'سائق غير محدد';
            final id = _djb2Hash('license_soon_${vehicle.id}');
            newNotifications.add(AppNotification(
              id: id,
              title: 'تنبيه انتهاء رخصة القيادة',
              body:
                  '$driver - تنتهي بعد $daysRemaining يوم (${AppFormatters.formatDate(expiry)})',
              type: 'license',
              icon: Icons.card_membership,
              color: AppColors.warning,
              time: now,
              isRead: readIds.contains(id),
            ));
          }
        }
      }

      // ── 3. Abnormal fuel records ──
      for (final fuel in fuelRecords) {
        if (fuel.isAbnormal == true) {
          final vehicleName = _getVehicleName(vehicles, fuel.vehicleId);
          final id = _djb2Hash('fuel_${fuel.id}');
          newNotifications.add(AppNotification(
            id: id,
            title: 'استهلاك وقود غير طبيعي',
            body:
                '$vehicleName - معدل استهلاك مرتفع (${AppFormatters.formatOdometer(fuel.odometerReading)})',
            type: 'fuel',
            icon: Icons.local_gas_station_outlined,
            color: AppColors.accent,
            time: fuel.createdAt,
            isRead: readIds.contains(id),
          ));
        }
      }

      // ── 4. Work order alerts: urgent priority still open ──
      for (final order in workOrders) {
        if (order.status != 'completed') {
          if (order.priority == 'urgent') {
            final vehicleName = _getVehicleName(vehicles, order.vehicleId);
            final daysOpen = now.difference(order.createdAt).inDays;
            final id = _djb2Hash('wo_urgent_${order.id}');
            newNotifications.add(AppNotification(
              id: id,
              title: 'أمر عمل عاجل مفتوح',
              body:
                  '$vehicleName - ${order.description ?? "بدون وصف"} (منذ $daysOpen يوم)',
              type: 'work_order',
              icon: Icons.construction,
              color: AppColors.error,
              time: order.createdAt,
              isRead: readIds.contains(id),
            ));
          } else if (order.priority == 'high' && order.status == 'open') {
            final vehicleName = _getVehicleName(vehicles, order.vehicleId);
            final id = _djb2Hash('wo_high_${order.id}');
            newNotifications.add(AppNotification(
              id: id,
              title: 'أمر عمل ذو أولوية عالية',
              body: '$vehicleName - ${order.description ?? "بدون وصف"}',
              type: 'work_order',
              icon: Icons.construction,
              color: AppColors.warning,
              time: order.createdAt,
              isRead: readIds.contains(id),
            ));
          }
        }
      }

      // ── 5. Violation alerts: unpaid (status='pending') ──
      for (final violation in violations) {
        if (violation.status == 'pending') {
          final vehicleName =
              _getVehicleName(vehicles, violation.vehicleId ?? 0);
          final id = _djb2Hash('violation_${violation.id}');
          newNotifications.add(AppNotification(
            id: id,
            title: 'مخالفة مرورية غير مدفوعة',
            body:
                '$vehicleName - ${violation.description} (المبلغ: ${AppFormatters.formatCurrency(violation.amount)})',
            type: 'violation',
            icon: Icons.gavel,
            color: AppColors.error,
            time: violation.createdAt,
            isRead: readIds.contains(id),
          ));
        }
      }

      // ── 6. Vehicle status: in 'maintenance' for more than 7 days ──
      for (final vehicle in vehicles) {
        if (vehicle.status == 'maintenance') {
          final daysInMaintenance = now.difference(vehicle.updatedAt).inDays;
          if (daysInMaintenance > 7) {
            final driver = vehicle.driverName ?? 'بدون سائق';
            final id = _djb2Hash('vstatus_${vehicle.id}');
            newNotifications.add(AppNotification(
              id: id,
              title: 'مركبة في الصيانة منذ فترة طويلة',
              body:
                  '${vehicle.make} ${vehicle.model} (${vehicle.plateNumber}) - السائق: $driver - منذ $daysInMaintenance يوم',
              type: 'vehicle_status',
              icon: Icons.directions_car_outlined,
              color: AppColors.info,
              time: vehicle.updatedAt,
              isRead: readIds.contains(id),
            ));
          }
        }
      }

      // Sort by time descending (newest first)
      newNotifications.sort((a, b) => b.time.compareTo(a.time));

      _notifications = newNotifications;
    } catch (e) {
      debugPrint('خطأ في إنشاء الإشعارات: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Helper: Get vehicle display name from list ─────────────────────────

  String _getVehicleName(List<Vehicle> vehicles, int vehicleId) {
    for (final v in vehicles) {
      if (v.id == vehicleId) {
        return '${v.make} ${v.model} (${v.plateNumber})';
      }
    }
    return 'مركبة #$vehicleId';
  }
}
