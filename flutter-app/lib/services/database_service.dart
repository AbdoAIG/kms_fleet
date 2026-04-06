import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/checklist.dart';
import '../models/fuel_record.dart';
import '../models/driver_violation.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

// Conditional import: use native sqflite on Android/iOS, stub on web/desktop.
// dart.library.io is TRUE on all native platforms (Android, iOS, Windows, macOS, Linux)
// and FALSE on web (both dart2js and dart2wasm).
import 'db_stub.dart' if (dart.library.io) 'db_native.dart';

class DatabaseService {
  static bool _useMemory = true;
  static List<Vehicle> _memVehicles = [];
  static List<MaintenanceRecord> _memRecords = [];
  static List<Checklist> _memChecklists = [];
  static List<FuelRecord> _memFuelRecords = [];
  static List<DriverViolation> _memViolations = [];
  static List<Expense> _memExpenses = [];
  static const _vt = 'vehicles';
  static const _mt = 'maintenance_records';
  static const _ct = 'checklists';
  static const _ft = 'fuel_records';
  static const _vt2 = 'driver_violations';
  static const _et = 'expenses';

  DatabaseService._();

  static Future<void> initialize() async {
    try {
      await initNativeDb();
      if (nativeDbAvailable) {
        _useMemory = false;
        return;
      }
    } catch (e) {
      debugPrint('DB init error, fallback to memory: $e');
    }
    _useMemory = true;
    _seedMemory();
  }

  static void _seedMemory() {
    _memVehicles = _seedVehicles();
    _memRecords = _seedRecords();
    _memChecklists = _seedChecklists();
    _memFuelRecords = _seedFuelRecords();
    _memViolations = _seedViolations();
    _memExpenses = _seedExpenses();
  }

  static List<Vehicle> _seedVehicles() {
    final n = DateTime.now();
    return [
      Vehicle(id: 1, plateNumber: 'أ ب ج 1234', make: 'تويوتا', model: 'كامري', year: 2023, color: 'white', fuelType: 'petrol', currentOdometer: 45000, status: 'active', driverName: 'أحمد محمود', createdAt: n, updatedAt: n),
      Vehicle(id: 2, plateNumber: 'د ه و 5678', make: 'هيونداي', model: 'توسان', year: 2022, color: 'black', fuelType: 'petrol', currentOdometer: 62000, status: 'active', driverName: 'محمد علي', createdAt: n, updatedAt: n),
      Vehicle(id: 3, plateNumber: 'ز ح ط 9012', make: 'نيسان', model: 'صني', year: 2021, color: 'silver', fuelType: 'petrol', currentOdometer: 89000, status: 'active', driverName: 'حسن إبراهيم', createdAt: n, updatedAt: n),
      Vehicle(id: 4, plateNumber: 'ي ك ل 3456', make: 'كيا', model: 'سبورتاج', year: 2023, color: 'blue', fuelType: 'diesel', currentOdometer: 28000, status: 'active', driverName: 'خالد سعيد', createdAt: n, updatedAt: n),
      Vehicle(id: 5, plateNumber: 'م ن س 7890', make: 'مرسيدس', model: 'C-Class', year: 2022, color: 'black', fuelType: 'petrol', currentOdometer: 35000, status: 'maintenance', driverName: 'عمر فاروق', createdAt: n, updatedAt: n),
      Vehicle(id: 6, plateNumber: 'ع ف ق 2345', make: 'تويوتا', model: 'هايلكس', year: 2020, color: 'white', fuelType: 'diesel', currentOdometer: 120000, status: 'active', driverName: 'ياسر أحمد', createdAt: n, updatedAt: n),
      Vehicle(id: 7, plateNumber: 'ر ش ت 6789', make: 'هيونداي', model: 'إلنترا', year: 2024, color: 'red', fuelType: 'petrol', currentOdometer: 8000, status: 'active', driverName: 'عبدالله حسن', createdAt: n, updatedAt: n),
      Vehicle(id: 8, plateNumber: 'ث خ ذ 0123', make: 'فورد', model: 'إكسبلورر', year: 2021, color: 'gray', fuelType: 'petrol', currentOdometer: 78000, status: 'inactive', driverName: 'محمود سالم', createdAt: n, updatedAt: n),
      Vehicle(id: 9, plateNumber: 'ض ظ غ 4567', make: 'شيفروليه', model: 'تاهو', year: 2023, color: 'black', fuelType: 'petrol', currentOdometer: 22000, status: 'active', driverName: 'طه عبدالرحمن', createdAt: n, updatedAt: n),
      Vehicle(id: 10, plateNumber: 'ج ث ب 8901', make: 'تويوتا', model: 'لاند كروزر', year: 2022, color: 'white', fuelType: 'diesel', currentOdometer: 55000, status: 'active', driverName: 'إبراهيم عثمان', createdAt: n, updatedAt: n),
      Vehicle(id: 11, plateNumber: 'ن ح ي 2468', make: 'بي إم دبليو', model: 'الفئة 5', year: 2021, color: 'blue', fuelType: 'petrol', currentOdometer: 92000, status: 'active', driverName: 'كريم حسام', createdAt: n, updatedAt: n),
      Vehicle(id: 12, plateNumber: 'و ك م 1357', make: 'أودي', model: 'Q7', year: 2023, color: 'gray', fuelType: 'diesel', currentOdometer: 18000, status: 'active', driverName: 'رامي شريف', createdAt: n, updatedAt: n),
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

  // ===== Violation seed =====
  static List<DriverViolation> _seedViolations() {
    final n = DateTime.now();
    return [
      DriverViolation(id: 1, vehicleId: 5, type: 'speeding', amount: 500, date: n.subtract(const Duration(days: 10)), description: 'سرعة زائدة على طريق القاهرة الإسكندرية', points: 2, status: 'paid', createdAt: n, updatedAt: n),
      DriverViolation(id: 2, vehicleId: 3, type: 'overweight', amount: 300, date: n.subtract(const Duration(days: 5)), description: 'حمل زائد على مركبة نقل', points: 1, status: 'pending', createdAt: n, updatedAt: n),
      DriverViolation(id: 3, vehicleId: 2, type: 'red_light', amount: 1000, date: n.subtract(const Duration(days: 2)), description: 'تجاوز إشارة مرورية حمراء', points: 3, status: 'pending', createdAt: n, updatedAt: n),
    ];
  }

  // ===== Expense seed =====
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

  // ===== Vehicle CRUD =====
  static Future<List<Vehicle>> getAllVehicles() async {
    if (_useMemory) return List.from(_memVehicles);
    try {
      final maps = await nativeQuery(_vt, orderBy: 'created_at DESC');
      return maps.map((m) => Vehicle.fromMap(m)).toList();
    } catch (e) {
      return List.from(_memVehicles);
    }
  }

  static Future<Vehicle?> getVehicleById(int id) async {
    if (_useMemory) {
      for (final v in _memVehicles) {
        if (v.id == id) return v;
      }
      return null;
    }
    try {
      final maps = await nativeQuery(_vt, where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return null;
      return Vehicle.fromMap(maps.first);
    } catch (e) {
      return null;
    }
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
    if (_useMemory) {
      final maxId = _memVehicles.isEmpty ? 0 : _memVehicles.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memVehicles.insert(0, v.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      return nativeInsert(_vt, v.toMap());
    } catch (e) { return -1; }
  }

  static Future<int> updateVehicle(Vehicle v) async {
    if (_useMemory) {
      for (int i = 0; i < _memVehicles.length; i++) {
        if (_memVehicles[i].id == v.id) { _memVehicles[i] = v; return 1; }
      }
      return 0;
    }
    try {
      return nativeUpdate(_vt, v.copyWith(updatedAt: DateTime.now()).toMap(), where: 'id = ?', whereArgs: [v.id]);
    } catch (e) { return 0; }
  }

  static Future<int> deleteVehicle(int id) async {
    if (_useMemory) {
      _memVehicles.removeWhere((v) => v.id == id);
      return 1;
    }
    try {
      return nativeDelete(_vt, where: 'id = ?', whereArgs: [id]);
    } catch (e) { return 0; }
  }

  // ===== Maintenance CRUD =====
  static Future<List<MaintenanceRecord>> getAllMaintenanceRecords() async {
    final vehicles = await getAllVehicles();
    if (_useMemory) {
      return _memRecords.map((r) {
        for (final v in vehicles) {
          if (v.id == r.vehicleId) return r.copyWith(vehicle: v);
        }
        return r;
      }).toList();
    }
    try {
      final maps = await nativeQuery(_mt, orderBy: 'maintenance_date DESC');
      return maps.map((m) {
        final vid = (m['vehicle_id'] as int?) ?? 0;
        Vehicle? veh;
        for (final v in vehicles) { if (v.id == vid) { veh = v; break; } }
        return MaintenanceRecord.fromMap(m).copyWith(vehicle: veh);
      }).toList();
    } catch (e) {
      return List.from(_memRecords);
    }
  }

  static Future<List<MaintenanceRecord>> getMaintenanceByVehicleId(int vid) async {
    final v = await getVehicleById(vid);
    if (_useMemory) {
      return _memRecords.where((r) => r.vehicleId == vid).map((r) => r.copyWith(vehicle: v)).toList();
    }
    try {
      final maps = await nativeQuery(_mt, where: 'vehicle_id = ?', whereArgs: [vid], orderBy: 'maintenance_date DESC');
      return maps.map((m) => MaintenanceRecord.fromMap(m).copyWith(vehicle: v)).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertMaintenanceRecord(MaintenanceRecord r) async {
    if (_useMemory) {
      final maxId = _memRecords.isEmpty ? 0 : _memRecords.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memRecords.insert(0, r.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      return nativeInsert(_mt, r.toMap());
    } catch (e) { return -1; }
  }

  static Future<int> updateMaintenanceRecord(MaintenanceRecord r) async {
    if (_useMemory) {
      for (int i = 0; i < _memRecords.length; i++) {
        if (_memRecords[i].id == r.id) { _memRecords[i] = r; return 1; }
      }
      return 0;
    }
    try {
      return nativeUpdate(_mt, r.copyWith(updatedAt: DateTime.now()).toMap(), where: 'id = ?', whereArgs: [r.id]);
    } catch (e) { return 0; }
  }

  static Future<int> deleteMaintenanceRecord(int id) async {
    if (_useMemory) {
      _memRecords.removeWhere((r) => r.id == id);
      return 1;
    }
    try {
      return nativeDelete(_mt, where: 'id = ?', whereArgs: [id]);
    } catch (e) { return 0; }
  }

  // ===== Checklist CRUD =====
  static Future<List<Checklist>> getAllChecklists() async {
    final vehicles = await getAllVehicles();
    if (_useMemory) {
      return _memChecklists.map((c) {
        for (final v in vehicles) {
          if (v.id == c.vehicleId) return c.copyWith(vehicle: v);
        }
        return c;
      }).toList();
    }
    try {
      final maps = await nativeQuery(_ct, orderBy: 'inspection_date DESC');
      return maps.map((m) {
        final vid = (m['vehicle_id'] as int?) ?? 0;
        Vehicle? veh;
        for (final v in vehicles) { if (v.id == vid) { veh = v; break; } }
        return Checklist.fromMap(m).copyWith(vehicle: veh);
      }).toList();
    } catch (e) {
      return List.from(_memChecklists);
    }
  }

  static Future<Checklist?> getChecklistById(int id) async {
    final vehicles = await getAllVehicles();
    if (_useMemory) {
      for (final c in _memChecklists) {
        if (c.id == id) {
          for (final v in vehicles) {
            if (v.id == c.vehicleId) return c.copyWith(vehicle: v);
          }
          return c;
        }
      }
      return null;
    }
    try {
      final maps = await nativeQuery(_ct, where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return null;
      final vid = (maps.first['vehicle_id'] as int?) ?? 0;
      Vehicle? veh;
      for (final v in vehicles) { if (v.id == vid) { veh = v; break; } }
      return Checklist.fromMap(maps.first).copyWith(vehicle: veh);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Checklist>> getChecklistsByVehicleId(int vid) async {
    final v = await getVehicleById(vid);
    if (_useMemory) {
      return _memChecklists.where((c) => c.vehicleId == vid).map((c) => c.copyWith(vehicle: v)).toList();
    }
    try {
      final maps = await nativeQuery(_ct, where: 'vehicle_id = ?', whereArgs: [vid], orderBy: 'inspection_date DESC');
      return maps.map((m) => Checklist.fromMap(m).copyWith(vehicle: v)).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertChecklist(Checklist c) async {
    if (_useMemory) {
      final maxId = _memChecklists.isEmpty ? 0 : _memChecklists.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memChecklists.insert(0, c.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      return nativeInsert(_ct, c.toMap());
    } catch (e) { return -1; }
  }

  static Future<int> updateChecklist(Checklist c) async {
    if (_useMemory) {
      for (int i = 0; i < _memChecklists.length; i++) {
        if (_memChecklists[i].id == c.id) { _memChecklists[i] = c; return 1; }
      }
      return 0;
    }
    try {
      return nativeUpdate(_ct, c.copyWith(updatedAt: DateTime.now()).toMap(), where: 'id = ?', whereArgs: [c.id]);
    } catch (e) { return 0; }
  }

  static Future<int> deleteChecklist(int id) async {
    if (_useMemory) {
      _memChecklists.removeWhere((c) => c.id == id);
      return 1;
    }
    try {
      return nativeDelete(_ct, where: 'id = ?', whereArgs: [id]);
    } catch (e) { return 0; }
  }

  // ===== FuelRecord CRUD =====
  static Future<List<FuelRecord>> getAllFuelRecords() async {
    final vehicles = await getAllVehicles();
    if (_useMemory) {
      return _memFuelRecords.map((f) {
        for (final v in vehicles) {
          if (v.id == f.vehicleId) return f.copyWith(vehicle: v);
        }
        return f;
      }).toList();
    }
    try {
      final maps = await nativeQuery(_ft, orderBy: 'fill_date DESC');
      return maps.map((m) {
        final vid = (m['vehicle_id'] as int?) ?? 0;
        Vehicle? veh;
        for (final v in vehicles) { if (v.id == vid) { veh = v; break; } }
        return FuelRecord.fromMap(m).copyWith(vehicle: veh);
      }).toList();
    } catch (e) {
      return List.from(_memFuelRecords);
    }
  }

  static Future<FuelRecord?> getFuelRecordById(int id) async {
    final vehicles = await getAllVehicles();
    if (_useMemory) {
      for (final f in _memFuelRecords) {
        if (f.id == id) {
          for (final v in vehicles) {
            if (v.id == f.vehicleId) return f.copyWith(vehicle: v);
          }
          return f;
        }
      }
      return null;
    }
    try {
      final maps = await nativeQuery(_ft, where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return null;
      final vid = (maps.first['vehicle_id'] as int?) ?? 0;
      Vehicle? veh;
      for (final v in vehicles) { if (v.id == vid) { veh = v; break; } }
      return FuelRecord.fromMap(maps.first).copyWith(vehicle: veh);
    } catch (e) {
      return null;
    }
  }

  static Future<List<FuelRecord>> getFuelRecordsByVehicleId(int vid) async {
    final v = await getVehicleById(vid);
    if (_useMemory) {
      return _memFuelRecords.where((f) => f.vehicleId == vid).map((f) => f.copyWith(vehicle: v)).toList();
    }
    try {
      final maps = await nativeQuery(_ft, where: 'vehicle_id = ?', whereArgs: [vid], orderBy: 'fill_date DESC');
      return maps.map((m) => FuelRecord.fromMap(m).copyWith(vehicle: v)).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertFuelRecord(FuelRecord f) async {
    if (_useMemory) {
      final maxId = _memFuelRecords.isEmpty ? 0 : _memFuelRecords.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      final record = f.copyWith(id: maxId + 1);
      _memFuelRecords.insert(0, record);
      _calculateAndUpdateConsumptionRate(record, _memFuelRecords);
      return maxId + 1;
    }
    try {
      final id = await nativeInsert(_ft, f.toMap());
      return id;
    } catch (e) { return -1; }
  }

  static Future<int> updateFuelRecord(FuelRecord f) async {
    if (_useMemory) {
      for (int i = 0; i < _memFuelRecords.length; i++) {
        if (_memFuelRecords[i].id == f.id) { _memFuelRecords[i] = f; return 1; }
      }
      return 0;
    }
    try {
      return nativeUpdate(_ft, f.copyWith(updatedAt: DateTime.now()).toMap(), where: 'id = ?', whereArgs: [f.id]);
    } catch (e) { return 0; }
  }

  static Future<int> deleteFuelRecord(int id) async {
    if (_useMemory) {
      _memFuelRecords.removeWhere((f) => f.id == id);
      return 1;
    }
    try {
      return nativeDelete(_ft, where: 'id = ?', whereArgs: [id]);
    } catch (e) { return 0; }
  }

  // ===== Fuel Consumption Rate Calculation =====

  static const double _abnormalThreshold = 0.20;

  static void _calculateAndUpdateConsumptionRate(
      FuelRecord newRecord, List<FuelRecord> allRecords) {
    final vehicleRecords = allRecords
        .where((r) => r.vehicleId == newRecord.vehicleId)
        .toList()
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

  // ===== Fuel Consumption Stats =====
  static Future<Map<int, Map<String, dynamic>>> getFuelConsumptionStats() async {
    final records = await getAllFuelRecords();
    final Map<int, List<FuelRecord>> byVehicle = {};
    for (final r in records) {
      byVehicle.putIfAbsent(r.vehicleId, () => []);
      byVehicle[r.vehicleId]!.add(r);
    }

    final Map<int, Map<String, dynamic>> stats = {};
    byVehicle.forEach((vid, recs) {
      recs.sort((a, b) => a.odometerReading.compareTo(b.odometerReading));

      final List<double> consumptionRates = [];
      double totalLiters = 0;
      double totalCost = 0;
      int abnormalCount = 0;

      for (final r in recs) {
        totalLiters += r.liters;
        totalCost += r.totalCost;
      }

      for (int i = 1; i < recs.length; i++) {
        final prev = recs[i - 1];
        final curr = recs[i];
        if (prev.fullTank && curr.fullTank && curr.liters > 0) {
          final distance = curr.odometerReading - prev.odometerReading;
          if (distance > 0) {
            final rate = distance / curr.liters;
            consumptionRates.add(rate);
          }
        }
      }

      double avgRate = 0;
      if (consumptionRates.isNotEmpty) {
        double sum = 0;
        for (final r in consumptionRates) { sum += r; }
        avgRate = sum / consumptionRates.length;

        for (final r in consumptionRates) {
          if (r > 0 && (avgRate - r) / r > 0.20) {
            abnormalCount++;
          }
        }
      }

      stats[vid] = {
        'vehicleId': vid,
        'totalFillUps': recs.length,
        'totalLiters': totalLiters,
        'totalCost': totalCost,
        'avgConsumptionRate': avgRate,
        'consumptionRates': consumptionRates,
        'abnormalCount': abnormalCount,
        'fullTankFillUps': recs.where((r) => r.fullTank).length,
      };
    });

    return stats;
  }

  // ===== DriverViolation CRUD =====
  static Future<List<DriverViolation>> getAllViolations() async {
    final vehicles = await getAllVehicles();
    if (_useMemory) {
      return _memViolations.map((v) {
        Vehicle? veh;
        for (final vv in vehicles) { if (vv.id == v.vehicleId) { veh = vv; break; } }
        return v.copyWith(vehicle: veh);
      }).toList();
    }
    try {
      final maps = await nativeQuery(_vt2, orderBy: 'date DESC');
      return maps.map((m) {
        final vid = (m['vehicle_id'] as int?) ?? 0;
        Vehicle? veh;
        for (final v in vehicles) { if (v.id == vid) { veh = v; break; } }
        return DriverViolation.fromMap(m).copyWith(vehicle: veh);
      }).toList();
    } catch (e) {
      return List.from(_memViolations);
    }
  }

  static Future<List<DriverViolation>> getViolationsByVehicleId(int vehicleId) async {
    final vehicles = await getAllVehicles();
    Vehicle? veh;
    for (final v in vehicles) { if (v.id == vehicleId) { veh = v; break; } }

    if (_useMemory) {
      return _memViolations.where((v) => v.vehicleId == vehicleId).map((v) {
        return v.copyWith(vehicle: veh);
      }).toList();
    }
    try {
      final maps = await nativeQuery(_vt2, where: 'vehicle_id = ?', whereArgs: [vehicleId], orderBy: 'date DESC');
      return maps.map((m) {
        return DriverViolation.fromMap(m).copyWith(vehicle: veh);
      }).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertViolation(DriverViolation v) async {
    if (_useMemory) {
      final maxId = _memViolations.isEmpty ? 0 : _memViolations.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memViolations.insert(0, v.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      return nativeInsert(_vt2, v.toMap());
    } catch (e) { return -1; }
  }

  static Future<int> updateViolation(DriverViolation v) async {
    if (_useMemory) {
      for (int i = 0; i < _memViolations.length; i++) {
        if (_memViolations[i].id == v.id) { _memViolations[i] = v; return 1; }
      }
      return 0;
    }
    try {
      return nativeUpdate(_vt2, v.copyWith(updatedAt: DateTime.now()).toMap(), where: 'id = ?', whereArgs: [v.id]);
    } catch (e) { return 0; }
  }

  static Future<int> deleteViolation(int id) async {
    if (_useMemory) {
      _memViolations.removeWhere((v) => v.id == id);
      return 1;
    }
    try {
      return nativeDelete(_vt2, where: 'id = ?', whereArgs: [id]);
    } catch (e) { return 0; }
  }

  // ===== Expense CRUD =====
  static Future<List<Expense>> getAllExpenses() async {
    final vehicles = await getAllVehicles();
    if (_useMemory) {
      return _memExpenses.map((e) {
        for (final v in vehicles) {
          if (v.id == e.vehicleId) return e.copyWith(vehicle: v);
        }
        return e;
      }).toList();
    }
    try {
      final maps = await nativeQuery(_et, orderBy: 'date DESC');
      return maps.map((m) {
        final vid = (m['vehicle_id'] as int?) ?? 0;
        Vehicle? veh;
        for (final v in vehicles) { if (v.id == vid) { veh = v; break; } }
        return Expense.fromMap(m).copyWith(vehicle: veh);
      }).toList();
    } catch (e) {
      return List.from(_memExpenses);
    }
  }

  static Future<List<Expense>> getExpensesByVehicleId(int vid) async {
    final v = await getVehicleById(vid);
    if (_useMemory) {
      return _memExpenses.where((e) => e.vehicleId == vid).map((e) => e.copyWith(vehicle: v)).toList();
    }
    try {
      final maps = await nativeQuery(_et, where: 'vehicle_id = ?', whereArgs: [vid], orderBy: 'date DESC');
      return maps.map((m) => Expense.fromMap(m).copyWith(vehicle: v)).toList();
    } catch (e) { return []; }
  }

  static Future<List<Expense>> getExpensesByType(String type) async {
    final vehicles = await getAllVehicles();
    if (_useMemory) {
      return _memExpenses.where((e) => e.type == type).map((e) {
        for (final v in vehicles) {
          if (v.id == e.vehicleId) return e.copyWith(vehicle: v);
        }
        return e;
      }).toList();
    }
    try {
      final maps = await nativeQuery(_et, where: 'type = ?', whereArgs: [type], orderBy: 'date DESC');
      return maps.map((m) {
        final vid = (m['vehicle_id'] as int?) ?? 0;
        Vehicle? veh;
        for (final v in vehicles) { if (v.id == vid) { veh = v; break; } }
        return Expense.fromMap(m).copyWith(vehicle: veh);
      }).toList();
    } catch (e) { return []; }
  }

  static Future<int> insertExpense(Expense e) async {
    if (_useMemory) {
      final maxId = _memExpenses.isEmpty ? 0 : _memExpenses.map((x) => x.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memExpenses.insert(0, e.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      return nativeInsert(_et, e.toMap());
    } catch (e) { return -1; }
  }

  static Future<int> updateExpense(Expense e) async {
    if (_useMemory) {
      for (int i = 0; i < _memExpenses.length; i++) {
        if (_memExpenses[i].id == e.id) { _memExpenses[i] = e; return 1; }
      }
      return 0;
    }
    try {
      return nativeUpdate(_et, e.copyWith(updatedAt: DateTime.now()).toMap(), where: 'id = ?', whereArgs: [e.id]);
    } catch (e) { return 0; }
  }

  static Future<int> deleteExpense(int id) async {
    if (_useMemory) {
      _memExpenses.removeWhere((e) => e.id == id);
      return 1;
    }
    try {
      return nativeDelete(_et, where: 'id = ?', whereArgs: [id]);
    } catch (e) { return 0; }
  }

  // ===== Statistics =====
  static Future<Map<String, dynamic>> getExpenseStats() async {
    final expenses = await getAllExpenses();
    double totalExpenses = 0;
    double tollCost = 0;
    double violationCost = 0;
    double insuranceCost = 0;
    double miscCost = 0;
    double maintenanceCost = 0;
    double fuelCost = 0;

    for (final e in expenses) {
      totalExpenses += e.amount;
      switch (e.type) {
        case 'toll':
          tollCost += e.amount;
          break;
        case 'violation':
          violationCost += e.amount;
          break;
        case 'insurance':
          insuranceCost += e.amount;
          break;
        case 'miscellaneous':
          miscCost += e.amount;
          break;
        case 'maintenance':
          maintenanceCost += e.amount;
          break;
        case 'fuel':
          fuelCost += e.amount;
          break;
      }
    }

    return {
      'totalExpenses': totalExpenses,
      'tollCost': tollCost,
      'violationCost': violationCost,
      'insuranceCost': insuranceCost,
      'miscCost': miscCost,
      'maintenanceCost': maintenanceCost,
      'fuelCost': fuelCost,
    };
  }

  static Future<Map<String, dynamic>> getDriverStats() async {
    final vehicles = await getAllVehicles();
    final now = DateTime.now();
    int totalDrivers = 0;
    int activeDrivers = 0;
    int suspendedDrivers = 0;
    int nearExpiryCount = 0;
    int expiredCount = 0;

    for (final v in vehicles) {
      if (v.driverName != null && v.driverName!.isNotEmpty) {
        totalDrivers++;
        if (v.driverStatus == 'suspended') {
          suspendedDrivers++;
        } else {
          activeDrivers++;
        }
        if (v.driverLicenseExpiry != null) {
          final diff = v.driverLicenseExpiry!.difference(now).inDays;
          if (diff < 0) {
            expiredCount++;
          } else if (diff <= 30) {
            nearExpiryCount++;
          }
        }
      }
    }

    return {
      'totalDrivers': totalDrivers,
      'activeDrivers': activeDrivers,
      'suspendedDrivers': suspendedDrivers,
      'nearExpiryCount': nearExpiryCount,
      'expiredCount': expiredCount,
    };
  }

  // ===== Statistics (pure Dart, no SQL) =====
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final vehicles = await getAllVehicles();
    final records = await getAllMaintenanceRecords();
    final completed = records.where((r) => r.status == 'completed').toList();
    double totalCost = 0;
    for (final r in completed) { totalCost += r.totalCost; }
    int pendingCount = 0;
    int inProgressCount = 0;
    int urgentCount = 0;
    for (final r in records) {
      if (r.status == 'pending') pendingCount++;
      if (r.status == 'in_progress') inProgressCount++;
      if (r.priority == 'urgent' && r.status != 'completed' && r.status != 'cancelled') urgentCount++;
    }
    int activeCount = 0;
    int maintCount = 0;
    for (final v in vehicles) {
      if (v.status == 'active') activeCount++;
      if (v.status == 'maintenance') maintCount++;
    }
    return {
      'vehicleCount': vehicles.length,
      'activeVehicles': activeCount,
      'maintenanceVehicles': maintCount,
      'totalCost': totalCost,
      'thisMonthCost': 0.0,
      'lastMonthCost': 0.0,
      'pendingRecords': pendingCount,
      'inProgressRecords': inProgressCount,
      'urgentRecords': urgentCount,
    };
  }

  static Future<List<Map<String, dynamic>>> getMaintenanceByType() async {
    final records = await getAllMaintenanceRecords();
    final Map<String, List<double>> typeCosts = {};
    for (final r in records) {
      if (r.status != 'completed') continue;
      typeCosts.putIfAbsent(r.type, () => []);
      typeCosts[r.type]!.add(r.totalCost);
    }
    final list = <Map<String, dynamic>>[];
    typeCosts.forEach((type, costs) {
      double total = 0;
      for (final c in costs) { total += c; }
      list.add({'type': type, 'count': costs.length, 'total_cost': total});
    });
    list.sort((a, b) => ((b['total_cost'] as double?) ?? 0).compareTo((a['total_cost'] as double?) ?? 0));
    return list;
  }

  static Future<List<Map<String, dynamic>>> getMonthlyCosts() async {
    final records = await getAllMaintenanceRecords();
    final Map<String, List<double>> monthCosts = {};
    for (final r in records) {
      if (r.status != 'completed') continue;
      final key = r.maintenanceDate.toIso8601String().substring(0, 7);
      monthCosts.putIfAbsent(key, () => []);
      monthCosts[key]!.add(r.totalCost);
    }
    final list = <Map<String, dynamic>>[];
    monthCosts.forEach((month, costs) {
      double total = 0;
      for (final c in costs) { total += c; }
      list.add({'month': month, 'total_cost': total, 'count': costs.length});
    });
    list.sort((a, b) => ((a['month'] as String?) ?? '').compareTo((b['month'] as String?) ?? ''));
    return list.reversed.toList();
  }

  static Future<List<Map<String, dynamic>>> getVehicleMaintenanceCosts() async {
    final vehicles = await getAllVehicles();
    final records = await getAllMaintenanceRecords();
    final completed = records.where((r) => r.status == 'completed').toList();
    final list = <Map<String, dynamic>>[];
    for (final v in vehicles) {
      double total = 0;
      int count = 0;
      for (final r in completed) {
        if (r.vehicleId == v.id) { total += r.totalCost; count++; }
      }
      list.add({
        'plate_number': v.plateNumber,
        'make': v.make,
        'model': v.model,
        'record_count': count,
        'total_cost': total,
      });
    }
    list.sort((a, b) => ((b['total_cost'] as double?) ?? 0).compareTo((a['total_cost'] as double?) ?? 0));
    if (list.length > 10) return list.sublist(0, 10);
    return list;
  }
}
