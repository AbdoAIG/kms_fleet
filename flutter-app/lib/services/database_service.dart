import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/checklist.dart';
import '../models/fuel_record.dart';
import '../models/driver_violation.dart';
import '../models/expense.dart';
import '../models/work_order.dart';
import '../models/trip_tracking.dart';
import '../models/app_user.dart';
import 'supabase_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DatabaseService — Supabase-primary with offline memory fallback
// ═══════════════════════════════════════════════════════════════════════════════
//
// When Supabase is available (user signed in + network), all CRUD goes to
// Supabase directly.  When offline or not signed in, data is held in memory
// with seed data so the UI stays functional.

class DatabaseService {
  // ── Offline memory storage ────────────────────────────────────────────────
  static bool _offline = true;
  static List<Vehicle> _memVehicles = [];
  static List<MaintenanceRecord> _memRecords = [];
  static List<Checklist> _memChecklists = [];
  static List<FuelRecord> _memFuelRecords = [];
  static List<DriverViolation> _memViolations = [];
  static List<Expense> _memExpenses = [];
  static List<WorkOrder> _memWorkOrders = [];
  static List<TripTracking> _memTrips = [];
  static List<AppUser> _memUsers = [];

  // ── Supabase convenience ──────────────────────────────────────────────────
  static String? get _uid => currentUserId;
  static bool get _isOnline => !_offline && supabaseReady && _uid != null;
  static final _db = Supabase.instance.client;

  DatabaseService._();

  // ═══════════════════════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> initialize() async {
    try {
      if (supabaseReady && currentUserId != null) {
        _offline = false;
        debugPrint('DB: Using Supabase as primary database');
        return;
      }
    } catch (e) {
      debugPrint('DB: Supabase not available, using offline mode: $e');
    }
    _offline = true;
    _seedMemory();
  }

  /// Call after sign-in to switch from offline to Supabase.
  static Future<void> goOnline() async {
    try {
      if (supabaseReady && currentUserId != null) {
        _offline = false;
        debugPrint('DB: Switched to Supabase online mode');
        // Check if the user has any data, if not seed from memory
        await _seedIfEmpty();
      }
    } catch (e) {
      debugPrint('DB: Failed to go online: $e');
    }
  }

  /// If Supabase tables are empty for this user, seed with sample data.
  static Future<void> _seedIfEmpty() async {
    try {
      final response = await _db.from('vehicles').select('id').eq('user_id', _uid!).limit(1);
      if (response.isEmpty) {
        debugPrint('DB: No data found for user, seeding sample data...');
        // Seed vehicles first (other entities reference them)
        for (final v in _seedVehicles()) {
          await _db.from('vehicles').insert(_toSupabaseRow(v.toMap()));
        }
        for (final r in _seedRecords()) {
          await _db.from('maintenance_records').insert(_toSupabaseRow(r.toMap()));
        }
        for (final c in _seedChecklists()) {
          final map = _toSupabaseRow(c.toMap());
          if (map['items'] is String) {
            try { map['items'] = jsonDecode(map['items']); } catch (_) {}
          }
          await _db.from('checklists').insert(map);
        }
        for (final f in _seedFuelRecords()) {
          final map = _toSupabaseRow(f.toMap());
          if (map['full_tank'] is int) map['full_tank'] = (map['full_tank'] as int) != 0;
          if (map['is_abnormal'] is int) map['is_abnormal'] = (map['is_abnormal'] as int) != 0;
          await _db.from('fuel_records').insert(map);
        }
        for (final v in _seedViolations()) {
          await _db.from('driver_violations').insert(_toSupabaseRow(v.toMap()));
        }
        for (final e in _seedExpenses()) {
          await _db.from('expenses').insert(_toSupabaseRow(e.toMap()));
        }
        for (final o in _seedWorkOrders()) {
          await _db.from('work_orders').insert(_toSupabaseRow(o.toMap()));
        }
        for (final t in _seedTrips()) {
          final map = _toSupabaseRow(t.toMap());
          final rawPoints = map['trip_points_json'];
          if (rawPoints is String && rawPoints.isNotEmpty) {
            try { map['trip_points_json'] = jsonDecode(rawPoints); } catch (_) {}
          }
          await _db.from('trip_trackings').insert(map);
        }
        debugPrint('DB: Sample data seeded successfully');
      }
    } catch (e) {
      debugPrint('DB: Error checking/seeding data: $e');
    }
  }

  /// Call after sign-out to switch back to offline mode.
  static void goOffline() {
    _offline = true;
    _seedMemory();
    debugPrint('DB: Switched to offline mode');
  }

  static void _seedMemory() {
    _memVehicles = _seedVehicles();
    _memRecords = _seedRecords();
    _memChecklists = _seedChecklists();
    _memFuelRecords = _seedFuelRecords();
    _memViolations = _seedViolations();
    _memExpenses = _seedExpenses();
    _memWorkOrders = _seedWorkOrders();
    _memTrips = _seedTrips();
    _memUsers = _seedUsers();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SEED DATA (offline fallback)
  // ═══════════════════════════════════════════════════════════════════════════

  static List<Vehicle> _seedVehicles() {
    final n = DateTime.now();
    return [
      Vehicle(id: 1, plateNumber: 'أ ب ج 1234', make: 'تويوتا', model: 'هايلكس', year: 2023, color: 'white', fuelType: 'diesel', currentOdometer: 45000, status: 'active', vehicleType: 'half_truck', driverName: 'أحمد محمود', createdAt: n, updatedAt: n),
      Vehicle(id: 2, plateNumber: 'د ه و 5678', make: 'هيونداي', model: 'HD78', year: 2022, color: 'white', fuelType: 'diesel', currentOdometer: 62000, status: 'active', vehicleType: 'half_truck', driverName: 'محمد علي', createdAt: n, updatedAt: n),
      Vehicle(id: 3, plateNumber: 'ز ح ط 9012', make: 'ميتسوبيشي', model: 'فوستر', year: 2021, color: 'white', fuelType: 'diesel', currentOdometer: 89000, status: 'active', vehicleType: 'jumbo_truck', driverName: 'حسن إبراهيم', createdAt: n, updatedAt: n),
      Vehicle(id: 4, plateNumber: 'ي ك ل 3456', make: 'تويوتا', model: 'هايلكس دبل', year: 2023, color: 'white', fuelType: 'diesel', currentOdometer: 28000, status: 'active', vehicleType: 'double_cabin', driverName: 'خالد سعيد', createdAt: n, updatedAt: n),
      Vehicle(id: 5, plateNumber: 'م ن س 7890', make: 'مرسيدس', model: 'O500', year: 2020, color: 'white', fuelType: 'diesel', currentOdometer: 135000, status: 'active', vehicleType: 'bus', driverName: 'عمر فاروق', createdAt: n, updatedAt: n),
      Vehicle(id: 6, plateNumber: 'ع ف ق 2345', make: 'تويوتا', model: 'هاييس', year: 2019, color: 'white', fuelType: 'diesel', currentOdometer: 120000, status: 'active', vehicleType: 'microbus', driverName: 'ياسر أحمد', createdAt: n, updatedAt: n),
      Vehicle(id: 7, plateNumber: 'ر ش ت 6789', make: 'تويوتا', model: '7FB', year: 2022, color: 'yellow', fuelType: 'diesel', currentOdometer: 8000, status: 'active', vehicleType: 'forklift', driverName: 'عبدالله حسن', createdAt: n, updatedAt: n),
      Vehicle(id: 8, plateNumber: 'ث خ ذ 0123', make: 'نيسان', model: 'ديزل', year: 2021, color: 'white', fuelType: 'diesel', currentOdometer: 78000, status: 'inactive', vehicleType: 'jumbo_truck', driverName: 'محمود سالم', createdAt: n, updatedAt: n),
      Vehicle(id: 9, plateNumber: 'ض ظ غ 4567', make: 'تويوتا', model: 'هايلكس دبل', year: 2023, color: 'black', fuelType: 'diesel', currentOdometer: 22000, status: 'maintenance', vehicleType: 'double_cabin', driverName: 'طه عبدالرحمن', createdAt: n, updatedAt: n),
      Vehicle(id: 10, plateNumber: 'ج ث ب 8901', make: 'هيونداي', model: 'كاونتري', year: 2022, color: 'white', fuelType: 'diesel', currentOdometer: 55000, status: 'active', vehicleType: 'microbus', driverName: 'إبراهيم عثمان', createdAt: n, updatedAt: n),
      Vehicle(id: 11, plateNumber: 'ن ح ي 2468', make: 'فولكس واجن', model: 'تارو', year: 2021, color: 'white', fuelType: 'diesel', currentOdometer: 92000, status: 'active', vehicleType: 'half_truck', driverName: 'كريم حسام', createdAt: n, updatedAt: n),
      Vehicle(id: 12, plateNumber: 'و ك م 1357', make: 'تويوتا', model: '8FB', year: 2023, color: 'yellow', fuelType: 'diesel', currentOdometer: 18000, status: 'active', vehicleType: 'forklift', driverName: 'رامي شريف', createdAt: n, updatedAt: n),
    ];
  }

  static List<MaintenanceRecord> _seedRecords() {
    final n = DateTime.now();
    return [
      MaintenanceRecord(id: 1, vehicleId: 1, maintenanceDate: n, description: 'تغيير زيت المحرك والفلتر', type: 'oil_change', odometerReading: 44500, cost: 450, laborCost: 50, serviceProvider: 'مركز تويوتا', invoiceNumber: 'INV-001', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 2, vehicleId: 1, maintenanceDate: n, description: 'فحص وتبديل الإطارات الأمامية', type: 'tires', odometerReading: 42000, cost: 1200, laborCost: 100, serviceProvider: 'مركز الإطارات', invoiceNumber: 'INV-002', priority: 'high', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 3, vehicleId: 2, maintenanceDate: n, description: 'إصلاح مشكلة التكييف', type: 'ac', odometerReading: 61900, cost: 800, laborCost: 200, serviceProvider: 'ورشة التكييف', invoiceNumber: 'INV-003', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 4, vehicleId: 2, maintenanceDate: n, description: 'تغيير فرامل أمامية', type: 'brakes', odometerReading: 63000, cost: 650, laborCost: 150, serviceProvider: 'مركز هيونداي', invoiceNumber: 'INV-004', priority: 'high', status: 'pending', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 5, vehicleId: 3, maintenanceDate: n, description: 'تغيير بطارية جديدة', type: 'battery', odometerReading: 88500, cost: 550, status: 'completed', serviceProvider: 'محل البطاريات', invoiceNumber: 'INV-005', priority: 'urgent', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 6, vehicleId: 3, maintenanceDate: n, description: 'صيانة دورية شاملة', type: 'inspection', odometerReading: 85000, cost: 350, laborCost: 200, serviceProvider: 'وكالة نيسان', invoiceNumber: 'INV-006', priority: 'low', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 7, vehicleId: 4, maintenanceDate: n, description: 'تغيير فلاتر الهواء والوقود', type: 'filter', odometerReading: 27000, cost: 280, laborCost: 80, serviceProvider: 'مركز كيا', invoiceNumber: 'INV-007', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 8, vehicleId: 5, maintenanceDate: n, description: 'إصلاح ناقل الحركة', type: 'transmission', odometerReading: 34800, cost: 3500, laborCost: 800, serviceProvider: 'مركز مرسيدس', invoiceNumber: 'INV-008', priority: 'urgent', status: 'in_progress', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 9, vehicleId: 6, maintenanceDate: n, description: 'صيانة الدفع الرباعي', type: 'mechanical', odometerReading: 118000, cost: 1800, laborCost: 500, serviceProvider: 'مركز تويوتا', invoiceNumber: 'INV-009', priority: 'high', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 10, vehicleId: 6, maintenanceDate: n, description: 'تبديل الإطارات الأربعة', type: 'tires', odometerReading: 110000, cost: 2400, laborCost: 200, serviceProvider: 'مركز الإطارات', invoiceNumber: 'INV-010', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 11, vehicleId: 7, maintenanceDate: n, description: 'تغيير زيت أول صيانة', type: 'oil_change', odometerReading: 10000, cost: 350, serviceProvider: 'مركز هيونداي', invoiceNumber: 'INV-011', priority: 'low', status: 'pending', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 12, vehicleId: 8, maintenanceDate: n, description: 'إصلاح كهربائي شامل', type: 'electrical', odometerReading: 75000, cost: 2200, laborCost: 600, serviceProvider: 'ورشة كهرباء', invoiceNumber: 'INV-012', priority: 'high', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 13, vehicleId: 9, maintenanceDate: n, description: 'تركيب حماية الهيكل', type: 'body', odometerReading: 21800, cost: 1500, laborCost: 300, serviceProvider: 'مركز الصيانة', invoiceNumber: 'INV-013', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 14, vehicleId: 10, maintenanceDate: n, description: 'تغيير زيت وفلاتر', type: 'oil_change', odometerReading: 54000, cost: 600, laborCost: 100, serviceProvider: 'مركز تويوتا', invoiceNumber: 'INV-014', priority: 'medium', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 15, vehicleId: 11, maintenanceDate: n, description: 'إصلاح كهرباء', type: 'electrical', odometerReading: 91000, cost: 950, laborCost: 250, serviceProvider: 'مركز بي إم دبليو', invoiceNumber: 'INV-016', priority: 'high', status: 'completed', createdAt: n, updatedAt: n),
      MaintenanceRecord(id: 16, vehicleId: 12, maintenanceDate: n, description: 'صيانة أولى', type: 'inspection', odometerReading: 15000, cost: 0, status: 'completed', serviceProvider: 'وكالة أودي', invoiceNumber: 'INV-017', priority: 'low', createdAt: n, updatedAt: n),
    ];
  }

  static List<Checklist> _seedChecklists() {
    final n = DateTime.now();
    return [
      Checklist(id: 1, vehicleId: 1, type: 'pre_trip', inspectionDate: n, odometerReading: 44800, items: [
        ChecklistItem(title: 'الإطارات', description: 'فحص حالة الإطارات', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الأضواء', description: 'فحص جميع الأضواء', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الزيت', description: 'فحص مستوى الزيت', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الفرامل', description: 'فحص الفرامل', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الرياح', description: 'فحص زجاج الرياح', isChecked: false, hasDefect: true, defectNotes: 'شرخ صغير في الزجاج الأمامي'),
      ], inspectorName: 'أحمد محمد', status: 'completed', overallScore: 85.0, createdAt: n, updatedAt: n),
      Checklist(id: 2, vehicleId: 2, type: 'post_trip', inspectionDate: n, odometerReading: 61800, items: [
        ChecklistItem(title: 'الإطارات', description: 'فحص حالة الإطارات', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الأضواء', description: 'فحص جميع الأضواء', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'المقصورة', description: 'فحص نظافة المقصورة', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الوقود', description: 'فحص مستوى الوقود', isChecked: true, hasDefect: false),
      ], inspectorName: 'خالد علي', status: 'completed', overallScore: 100.0, createdAt: n, updatedAt: n),
      Checklist(id: 3, vehicleId: 3, type: 'weekly', inspectionDate: n, odometerReading: 88200, items: [
        ChecklistItem(title: 'المحرك', description: 'فحص حالة المحرك', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'البطارية', description: 'فحص البطارية', isChecked: true, hasDefect: true, defectNotes: 'البطارية ضعيفة تحتاج تبديل'),
        ChecklistItem(title: 'المبرد', description: 'فحص المبرد', isChecked: false, hasDefect: false),
        ChecklistItem(title: 'السوائل', description: 'فحص مستوى السوائل', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الحزام', description: 'فحص أحزمة المحرك', isChecked: true, hasDefect: false),
      ], inspectorName: 'سعيد حسن', status: 'pending', overallScore: 75.0, createdAt: n, updatedAt: n),
      Checklist(id: 4, vehicleId: 4, type: 'pre_trip', inspectionDate: n, odometerReading: 27600, items: [
        ChecklistItem(title: 'الإطارات', description: 'فحص حالة الإطارات', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الأضواء', description: 'فحص جميع الأضواء', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الزيت', description: 'فحص مستوى الزيت', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الفرامل', description: 'فحص الفرامل', isChecked: false, hasDefect: false),
        ChecklistItem(title: 'الرياح', description: 'فحص زجاج الرياح', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'المرايا', description: 'فحص المرايا', isChecked: true, hasDefect: false),
      ], inspectorName: 'أحمد محمد', status: 'completed', overallScore: 92.0, createdAt: n, updatedAt: n),
      Checklist(id: 5, vehicleId: 6, type: 'pre_trip', inspectionDate: n, odometerReading: 119500, items: [
        ChecklistItem(title: 'الإطارات', description: 'فحص حالة الإطارات', isChecked: true, hasDefect: true, defectNotes: 'إطار خلفي أيمن يحتاج تبديل'),
        ChecklistItem(title: 'الأضواء', description: 'فحص جميع الأضواء', isChecked: true, hasDefect: false),
        ChecklistItem(title: 'الزيت', description: 'فحص مستوى الزيت', isChecked: false, hasDefect: false),
        ChecklistItem(title: 'الفرامل', description: 'فحص الفرامل', isChecked: true, hasDefect: true, defectNotes: 'صوت الفرامل غير طبيعي'),
      ], inspectorName: 'فهد سالم', status: 'pending', overallScore: 60.0, createdAt: n, updatedAt: n),
    ];
  }

  static List<FuelRecord> _seedFuelRecords() {
    final n = DateTime.now();
    return [
      FuelRecord(id: 1, vehicleId: 1, fillDate: n, odometerReading: 43000, liters: 55.0, costPerLiter: 2.33, fuelType: 'petrol', stationName: 'محطة الأفق', stationLocation: 'الرياض', fullTank: true, notes: 'تعبئة كاملة', createdAt: n, updatedAt: n),
      FuelRecord(id: 2, vehicleId: 1, fillDate: n, odometerReading: 44500, liters: 50.0, costPerLiter: 2.33, fuelType: 'petrol', stationName: 'محطة النور', stationLocation: 'الرياض', fullTank: true, createdAt: n, updatedAt: n),
      FuelRecord(id: 3, vehicleId: 2, fillDate: n, odometerReading: 60000, liters: 60.0, costPerLiter: 2.33, fuelType: 'petrol', stationName: 'محطة الوادي', stationLocation: 'جدة', fullTank: true, createdAt: n, updatedAt: n),
      FuelRecord(id: 4, vehicleId: 2, fillDate: n, odometerReading: 61500, liters: 58.0, costPerLiter: 2.33, fuelType: 'petrol', stationName: 'محطة النور', stationLocation: 'جدة', fullTank: true, createdAt: n, updatedAt: n),
      FuelRecord(id: 5, vehicleId: 3, fillDate: n, odometerReading: 87000, liters: 45.0, costPerLiter: 2.33, fuelType: 'petrol', stationName: 'محطة السلام', stationLocation: 'الدمام', fullTank: true, createdAt: n, updatedAt: n),
      FuelRecord(id: 6, vehicleId: 3, fillDate: n, odometerReading: 88500, liters: 55.0, costPerLiter: 2.33, fuelType: 'petrol', stationName: 'محطة الأفق', stationLocation: 'الدمام', fullTank: true, notes: 'استهلاك مرتفع', consumptionRate: 18.3, isAbnormal: true, createdAt: n, updatedAt: n),
    ];
  }

  static List<DriverViolation> _seedViolations() {
    final n = DateTime.now();
    return [
      DriverViolation(id: 1, vehicleId: 5, type: 'speeding', amount: 500, date: n.subtract(const Duration(days: 10)), description: 'سرعة زائدة على طريق القاهرة الإسكندرية', points: 2, status: 'paid', createdAt: n, updatedAt: n),
      DriverViolation(id: 2, vehicleId: 3, type: 'overweight', amount: 300, date: n.subtract(const Duration(days: 5)), description: 'حمل زائد على مركبة نقل', points: 1, status: 'pending', createdAt: n, updatedAt: n),
      DriverViolation(id: 3, vehicleId: 2, type: 'red_light', amount: 1000, date: n.subtract(const Duration(days: 2)), description: 'تجاوز إشارة مرورية حمراء', points: 3, status: 'pending', createdAt: n, updatedAt: n),
    ];
  }

  static List<Expense> _seedExpenses() {
    final n = DateTime.now();
    return [
      Expense(id: 1, vehicleId: 1, type: 'toll', amount: 150, date: n.subtract(const Duration(days: 12)), description: 'رسوم طريق القاهرة السويس', serviceProvider: 'هيئة الطرق والكباري', invoiceNumber: 'TOLL-001', createdAt: n, updatedAt: n),
      Expense(id: 2, vehicleId: 3, type: 'toll', amount: 200, date: n.subtract(const Duration(days: 8)), description: 'رسوم طريق الدائرية', serviceProvider: 'هيئة الطرق والكباري', invoiceNumber: 'TOLL-002', createdAt: n, updatedAt: n),
      Expense(id: 3, vehicleId: 2, type: 'insurance', amount: 5000, date: n.subtract(const Duration(days: 60)), description: 'تجديد تأمين المركبة السنوي', serviceProvider: 'شركة التأمين المصرية', invoiceNumber: 'INS-001', createdAt: n, updatedAt: n),
      Expense(id: 4, vehicleId: 5, type: 'violation', amount: 500, date: n.subtract(const Duration(days: 10)), description: 'غرامة مرورية - سرعة زائدة', serviceProvider: 'الإدارة العامة للمرور', invoiceNumber: 'VIO-001', createdAt: n, updatedAt: n),
      Expense(id: 5, vehicleId: 4, type: 'miscellaneous', amount: 150, date: n.subtract(const Duration(days: 15)), description: 'غسيل وتنظيف المركبة', serviceProvider: 'مركز الغسيل', invoiceNumber: 'MISC-001', createdAt: n, updatedAt: n),
      Expense(id: 6, vehicleId: 6, type: 'miscellaneous', amount: 250, date: n.subtract(const Duration(days: 7)), description: 'تغيير لوحة ترخيص جديدة', serviceProvider: 'مصلحة المرور', invoiceNumber: 'MISC-002', createdAt: n, updatedAt: n),
      Expense(id: 7, vehicleId: 1, type: 'fuel', amount: 550, date: n.subtract(const Duration(days: 3)), description: 'تعبئة وقود - بنزين 95', serviceProvider: 'محطة الأفق', odometerReading: 45500, createdAt: n, updatedAt: n),
      Expense(id: 8, vehicleId: 3, type: 'maintenance', amount: 350, date: n.subtract(const Duration(days: 20)), description: 'تغيير فلتر زيت وفلتر هواء', serviceProvider: 'ورشة الصيانة السريعة', invoiceNumber: 'MAINT-001', odometerReading: 89500, createdAt: n, updatedAt: n),
    ];
  }

  static List<WorkOrder> _seedWorkOrders() {
    final n = DateTime.now();
    return [
      WorkOrder(id: 1, vehicleId: 1, type: 'maintenance', status: 'open', description: 'تغيير زيت المحرك + فلتر الهواء', technicianName: 'أحمد فني', technicianPhone: '01155544433', estimatedCost: 600, priority: 'medium', createdAt: n.subtract(const Duration(days: 1)), updatedAt: n),
      WorkOrder(id: 2, vehicleId: 5, type: 'repair', status: 'in_progress', description: 'إصلاح ناقل الحركة - مشكلة في الفتيس', technicianName: 'محمد ميكانيكي', technicianPhone: '01234455566', estimatedCost: 4000, actualCost: 4500, priority: 'urgent', startDate: n.subtract(const Duration(days: 3)), createdAt: n.subtract(const Duration(days: 5)), updatedAt: n),
      WorkOrder(id: 3, vehicleId: 2, type: 'inspection', status: 'completed', description: 'فحص دوري شامل - 60,000 كم', technicianName: 'خالد فاحص', technicianPhone: '01099988877', estimatedCost: 350, actualCost: 350, priority: 'low', startDate: n.subtract(const Duration(days: 7)), completedDate: n.subtract(const Duration(days: 5)), createdAt: n.subtract(const Duration(days: 10)), updatedAt: n),
      WorkOrder(id: 4, vehicleId: 3, type: 'repair', status: 'open', description: 'إصلاح مشكلة في المكيف', technicianName: 'ياسر كهربائي', technicianPhone: '01177788899', estimatedCost: 1200, priority: 'high', createdAt: n.subtract(const Duration(hours: 6)), updatedAt: n),
      WorkOrder(id: 5, vehicleId: 6, type: 'maintenance', status: 'completed', description: 'صيانة الدفع الرباعي + تغيير الإطارات', technicianName: 'سعيد فني', technicianPhone: '01066677788', estimatedCost: 3000, actualCost: 2800, priority: 'medium', startDate: n.subtract(const Duration(days: 14)), completedDate: n.subtract(const Duration(days: 10)), createdAt: n.subtract(const Duration(days: 16)), updatedAt: n),
      WorkOrder(id: 6, vehicleId: 10, type: 'inspection', status: 'in_progress', description: 'فحص قبل الرحلة الطويلة', technicianName: 'عبدالله فاحص', technicianPhone: '01555566677', estimatedCost: 200, priority: 'medium', startDate: n.subtract(const Duration(days: 1)), createdAt: n.subtract(const Duration(days: 2)), updatedAt: n),
    ];
  }

  static List<TripTracking> _seedTrips() {
    final n = DateTime.now();
    return [
      TripTracking(id: 1, vehicleId: 1, status: 'completed', startLat: 30.0444, startLng: 31.2357, endLat: 30.0846, endLng: 31.2436, startAddress: 'القاهرة - المعادي', endAddress: 'القاهرة - مدينة نصر', distanceKm: 12.5, durationMinutes: 35, startOdometer: 44800, endOdometer: 44813, driverName: 'أحمد محمود', notes: 'رحلة صباحية للمكتب', createdAt: n.subtract(const Duration(days: 2)), updatedAt: n.subtract(const Duration(days: 2))),
      TripTracking(id: 2, vehicleId: 2, status: 'completed', startLat: 30.0561, startLng: 31.2243, endLat: 29.9858, endLng: 31.2812, startAddress: 'الجيزة - الدقي', endAddress: 'القاهرة - المعادي', distanceKm: 18.3, durationMinutes: 45, startOdometer: 61700, endOdometer: 61718, driverName: 'محمد علي', createdAt: n.subtract(const Duration(days: 1)), updatedAt: n.subtract(const Duration(days: 1))),
      TripTracking(id: 3, vehicleId: 6, status: 'completed', startLat: 30.0444, startLng: 31.2357, endLat: 30.1219, endLng: 31.4056, startAddress: 'القاهرة - وسط البلد', endAddress: 'القاهرة - التجمع الخامس', distanceKm: 35.7, durationMinutes: 55, startOdometer: 119500, endOdometer: 119536, driverName: 'ياسر أحمد', notes: 'توصيل بضائع', createdAt: n.subtract(const Duration(hours: 8)), updatedAt: n.subtract(const Duration(hours: 7))),
      TripTracking(id: 4, vehicleId: 3, status: 'active', startLat: 30.0846, startLng: 31.2436, startAddress: 'القاهرة - مدينة نصر', distanceKm: 5.2, durationMinutes: 12, startOdometer: 88200, driverName: 'حسن إبراهيم', createdAt: n.subtract(const Duration(minutes: 12)), updatedAt: n),
    ];
  }

  static List<AppUser> _seedUsers() {
    final n = DateTime.now();
    return [
      AppUser(id: 1, email: 'admin@kmsfleet.com', displayName: 'مدير النظام', role: 'admin', phone: '01000000000', isActive: true, createdAt: n, updatedAt: n),
      AppUser(id: 2, email: 'supervisor@kmsfleet.com', displayName: 'المشرف أحمد', role: 'supervisor', phone: '01100000000', isActive: true, createdAt: n, updatedAt: n),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SUPABASE HELPERS — convert between Supabase rows and model maps
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert a model's toMap() output to a Supabase-compatible row (adds user_id).
  static Map<String, dynamic> _toSupabaseRow(Map<String, dynamic> map) {
    final row = Map<String, dynamic>.from(map);
    row['user_id'] = _uid;
    // Don't send null id for inserts — let Postgres auto-generate BIGSERIAL
    if (row['id'] == null) row.remove('id');
    return row;
  }

  /// Convert a Supabase row back to a model-compatible map.
  /// Handles JSONB columns and boolean↔int conversions.
  static Map<String, dynamic> _fromSupabaseRow(Map<String, dynamic> row) {
    // Checklist items: JSONB → JSON string
    final rawItems = row['items'];
    if (rawItems is List) {
      row['items'] = jsonEncode(rawItems);
    } else if (rawItems == null) {
      row['items'] = '[]';
    }
    // Trip points: JSONB → JSON string
    final rawPoints = row['trip_points_json'];
    if (rawPoints is List) {
      row['trip_points_json'] = jsonEncode(rawPoints);
    } else if (rawPoints == null) {
      row['trip_points_json'] = null;
    }
    // Fuel booleans
    if (row['full_tank'] is bool) {
      row['full_tank'] = (row['full_tank'] as bool) ? 1 : 0;
    }
    if (row['is_abnormal'] is bool) {
      row['is_abnormal'] = (row['is_abnormal'] as bool) ? 1 : 0;
    }
    // AppUser booleans
    if (row['is_active'] is bool) {
      row['is_active'] = (row['is_active'] as bool) ? 1 : 0;
    }
    return row;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  VEHICLE CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<Vehicle>> getAllVehicles() async {
    if (_offline) return List.from(_memVehicles);
    try {
      final response = await _db.from('vehicles').select().eq('user_id', _uid!).order('created_at', ascending: false);
      return response.map((r) => Vehicle.fromMap(_fromSupabaseRow(r))).toList();
    } catch (e) {
      debugPrint('DB: Error fetching vehicles: $e');
      return List.from(_memVehicles);
    }
  }

  static Future<Vehicle?> getVehicleById(int id) async {
    if (_offline) {
      for (final v in _memVehicles) { if (v.id == id) return v; }
      return null;
    }
    try {
      final response = await _db.from('vehicles').select().eq('id', id).eq('user_id', _uid!).maybeSingle();
      if (response == null) return null;
      return Vehicle.fromMap(_fromSupabaseRow(response));
    } catch (e) { return null; }
  }

  static Future<List<Vehicle>> searchVehicles(String query) async {
    final all = await getAllVehicles();
    final q = query.toLowerCase();
    return all.where((v) =>
        v.plateNumber.toLowerCase().contains(q) ||
        v.make.toLowerCase().contains(q) ||
        v.model.toLowerCase().contains(q) ||
        (v.driverName != null && v.driverName!.toLowerCase().contains(q))).toList();
  }

  static Future<int> insertVehicle(Vehicle v) async {
    if (_offline) {
      final maxId = _memVehicles.isEmpty ? 0 : _memVehicles.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memVehicles.insert(0, v.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      final row = _toSupabaseRow(v.toMap());
      final response = await _db.from('vehicles').insert(row).select('id').single();
      return (response['id'] as int?) ?? -1;
    } catch (e) { debugPrint('DB: Error inserting vehicle: $e'); return -1; }
  }

  static Future<int> updateVehicle(Vehicle v) async {
    if (_offline) {
      for (int i = 0; i < _memVehicles.length; i++) {
        if (_memVehicles[i].id == v.id) { _memVehicles[i] = v; return 1; }
      }
      return 0;
    }
    try {
      await _db.from('vehicles').update(v.toMap()).eq('id', v.id!).eq('user_id', _uid!);
      return 1;
    } catch (e) { debugPrint('DB: Error updating vehicle: $e'); return 0; }
  }

  static Future<int> deleteVehicle(int id) async {
    if (_offline) {
      _memVehicles.removeWhere((v) => v.id == id);
      return 1;
    }
    try {
      await _db.from('vehicles').delete().eq('id', id).eq('user_id', _uid!);
      return 1;
    } catch (e) { debugPrint('DB: Error deleting vehicle: $e'); return 0; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  MAINTENANCE CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<MaintenanceRecord>> getAllMaintenanceRecords() async {
    final vehicles = await getAllVehicles();
    if (_offline) {
      return _memRecords.map((r) {
        for (final v in vehicles) { if (v.id == r.vehicleId) return r.copyWith(vehicle: v); }
        return r;
      }).toList();
    }
    try {
      final response = await _db.from('maintenance_records').select().eq('user_id', _uid!).order('maintenance_date', ascending: false);
      return _joinVehicles(response.map((m) => MaintenanceRecord.fromMap(_fromSupabaseRow(m))).toList(), vehicles);
    } catch (e) {
      debugPrint('DB: Error fetching maintenance: $e');
      return List.from(_memRecords);
    }
  }

  static Future<List<MaintenanceRecord>> getMaintenanceByVehicleId(int vid) async {
    final v = await getVehicleById(vid);
    if (_offline) {
      return _memRecords.where((r) => r.vehicleId == vid).map((r) => r.copyWith(vehicle: v)).toList();
    }
    try {
      final response = await _db.from('maintenance_records').select().eq('user_id', _uid!).eq('vehicle_id', vid).order('maintenance_date', ascending: false);
      return response.map((m) => MaintenanceRecord.fromMap(_fromSupabaseRow(m)).copyWith(vehicle: v)).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertMaintenanceRecord(MaintenanceRecord r) async {
    if (_offline) {
      final maxId = _memRecords.isEmpty ? 0 : _memRecords.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memRecords.insert(0, r.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      final row = _toSupabaseRow(r.toMap());
      final response = await _db.from('maintenance_records').insert(row).select('id').single();
      return (response['id'] as int?) ?? -1;
    } catch (e) { debugPrint('DB: Error inserting maintenance: $e'); return -1; }
  }

  static Future<int> updateMaintenanceRecord(MaintenanceRecord r) async {
    if (_offline) {
      for (int i = 0; i < _memRecords.length; i++) {
        if (_memRecords[i].id == r.id) { _memRecords[i] = r; return 1; }
      }
      return 0;
    }
    try {
      await _db.from('maintenance_records').update(r.toMap()).eq('id', r.id!).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  static Future<int> deleteMaintenanceRecord(int id) async {
    if (_offline) { _memRecords.removeWhere((r) => r.id == id); return 1; }
    try {
      await _db.from('maintenance_records').delete().eq('id', id).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CHECKLIST CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<Checklist>> getAllChecklists() async {
    final vehicles = await getAllVehicles();
    if (_offline) {
      return _memChecklists.map((c) {
        for (final v in vehicles) { if (v.id == c.vehicleId) return c.copyWith(vehicle: v); }
        return c;
      }).toList();
    }
    try {
      final response = await _db.from('checklists').select().eq('user_id', _uid!).order('inspection_date', ascending: false);
      return _joinVehiclesChecklists(response.map((m) => Checklist.fromMap(_fromSupabaseRow(m))).toList(), vehicles);
    } catch (e) {
      debugPrint('DB: Error fetching checklists: $e');
      return List.from(_memChecklists);
    }
  }

  static Future<Checklist?> getChecklistById(int id) async {
    final vehicles = await getAllVehicles();
    if (_offline) {
      for (final c in _memChecklists) {
        if (c.id == id) {
          for (final v in vehicles) { if (v.id == c.vehicleId) return c.copyWith(vehicle: v); }
          return c;
        }
      }
      return null;
    }
    try {
      final response = await _db.from('checklists').select().eq('id', id).eq('user_id', _uid!).maybeSingle();
      if (response == null) return null;
      final vid = (response['vehicle_id'] as int?) ?? 0;
      Vehicle? veh;
      for (final v in vehicles) { if (v.id == vid) { veh = v; break; } }
      return Checklist.fromMap(_fromSupabaseRow(response)).copyWith(vehicle: veh);
    } catch (e) { return null; }
  }

  static Future<List<Checklist>> getChecklistsByVehicleId(int vid) async {
    final v = await getVehicleById(vid);
    if (_offline) {
      return _memChecklists.where((c) => c.vehicleId == vid).map((c) => c.copyWith(vehicle: v)).toList();
    }
    try {
      final response = await _db.from('checklists').select().eq('user_id', _uid!).eq('vehicle_id', vid).order('inspection_date', ascending: false);
      return response.map((m) => Checklist.fromMap(_fromSupabaseRow(m)).copyWith(vehicle: v)).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertChecklist(Checklist c) async {
    if (_offline) {
      final maxId = _memChecklists.isEmpty ? 0 : _memChecklists.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memChecklists.insert(0, c.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      final map = _toSupabaseRow(c.toMap());
      // Convert JSON string items to List for JSONB column
      final rawItems = map['items'];
      if (rawItems is String && rawItems.isNotEmpty) {
        try { map['items'] = jsonDecode(rawItems); } catch (_) {}
      }
      final response = await _db.from('checklists').insert(map).select('id').single();
      return (response['id'] as int?) ?? -1;
    } catch (e) { debugPrint('DB: Error inserting checklist: $e'); return -1; }
  }

  static Future<int> updateChecklist(Checklist c) async {
    if (_offline) {
      for (int i = 0; i < _memChecklists.length; i++) {
        if (_memChecklists[i].id == c.id) { _memChecklists[i] = c; return 1; }
      }
      return 0;
    }
    try {
      final map = c.toMap();
      final rawItems = map['items'];
      if (rawItems is String && rawItems.isNotEmpty) {
        try { map['items'] = jsonDecode(rawItems); } catch (_) {}
      }
      await _db.from('checklists').update(map).eq('id', c.id!).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  static Future<int> deleteChecklist(int id) async {
    if (_offline) { _memChecklists.removeWhere((c) => c.id == id); return 1; }
    try {
      await _db.from('checklists').delete().eq('id', id).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FUEL RECORD CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<FuelRecord>> getAllFuelRecords() async {
    final vehicles = await getAllVehicles();
    if (_offline) {
      return _memFuelRecords.map((f) {
        for (final v in vehicles) { if (v.id == f.vehicleId) return f.copyWith(vehicle: v); }
        return f;
      }).toList();
    }
    try {
      final response = await _db.from('fuel_records').select().eq('user_id', _uid!).order('fill_date', ascending: false);
      return _joinVehiclesFuel(response.map((m) => FuelRecord.fromMap(_fromSupabaseRow(m))).toList(), vehicles);
    } catch (e) {
      debugPrint('DB: Error fetching fuel: $e');
      return List.from(_memFuelRecords);
    }
  }

  static Future<FuelRecord?> getFuelRecordById(int id) async {
    final vehicles = await getAllVehicles();
    if (_offline) {
      for (final f in _memFuelRecords) {
        if (f.id == id) {
          for (final v in vehicles) { if (v.id == f.vehicleId) return f.copyWith(vehicle: v); }
          return f;
        }
      }
      return null;
    }
    try {
      final response = await _db.from('fuel_records').select().eq('id', id).eq('user_id', _uid!).maybeSingle();
      if (response == null) return null;
      final vid = (response['vehicle_id'] as int?) ?? 0;
      Vehicle? veh;
      for (final v in vehicles) { if (v.id == vid) { veh = v; break; } }
      return FuelRecord.fromMap(_fromSupabaseRow(response)).copyWith(vehicle: veh);
    } catch (e) { return null; }
  }

  static Future<List<FuelRecord>> getFuelRecordsByVehicleId(int vid) async {
    final v = await getVehicleById(vid);
    if (_offline) {
      return _memFuelRecords.where((f) => f.vehicleId == vid).map((f) => f.copyWith(vehicle: v)).toList();
    }
    try {
      final response = await _db.from('fuel_records').select().eq('user_id', _uid!).eq('vehicle_id', vid).order('fill_date', ascending: false);
      return response.map((m) => FuelRecord.fromMap(_fromSupabaseRow(m)).copyWith(vehicle: v)).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertFuelRecord(FuelRecord f) async {
    if (_offline) {
      final maxId = _memFuelRecords.isEmpty ? 0 : _memFuelRecords.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      final record = f.copyWith(id: maxId + 1);
      _memFuelRecords.insert(0, record);
      _calculateAndUpdateConsumptionRate(record, _memFuelRecords);
      return maxId + 1;
    }
    try {
      final map = _toSupabaseRow(f.toMap());
      // Convert int booleans to real booleans for Supabase
      if (map['full_tank'] is int) map['full_tank'] = (map['full_tank'] as int) != 0;
      if (map['is_abnormal'] is int) map['is_abnormal'] = (map['is_abnormal'] as int) != 0;
      final response = await _db.from('fuel_records').insert(map).select('id').single();
      return (response['id'] as int?) ?? -1;
    } catch (e) { debugPrint('DB: Error inserting fuel: $e'); return -1; }
  }

  static Future<int> updateFuelRecord(FuelRecord f) async {
    if (_offline) {
      for (int i = 0; i < _memFuelRecords.length; i++) {
        if (_memFuelRecords[i].id == f.id) { _memFuelRecords[i] = f; return 1; }
      }
      return 0;
    }
    try {
      final map = f.toMap();
      if (map['full_tank'] is int) map['full_tank'] = (map['full_tank'] as int) != 0;
      if (map['is_abnormal'] is int) map['is_abnormal'] = (map['is_abnormal'] as int) != 0;
      await _db.from('fuel_records').update(map).eq('id', f.id!).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  static Future<int> deleteFuelRecord(int id) async {
    if (_offline) { _memFuelRecords.removeWhere((f) => f.id == id); return 1; }
    try {
      await _db.from('fuel_records').delete().eq('id', id).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  // ── Fuel Consumption Rate Calculation ──

  static const double _abnormalThreshold = 0.20;

  static void _calculateAndUpdateConsumptionRate(FuelRecord newRecord, List<FuelRecord> allRecords) {
    final vehicleRecords = allRecords.where((r) => r.vehicleId == newRecord.vehicleId).toList()
      ..sort((a, b) => a.odometerReading.compareTo(b.odometerReading));
    _applyConsumptionRates(vehicleRecords);
  }

  static void _applyConsumptionRates(List<FuelRecord> records) {
    if (records.isEmpty) return;
    final List<double> rates = [];
    for (int i = 1; i < records.length; i++) {
      final prev = records[i - 1];
      final curr = records[i];
      if (prev.fullTank && curr.fullTank && curr.liters > 0) {
        final distance = curr.odometerReading - prev.odometerReading;
        if (distance > 0) {
          final rate = distance / curr.liters;
          rates.add(rate);
          records[i] = curr.copyWith(consumptionRate: rate);
        }
      }
    }
    if (rates.length >= 2) {
      double sum = 0;
      for (final r in rates) { sum += r; }
      final avg = sum / rates.length;
      for (int i = 0; i < records.length; i++) {
        final r = records[i];
        if (r.consumptionRate != null && r.consumptionRate! > 0) {
          final isAbnormal = (avg - r.consumptionRate!) / r.consumptionRate! > _abnormalThreshold;
          records[i] = r.copyWith(isAbnormal: isAbnormal);
        }
      }
    }
  }

  static Future<Map<int, Map<String, dynamic>>> getFuelConsumptionStats() async {
    final records = await getAllFuelRecords();
    final Map<int, List<FuelRecord>> byVehicle = {};
    for (final r in records) { byVehicle.putIfAbsent(r.vehicleId, () => []).add(r); }
    final Map<int, Map<String, dynamic>> stats = {};
    byVehicle.forEach((vid, recs) {
      recs.sort((a, b) => a.odometerReading.compareTo(b.odometerReading));
      final List<double> consumptionRates = [];
      double totalLiters = 0, totalCost = 0;
      int abnormalCount = 0;
      for (final r in recs) { totalLiters += r.liters; totalCost += r.totalCost; }
      for (int i = 1; i < recs.length; i++) {
        final prev = recs[i - 1], curr = recs[i];
        if (prev.fullTank && curr.fullTank && curr.liters > 0) {
          final distance = curr.odometerReading - prev.odometerReading;
          if (distance > 0) consumptionRates.add(distance / curr.liters);
        }
      }
      double avgRate = 0;
      if (consumptionRates.isNotEmpty) {
        double sum = 0; for (final r in consumptionRates) { sum += r; }
        avgRate = sum / consumptionRates.length;
        for (final r in consumptionRates) {
          if (r > 0 && (avgRate - r) / r > 0.20) abnormalCount++;
        }
      }
      stats[vid] = {
        'vehicleId': vid, 'totalFillUps': recs.length, 'totalLiters': totalLiters,
        'totalCost': totalCost, 'avgConsumptionRate': avgRate, 'consumptionRates': consumptionRates,
        'abnormalCount': abnormalCount, 'fullTankFillUps': recs.where((r) => r.fullTank).length,
      };
    });
    return stats;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DRIVER VIOLATION CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<DriverViolation>> getAllViolations() async {
    final vehicles = await getAllVehicles();
    if (_offline) {
      return _memViolations.map((v) {
        Vehicle? veh; for (final vv in vehicles) { if (vv.id == v.vehicleId) { veh = vv; break; } }
        return v.copyWith(vehicle: veh);
      }).toList();
    }
    try {
      final response = await _db.from('driver_violations').select().eq('user_id', _uid!).order('date', ascending: false);
      return _joinVehiclesViolations(response.map((m) => DriverViolation.fromMap(_fromSupabaseRow(m))).toList(), vehicles);
    } catch (e) {
      debugPrint('DB: Error fetching violations: $e');
      return List.from(_memViolations);
    }
  }

  static Future<List<DriverViolation>> getViolationsByVehicleId(int vehicleId) async {
    final vehicles = await getAllVehicles();
    Vehicle? veh; for (final v in vehicles) { if (v.id == vehicleId) { veh = v; break; } }
    if (_offline) {
      return _memViolations.where((v) => v.vehicleId == vehicleId).map((v) => v.copyWith(vehicle: veh)).toList();
    }
    try {
      final response = await _db.from('driver_violations').select().eq('user_id', _uid!).eq('vehicle_id', vehicleId).order('date', ascending: false);
      return response.map((m) => DriverViolation.fromMap(_fromSupabaseRow(m)).copyWith(vehicle: veh)).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertViolation(DriverViolation v) async {
    if (_offline) {
      final maxId = _memViolations.isEmpty ? 0 : _memViolations.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memViolations.insert(0, v.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      final row = _toSupabaseRow(v.toMap());
      final response = await _db.from('driver_violations').insert(row).select('id').single();
      return (response['id'] as int?) ?? -1;
    } catch (e) { debugPrint('DB: Error inserting violation: $e'); return -1; }
  }

  static Future<int> updateViolation(DriverViolation v) async {
    if (_offline) {
      for (int i = 0; i < _memViolations.length; i++) {
        if (_memViolations[i].id == v.id) { _memViolations[i] = v; return 1; }
      }
      return 0;
    }
    try {
      await _db.from('driver_violations').update(v.toMap()).eq('id', v.id!).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  static Future<int> deleteViolation(int id) async {
    if (_offline) { _memViolations.removeWhere((v) => v.id == id); return 1; }
    try {
      await _db.from('driver_violations').delete().eq('id', id).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EXPENSE CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<Expense>> getAllExpenses() async {
    final vehicles = await getAllVehicles();
    if (_offline) {
      return _memExpenses.map((e) {
        Vehicle? veh; for (final v in vehicles) { if (v.id == e.vehicleId) { veh = v; break; } }
        return e.copyWith(vehicle: veh);
      }).toList();
    }
    try {
      final response = await _db.from('expenses').select().eq('user_id', _uid!).order('date', ascending: false);
      return _joinVehiclesExpenses(response.map((m) => Expense.fromMap(_fromSupabaseRow(m))).toList(), vehicles);
    } catch (e) {
      debugPrint('DB: Error fetching expenses: $e');
      return List.from(_memExpenses);
    }
  }

  static Future<List<Expense>> getExpensesByVehicleId(int vehicleId) async {
    final vehicles = await getAllVehicles();
    Vehicle? veh; for (final v in vehicles) { if (v.id == vehicleId) { veh = v; break; } }
    if (_offline) {
      return _memExpenses.where((e) => e.vehicleId == vehicleId).map((e) => e.copyWith(vehicle: veh)).toList();
    }
    try {
      final response = await _db.from('expenses').select().eq('user_id', _uid!).eq('vehicle_id', vehicleId).order('date', ascending: false);
      return response.map((m) => Expense.fromMap(_fromSupabaseRow(m)).copyWith(vehicle: veh)).toList();
    } catch (e) { return []; }
  }

  static Future<List<Expense>> getExpensesByType(String type) async {
    final all = await getAllExpenses();
    return all.where((e) => e.type == type).toList();
  }

  static Future<int> insertExpense(Expense e) async {
    if (_offline) {
      final maxId = _memExpenses.isEmpty ? 0 : _memExpenses.map((x) => x.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memExpenses.insert(0, e.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      final row = _toSupabaseRow(e.toMap());
      final response = await _db.from('expenses').insert(row).select('id').single();
      return (response['id'] as int?) ?? -1;
    } catch (ex) { debugPrint('DB: Error inserting expense: $ex'); return -1; }
  }

  static Future<int> updateExpense(Expense e) async {
    if (_offline) {
      for (int i = 0; i < _memExpenses.length; i++) {
        if (_memExpenses[i].id == e.id) { _memExpenses[i] = e; return 1; }
      }
      return 0;
    }
    try {
      await _db.from('expenses').update(e.toMap()).eq('id', e.id!).eq('user_id', _uid!);
      return 1;
    } catch (ex) { return 0; }
  }

  static Future<int> deleteExpense(int id) async {
    if (_offline) { _memExpenses.removeWhere((e) => e.id == id); return 1; }
    try {
      await _db.from('expenses').delete().eq('id', id).eq('user_id', _uid!);
      return 1;
    } catch (ex) { return 0; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  WORK ORDER CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<WorkOrder>> getAllWorkOrders() async {
    final vehicles = await getAllVehicles();
    if (_offline) {
      return _memWorkOrders.map((o) {
        Vehicle? veh; for (final v in vehicles) { if (v.id == o.vehicleId) { veh = v; break; } }
        return o.copyWith(vehicle: veh);
      }).toList();
    }
    try {
      final response = await _db.from('work_orders').select().eq('user_id', _uid!).order('created_at', ascending: false);
      return _joinVehiclesWorkOrders(response.map((m) => WorkOrder.fromMap(_fromSupabaseRow(m))).toList(), vehicles);
    } catch (e) {
      debugPrint('DB: Error fetching work orders: $e');
      return List.from(_memWorkOrders);
    }
  }

  static Future<List<WorkOrder>> getWorkOrdersByVehicleId(int vid) async {
    final v = await getVehicleById(vid);
    if (_offline) {
      return _memWorkOrders.where((o) => o.vehicleId == vid).map((o) => o.copyWith(vehicle: v)).toList();
    }
    try {
      final response = await _db.from('work_orders').select().eq('user_id', _uid!).eq('vehicle_id', vid).order('created_at', ascending: false);
      return response.map((m) => WorkOrder.fromMap(_fromSupabaseRow(m)).copyWith(vehicle: v)).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertWorkOrder(WorkOrder o) async {
    if (_offline) {
      final maxId = _memWorkOrders.isEmpty ? 0 : _memWorkOrders.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memWorkOrders.insert(0, o.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      final row = _toSupabaseRow(o.toMap());
      final response = await _db.from('work_orders').insert(row).select('id').single();
      return (response['id'] as int?) ?? -1;
    } catch (e) { debugPrint('DB: Error inserting work order: $e'); return -1; }
  }

  static Future<int> updateWorkOrder(WorkOrder o) async {
    if (_offline) {
      for (int i = 0; i < _memWorkOrders.length; i++) {
        if (_memWorkOrders[i].id == o.id) { _memWorkOrders[i] = o; return 1; }
      }
      return 0;
    }
    try {
      await _db.from('work_orders').update(o.toMap()).eq('id', o.id!).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  static Future<int> deleteWorkOrder(int id) async {
    if (_offline) { _memWorkOrders.removeWhere((o) => o.id == id); return 1; }
    try {
      await _db.from('work_orders').delete().eq('id', id).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TRIP TRACKING CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<TripTracking>> getAllTrips() async {
    if (_offline) return List.from(_memTrips);
    try {
      final response = await _db.from('trip_trackings').select().eq('user_id', _uid!).order('created_at', ascending: false);
      return response.map((m) => TripTracking.fromMap(_fromSupabaseRow(m))).toList();
    } catch (e) {
      debugPrint('DB: Error fetching trips: $e');
      return List.from(_memTrips);
    }
  }

  static Future<List<TripTracking>> getTripsByVehicleId(int vid) async {
    if (_offline) return _memTrips.where((t) => t.vehicleId == vid).toList();
    try {
      final response = await _db.from('trip_trackings').select().eq('user_id', _uid!).eq('vehicle_id', vid).order('created_at', ascending: false);
      return response.map((m) => TripTracking.fromMap(_fromSupabaseRow(m))).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertTrip(TripTracking t) async {
    if (_offline) {
      final maxId = _memTrips.isEmpty ? 0 : _memTrips.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memTrips.insert(0, t.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      final map = _toSupabaseRow(t.toMap());
      // Convert JSON string trip_points to List for JSONB column
      final rawPoints = map['trip_points_json'];
      if (rawPoints is String && rawPoints.isNotEmpty) {
        try { map['trip_points_json'] = jsonDecode(rawPoints); } catch (_) {}
      }
      final response = await _db.from('trip_trackings').insert(map).select('id').single();
      return (response['id'] as int?) ?? -1;
    } catch (e) { debugPrint('DB: Error inserting trip: $e'); return -1; }
  }

  static Future<int> updateTrip(TripTracking t) async {
    if (_offline) {
      for (int i = 0; i < _memTrips.length; i++) {
        if (_memTrips[i].id == t.id) { _memTrips[i] = t; return 1; }
      }
      return 0;
    }
    try {
      final map = t.toMap();
      final rawPoints = map['trip_points_json'];
      if (rawPoints is String && rawPoints.isNotEmpty) {
        try { map['trip_points_json'] = jsonDecode(rawPoints); } catch (_) {}
      }
      await _db.from('trip_trackings').update(map).eq('id', t.id!).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  static Future<int> deleteTrip(int id) async {
    if (_offline) { _memTrips.removeWhere((t) => t.id == id); return 1; }
    try {
      await _db.from('trip_trackings').delete().eq('id', id).eq('user_id', _uid!);
      return 1;
    } catch (e) { return 0; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  APP USER CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<AppUser>> getAllUsers() async {
    if (_offline) return List.from(_memUsers);
    try {
      final response = await _db.from('app_users').select().order('created_at', ascending: false);
      return response.map((r) => AppUser.fromMap(_fromSupabaseRow(r))).toList();
    } catch (e) {
      debugPrint('DB: Error fetching users: $e');
      return List.from(_memUsers);
    }
  }

  static Future<AppUser?> getCurrentUserProfile() async {
    if (_offline) return _memUsers.isNotEmpty ? _memUsers.first : null;
    try {
      final response = await _db.from('app_users').select().eq('auth_user_id', _uid!).maybeSingle();
      if (response == null) return null;
      return AppUser.fromMap(_fromSupabaseRow(response));
    } catch (e) { return null; }
  }

  static Future<int> insertUser(AppUser u) async {
    if (_offline) {
      final maxId = _memUsers.isEmpty ? 0 : _memUsers.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memUsers.insert(0, u.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      final map = _toSupabaseRow(u.toMap());
      if (map['is_active'] is int) map['is_active'] = (map['is_active'] as int) != 0;
      final response = await _db.from('app_users').insert(map).select('id').single();
      return (response['id'] as int?) ?? -1;
    } catch (e) { debugPrint('DB: Error inserting user: $e'); return -1; }
  }

  static Future<int> updateUser(AppUser u) async {
    if (_offline) {
      for (int i = 0; i < _memUsers.length; i++) {
        if (_memUsers[i].id == u.id) { _memUsers[i] = u; return 1; }
      }
      return 0;
    }
    try {
      final map = u.toMap();
      if (map['is_active'] is int) map['is_active'] = (map['is_active'] as int) != 0;
      await _db.from('app_users').update(map).eq('id', u.id!);
      return 1;
    } catch (e) { return 0; }
  }

  static Future<int> deleteUser(int id) async {
    if (_offline) { _memUsers.removeWhere((u) => u.id == id); return 1; }
    try {
      await _db.from('app_users').delete().eq('id', id);
      return 1;
    } catch (e) { return 0; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final vehicles = await getAllVehicles();
    final records = await getAllMaintenanceRecords();
    final workOrders = await getAllWorkOrders();

    final activeCount = vehicles.where((v) => v.status == 'active').length;
    final maintenanceCount = vehicles.where((v) => v.status == 'maintenance').length;
    final inactiveCount = vehicles.where((v) => v.status == 'inactive').length;
    final pendingMaint = records.where((r) => r.status == 'pending').length;
    final inProgressMaint = records.where((r) => r.status == 'in_progress').length;
    final urgentMaint = records.where((r) => r.priority == 'urgent' && r.status != 'completed').length;
    final openWO = workOrders.where((o) => o.status == 'open').length;
    final inProgressWO = workOrders.where((o) => o.status == 'in_progress').length;
    final totalMaintCost = records.fold<double>(0, (sum, r) => sum + r.totalCost);

    return {
      'totalVehicles': vehicles.length,
      'activeVehicles': activeCount,
      'maintenanceVehicles': maintenanceCount,
      'inactiveVehicles': inactiveCount,
      'totalMaintenance': records.length,
      'pendingMaintenance': pendingMaint,
      'inProgressMaintenance': inProgressMaint,
      'urgentMaintenance': urgentMaint,
      'totalWorkOrders': workOrders.length,
      'openWorkOrders': openWO,
      'inProgressWorkOrders': inProgressWO,
      'totalMaintenanceCost': totalMaintCost,
    };
  }

  static Future<Map<String, double>> getExpenseStats() async {
    final expenses = await getAllExpenses();
    final stats = <String, double>{
      'fuel': 0, 'maintenance': 0, 'toll': 0, 'violation': 0, 'insurance': 0, 'miscellaneous': 0,
    };
    for (final e in expenses) {
      stats[e.type] = (stats[e.type] ?? 0) + e.amount;
    }
    return stats;
  }

  static Future<List<Map<String, dynamic>>> getMonthlyCosts() async {
    final records = await getAllMaintenanceRecords();
    final expenses = await getAllExpenses();
    final costs = <String, double>{};

    void addCost(DateTime date, double amount) {
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      costs[key] = (costs[key] ?? 0) + amount;
    }

    for (final r in records) { addCost(r.maintenanceDate, r.totalCost); }
    for (final e in expenses) { addCost(e.date, e.amount); }

    // Convert to sorted list of maps for FutureBuilder compatibility
    final sortedKeys = costs.keys.toList()..sort();
    return sortedKeys.map((key) => {
      'month': key,
      'total_cost': costs[key],
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getMaintenanceByType() async {
    final records = await getAllMaintenanceRecords();
    final stats = <String, double>{};
    for (final r in records) {
      stats[r.type] = (stats[r.type] ?? 0) + r.totalCost;
    }
    return stats.entries.map((entry) => {
      'type': entry.key,
      'total_cost': entry.value,
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getVehicleMaintenanceCosts() async {
    final records = await getAllMaintenanceRecords();
    final vehicles = await getAllVehicles();
    final Map<int, double> costs = {};

    for (final r in records) {
      costs[r.vehicleId] = (costs[r.vehicleId] ?? 0) + r.totalCost;
    }

    final sorted = costs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).map((entry) {
      final v = vehicles.firstWhere(
        (veh) => veh.id == entry.key,
        orElse: () => Vehicle(id: entry.key, plateNumber: '???', make: '', model: '', year: 2024, color: '', fuelType: '', currentOdometer: 0, status: 'active'),
      );
      return {
        'vehicle': v,
        'totalCost': entry.value,
        'recordCount': records.where((r) => r.vehicleId == entry.key).length,
      };
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  VEHICLE JOIN HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static List<MaintenanceRecord> _joinVehicles(List<MaintenanceRecord> records, List<Vehicle> vehicles) {
    return records.map((r) {
      Vehicle? veh; for (final v in vehicles) { if (v.id == r.vehicleId) { veh = v; break; } }
      return r.copyWith(vehicle: veh);
    }).toList();
  }

  static List<Checklist> _joinVehiclesChecklists(List<Checklist> records, List<Vehicle> vehicles) {
    return records.map((c) {
      Vehicle? veh; for (final v in vehicles) { if (v.id == c.vehicleId) { veh = v; break; } }
      return c.copyWith(vehicle: veh);
    }).toList();
  }

  static List<FuelRecord> _joinVehiclesFuel(List<FuelRecord> records, List<Vehicle> vehicles) {
    return records.map((f) {
      Vehicle? veh; for (final v in vehicles) { if (v.id == f.vehicleId) { veh = v; break; } }
      return f.copyWith(vehicle: veh);
    }).toList();
  }

  static List<DriverViolation> _joinVehiclesViolations(List<DriverViolation> records, List<Vehicle> vehicles) {
    return records.map((v) {
      Vehicle? veh; for (final vv in vehicles) { if (vv.id == v.vehicleId) { veh = vv; break; } }
      return v.copyWith(vehicle: veh);
    }).toList();
  }

  static List<Expense> _joinVehiclesExpenses(List<Expense> records, List<Vehicle> vehicles) {
    return records.map((e) {
      Vehicle? veh; for (final v in vehicles) { if (v.id == e.vehicleId) { veh = v; break; } }
      return e.copyWith(vehicle: veh);
    }).toList();
  }

  static List<WorkOrder> _joinVehiclesWorkOrders(List<WorkOrder> records, List<Vehicle> vehicles) {
    return records.map((o) {
      Vehicle? veh; for (final v in vehicles) { if (v.id == o.vehicleId) { veh = v; break; } }
      return o.copyWith(vehicle: veh);
    }).toList();
  }
}
