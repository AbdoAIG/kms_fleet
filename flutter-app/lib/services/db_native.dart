// ─────────────────────────────────────────────────────────────────────────────
// db_native.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// Native database backend using sqflite (only compiled when dart:io is available).
// Provides real SQLite operations for Android, iOS, Windows, macOS, and Linux.
//
// On web, db_stub.dart is used instead via conditional import.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Platform-specific SQLite imports
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/checklist.dart';
import '../models/fuel_record.dart';

/// Whether the native database was successfully initialized.
bool nativeDbAvailable = false;

/// Internal database instance.
Database? _database;

/// Table names
const _vt = 'vehicles';
const _mt = 'maintenance_records';
const _ct = 'checklists';
const _ft = 'fuel_records';
const _tt = 'trip_trackings';

/// Attempt to initialize the native SQLite database.
/// Returns true if successful, false otherwise.
Future<void> initNativeDb() async {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'kms_fleet.db');
      _database = await openDatabase(path, version: 1, onCreate: _onCreate);
      nativeDbAvailable = _database != null;
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop platforms: use sqflite_common_ffi
      sqfliteFfiInit();
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, 'kms_fleet.db');
      _database = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
      );
      nativeDbAvailable = _database != null;
    } else {
      nativeDbAvailable = false;
    }
  } catch (e) {
    debugPrint('Native DB init error: $e');
    nativeDbAvailable = false;
  }
}

/// Called when the database is first created.
/// Creates all tables and inserts seed data.
Future<void> _onCreate(Database db, int version) async {
  await db.execute(
    'CREATE TABLE $_vt(id INTEGER PRIMARY KEY AUTOINCREMENT,plate_number TEXT NOT NULL,make TEXT NOT NULL,model TEXT NOT NULL,year INTEGER NOT NULL,color TEXT DEFAULT white,fuel_type TEXT DEFAULT petrol,current_odometer INTEGER DEFAULT 0,status TEXT DEFAULT active,notes TEXT,driver_name TEXT,driver_phone TEXT,driver_license_number TEXT,driver_license_expiry TEXT,driver_status TEXT DEFAULT active,created_at TEXT NOT NULL,updated_at TEXT NOT NULL)',
  );
  await db.execute(
    'CREATE TABLE $_mt(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_id INTEGER NOT NULL,maintenance_date TEXT NOT NULL,description TEXT NOT NULL,type TEXT NOT NULL,odometer_reading INTEGER DEFAULT 0,cost REAL DEFAULT 0,labor_cost REAL,service_provider TEXT,invoice_number TEXT,priority TEXT DEFAULT medium,status TEXT DEFAULT pending,parts_used TEXT,next_maintenance_date TEXT,next_maintenance_km INTEGER,notes TEXT,created_at TEXT NOT NULL,updated_at TEXT NOT NULL)',
  );
  await db.execute(
    'CREATE TABLE $_ct(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_id INTEGER NOT NULL,type TEXT NOT NULL,inspection_date TEXT NOT NULL,odometer_reading INTEGER DEFAULT 0,items TEXT NOT NULL,inspector_name TEXT,signature_path TEXT,notes TEXT,status TEXT DEFAULT pending,overall_score REAL DEFAULT 0,created_at TEXT NOT NULL,updated_at TEXT NOT NULL)',
  );
  await db.execute(
    'CREATE TABLE $_ft(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_id INTEGER NOT NULL,fill_date TEXT NOT NULL,odometer_reading INTEGER DEFAULT 0,liters REAL DEFAULT 0,cost_per_liter REAL DEFAULT 0,fuel_type TEXT DEFAULT petrol,station_name TEXT,station_location TEXT,full_tank INTEGER DEFAULT 1,notes TEXT,consumption_rate REAL,is_abnormal INTEGER DEFAULT 0,created_at TEXT NOT NULL,updated_at TEXT NOT NULL)',
  );
  await db.execute(
    'CREATE TABLE $_tt(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_id INTEGER NOT NULL,status TEXT DEFAULT active,start_lat REAL,start_lng REAL,end_lat REAL,end_lng REAL,start_address TEXT,end_address TEXT,distance_km REAL DEFAULT 0,duration_minutes REAL DEFAULT 0,start_odometer INTEGER,end_odometer INTEGER,notes TEXT,trip_points_json TEXT,driver_name TEXT,created_at TEXT NOT NULL,updated_at TEXT NOT NULL)',
  );

  final now = DateTime.now().toIso8601String();

  // Seed vehicles
  for (final v in _seedVehicles()) {
    await db.rawInsert(
      "INSERT INTO $_vt(plate_number,make,model,year,color,fuel_type,current_odometer,status,notes,driver_name,driver_phone,driver_license_number,driver_license_expiry,driver_status,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
      [v.plateNumber, v.make, v.model, v.year, v.color, v.fuelType, v.currentOdometer, v.status, v.notes ?? '', v.driverName ?? '', v.driverPhone ?? '', v.driverLicenseNumber ?? '', v.driverLicenseExpiry?.toIso8601String() ?? '', v.driverStatus ?? 'active', now, now],
    );
  }

  // Seed maintenance records
  for (final r in _seedRecords()) {
    await db.rawInsert(
      "INSERT INTO $_mt(vehicle_id,maintenance_date,description,type,odometer_reading,cost,labor_cost,service_provider,invoice_number,priority,status,parts_used,notes,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
      [r.vehicleId, now, r.description, r.type, r.odometerReading, r.cost, r.laborCost, r.serviceProvider, r.invoiceNumber, r.priority, r.status, r.partsUsed, r.notes ?? '', now, now],
    );
  }

  // Seed checklists
  for (final c in _seedChecklists()) {
    await db.rawInsert(
      "INSERT INTO $_ct(vehicle_id,type,inspection_date,odometer_reading,items,inspector_name,notes,status,overall_score,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)",
      [c.vehicleId, c.type, now, c.odometerReading, jsonEncode(c.items.map((i) => i.toMap()).toList()), c.inspectorName ?? '', c.notes ?? '', c.status, c.overallScore, now, now],
    );
  }

  // Seed fuel records
  for (final f in _seedFuelRecords()) {
    await db.rawInsert(
      "INSERT INTO $_ft(vehicle_id,fill_date,odometer_reading,liters,cost_per_liter,fuel_type,station_name,station_location,full_tank,notes,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)",
      [f.vehicleId, now, f.odometerReading, f.liters, f.costPerLiter, f.fuelType, f.stationName ?? '', f.stationLocation ?? '', f.fullTank ? 1 : 0, f.notes ?? '', now, now],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Seed data generators
// ═══════════════════════════════════════════════════════════════════════════

List<Vehicle> _seedVehicles() {
  final n = DateTime.now();
  return [
    Vehicle(id: 1, plateNumber: 'أ ب ج 1234', make: 'تويوتا', model: 'كامري', year: 2023, color: 'white', fuelType: 'petrol', currentOdometer: 45000, status: 'active', driverName: 'أحمد محمود', driverPhone: '01012345678', driverLicenseNumber: 'DL-001', driverLicenseExpiry: n.add(const Duration(days: 180)), driverStatus: 'active', createdAt: n, updatedAt: n),
    Vehicle(id: 2, plateNumber: 'د ه و 5678', make: 'هيونداي', model: 'توسان', year: 2022, color: 'black', fuelType: 'petrol', currentOdometer: 62000, status: 'active', driverName: 'محمد علي', driverPhone: '01098765432', driverLicenseNumber: 'DL-002', driverLicenseExpiry: n.add(const Duration(days: 90)), driverStatus: 'active', createdAt: n, updatedAt: n),
    Vehicle(id: 3, plateNumber: 'ز ح ط 9012', make: 'نيسان', model: 'صني', year: 2021, color: 'silver', fuelType: 'petrol', currentOdometer: 89000, status: 'active', driverName: 'حسن إبراهيم', driverPhone: '01055544433', driverLicenseNumber: 'DL-003', driverLicenseExpiry: n.add(const Duration(days: 30)), driverStatus: 'active', createdAt: n, updatedAt: n),
    Vehicle(id: 4, plateNumber: 'ي ك ل 3456', make: 'كيا', model: 'سبورتاج', year: 2023, color: 'blue', fuelType: 'diesel', currentOdometer: 28000, status: 'active', driverName: 'خالد سعيد', driverPhone: '01112223334', driverLicenseNumber: 'DL-004', driverLicenseExpiry: n.add(const Duration(days: 365)), driverStatus: 'active', createdAt: n, updatedAt: n),
    Vehicle(id: 5, plateNumber: 'م ن س 7890', make: 'مرسيدس', model: 'C-Class', year: 2022, color: 'black', fuelType: 'petrol', currentOdometer: 35000, status: 'maintenance', driverName: 'عمر فاروق', driverPhone: '01155667788', driverLicenseNumber: 'DL-005', driverLicenseExpiry: n.subtract(const Duration(days: 30)), driverStatus: 'suspended', createdAt: n, updatedAt: n),
    Vehicle(id: 6, plateNumber: 'ع ف ق 2345', make: 'تويوتا', model: 'هايلكس', year: 2020, color: 'white', fuelType: 'diesel', currentOdometer: 120000, status: 'active', driverName: 'ياسر أحمد', driverPhone: '01234567890', driverLicenseNumber: 'DL-006', driverLicenseExpiry: n.add(const Duration(days: 240)), driverStatus: 'active', createdAt: n, updatedAt: n),
    Vehicle(id: 7, plateNumber: 'ر ش ت 6789', make: 'هيونداي', model: 'إلنترا', year: 2024, color: 'red', fuelType: 'petrol', currentOdometer: 8000, status: 'active', driverName: 'عبدالله حسن', driverPhone: '01087654321', driverLicenseNumber: 'DL-007', driverLicenseExpiry: n.add(const Duration(days: 400)), driverStatus: 'active', createdAt: n, updatedAt: n),
    Vehicle(id: 8, plateNumber: 'ث خ ذ 0123', make: 'فورد', model: 'إكسبلورر', year: 2021, color: 'gray', fuelType: 'petrol', currentOdometer: 78000, status: 'inactive', driverName: 'محمود سالم', driverPhone: '01133445566', driverLicenseNumber: 'DL-008', driverLicenseExpiry: n.add(const Duration(days: 60)), driverStatus: 'active', createdAt: n, updatedAt: n),
    Vehicle(id: 9, plateNumber: 'ض ظ غ 4567', make: 'شيفروليه', model: 'تاهو', year: 2023, color: 'black', fuelType: 'petrol', currentOdometer: 22000, status: 'active', driverName: 'طه عبدالرحمن', driverPhone: '01022334455', driverLicenseNumber: 'DL-009', driverLicenseExpiry: n.add(const Duration(days: 300)), driverStatus: 'active', createdAt: n, updatedAt: n),
    Vehicle(id: 10, plateNumber: 'ج ث ب 8901', make: 'تويوتا', model: 'لاند كروزر', year: 2022, color: 'white', fuelType: 'diesel', currentOdometer: 55000, status: 'active', driverName: 'إبراهيم عثمان', driverPhone: '01099887766', driverLicenseNumber: 'DL-010', driverLicenseExpiry: n.add(const Duration(days: 150)), driverStatus: 'active', createdAt: n, updatedAt: n),
    Vehicle(id: 11, plateNumber: 'ن ح ي 2468', make: 'بي إم دبليو', model: 'الفئة 5', year: 2021, color: 'blue', fuelType: 'petrol', currentOdometer: 92000, status: 'active', driverName: 'كريم حسام', driverPhone: '01166778899', driverLicenseNumber: 'DL-011', driverLicenseExpiry: n.add(const Duration(days: 200)), driverStatus: 'active', createdAt: n, updatedAt: n),
    Vehicle(id: 12, plateNumber: 'و ك م 1357', make: 'أودي', model: 'Q7', year: 2023, color: 'gray', fuelType: 'diesel', currentOdometer: 18000, status: 'active', driverName: 'رامي شريف', driverPhone: '01144556677', driverLicenseNumber: 'DL-012', driverLicenseExpiry: n.add(const Duration(days: 500)), driverStatus: 'active', createdAt: n, updatedAt: n),
  ];
}

List<MaintenanceRecord> _seedRecords() {
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

List<Checklist> _seedChecklists() {
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

List<FuelRecord> _seedFuelRecords() {
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

// ═══════════════════════════════════════════════════════════════════════════
//  Database operations
// ═══════════════════════════════════════════════════════════════════════════

/// Query a table and return matching rows.
Future<List<Map<String, dynamic>>> nativeQuery(
  String table, {
  String? orderBy,
  String? where,
  List<Object?>? whereArgs,
}) async {
  if (_database == null) return [];
  return _database!.query(table, orderBy: orderBy, where: where, whereArgs: whereArgs);
}

/// Insert a row and return the new row ID.
Future<int> nativeInsert(String table, Map<String, Object?> values) async {
  if (_database == null) return -1;
  return _database!.insert(table, values);
}

/// Update matching rows and return the number of affected rows.
Future<int> nativeUpdate(
  String table,
  Map<String, Object?> values, {
  String? where,
  List<Object?>? whereArgs,
}) async {
  if (_database == null) return 0;
  return _database!.update(table, values, where: where, whereArgs: whereArgs);
}

/// Delete matching rows and return the number of affected rows.
Future<int> nativeDelete(
  String table, {
  String? where,
  List<Object?>? whereArgs,
}) async {
  if (_database == null) return 0;
  return _database!.delete(table, where: where, whereArgs: whereArgs);
}

/// Execute raw SQL.
Future<void> nativeExec(String sql, [List<Object?>? args]) async {
  if (_database == null) return;
  await _database!.execute(sql, args);
}
