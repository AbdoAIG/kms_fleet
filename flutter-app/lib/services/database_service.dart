import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../utils/constants.dart';

class DatabaseService {
  static Database? _database;
  static bool _useMemory = true;
  static List<Vehicle> _memVehicles = [];
  static List<MaintenanceRecord> _memRecords = [];
  static const _vt = 'vehicles';
  static const _mt = 'maintenance_records';

  DatabaseService._();

  static Future<void> initialize() async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        _useMemory = true;
        _seedMemory();
        return;
      }
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.dbName);
      _database = await openDatabase(path, version: 1, onCreate: _onCreate);
      _useMemory = false;
    } catch (e) {
      debugPrint('DB init error, fallback to memory: $e');
      _useMemory = true;
      _seedMemory();
    }
  }

  static Future<void> _onCreate(Database db, int v) async {
    await db.execute('CREATE TABLE $_vt(id INTEGER PRIMARY KEY AUTOINCREMENT,plate_number TEXT NOT NULL,make TEXT NOT NULL,model TEXT NOT NULL,year INTEGER NOT NULL,color TEXT DEFAULT white,fuel_type TEXT DEFAULT petrol,current_odometer INTEGER DEFAULT 0,status TEXT DEFAULT active,notes TEXT,created_at TEXT NOT NULL,updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE $_mt(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_id INTEGER NOT NULL,maintenance_date TEXT NOT NULL,description TEXT NOT NULL,type TEXT NOT NULL,odometer_reading INTEGER DEFAULT 0,cost REAL DEFAULT 0,labor_cost REAL,service_provider TEXT,invoice_number TEXT,priority TEXT DEFAULT medium,status TEXT DEFAULT pending,parts_used TEXT,next_maintenance_date TEXT,next_maintenance_km INTEGER,notes TEXT,created_at TEXT NOT NULL,updated_at TEXT NOT NULL)');
    final now = DateTime.now().toIso8601String();
    for (final v in _seedVehicles()) {
      await db.rawInsert("INSERT INTO $_vt(plate_number,make,model,year,color,fuel_type,current_odometer,status,notes,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)",
          [v.plateNumber, v.make, v.model, v.year, v.color, v.fuelType, v.currentOdometer, v.status, v.notes ?? '', now, now]);
    }
    for (final r in _seedRecords()) {
      await db.rawInsert("INSERT INTO $_mt(vehicle_id,maintenance_date,description,type,odometer_reading,cost,labor_cost,service_provider,invoice_number,priority,status,parts_used,notes,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
          [r.vehicleId, now, r.description, r.type, r.odometerReading, r.cost, r.laborCost, r.serviceProvider, r.invoiceNumber, r.priority, r.status, r.partsUsed, r.notes ?? '', now, now]);
    }
  }

  static void _seedMemory() {
    _memVehicles = _seedVehicles();
    _memRecords = _seedRecords();
  }

  static List<Vehicle> _seedVehicles() {
    final n = DateTime.now();
    return [
      Vehicle(id: 1, plateNumber: 'أ ب ج 1234', make: 'تويوتا', model: 'كامري', year: 2023, color: 'white', fuelType: 'petrol', currentOdometer: 45000, status: 'active', createdAt: n, updatedAt: n),
      Vehicle(id: 2, plateNumber: 'د ه و 5678', make: 'هيونداي', model: 'توسان', year: 2022, color: 'black', fuelType: 'petrol', currentOdometer: 62000, status: 'active', createdAt: n, updatedAt: n),
      Vehicle(id: 3, plateNumber: 'ز ح ط 9012', make: 'نيسان', model: 'صني', year: 2021, color: 'silver', fuelType: 'petrol', currentOdometer: 89000, status: 'active', createdAt: n, updatedAt: n),
      Vehicle(id: 4, plateNumber: 'ي ك ل 3456', make: 'كيا', model: 'سبورتاج', year: 2023, color: 'blue', fuelType: 'diesel', currentOdometer: 28000, status: 'active', createdAt: n, updatedAt: n),
      Vehicle(id: 5, plateNumber: 'م ن س 7890', make: 'مرسيدس', model: 'C-Class', year: 2022, color: 'black', fuelType: 'petrol', currentOdometer: 35000, status: 'maintenance', createdAt: n, updatedAt: n),
      Vehicle(id: 6, plateNumber: 'ع ف ق 2345', make: 'تويوتا', model: 'هايلكس', year: 2020, color: 'white', fuelType: 'diesel', currentOdometer: 120000, status: 'active', createdAt: n, updatedAt: n),
      Vehicle(id: 7, plateNumber: 'ر ش ت 6789', make: 'هيونداي', model: 'إلنترا', year: 2024, color: 'red', fuelType: 'petrol', currentOdometer: 8000, status: 'active', createdAt: n, updatedAt: n),
      Vehicle(id: 8, plateNumber: 'ث خ ذ 0123', make: 'فورد', model: 'إكسبلورر', year: 2021, color: 'gray', fuelType: 'petrol', currentOdometer: 78000, status: 'inactive', createdAt: n, updatedAt: n),
      Vehicle(id: 9, plateNumber: 'ض ظ غ 4567', make: 'شيفروليه', model: 'تاهو', year: 2023, color: 'black', fuelType: 'petrol', currentOdometer: 22000, status: 'active', createdAt: n, updatedAt: n),
      Vehicle(id: 10, plateNumber: 'ج ث ب 8901', make: 'تويوتا', model: 'لاند كروزر', year: 2022, color: 'white', fuelType: 'diesel', currentOdometer: 55000, status: 'active', createdAt: n, updatedAt: n),
      Vehicle(id: 11, plateNumber: 'ن ح ي 2468', make: 'بي إم دبليو', model: 'الفئة 5', year: 2021, color: 'blue', fuelType: 'petrol', currentOdometer: 92000, status: 'active', createdAt: n, updatedAt: n),
      Vehicle(id: 12, plateNumber: 'و ك م 1357', make: 'أودي', model: 'Q7', year: 2023, color: 'gray', fuelType: 'diesel', currentOdometer: 18000, status: 'active', createdAt: n, updatedAt: n),
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

  // ===== Vehicle CRUD =====
  static Future<List<Vehicle>> getAllVehicles() async {
    if (_useMemory) return List.from(_memVehicles);
    try {
      final db = _database;
      if (db == null) return List.from(_memVehicles);
      final maps = await db.query(_vt, orderBy: 'created_at DESC');
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
      final db = _database;
      if (db == null) return null;
      final maps = await db.query(_vt, where: 'id = ?', whereArgs: [id]);
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
        v.model.toLowerCase().contains(q)).toList();
  }

  static Future<int> insertVehicle(Vehicle v) async {
    if (_useMemory) {
      final maxId = _memVehicles.isEmpty ? 0 : _memVehicles.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
      _memVehicles.insert(0, v.copyWith(id: maxId + 1));
      return maxId + 1;
    }
    try {
      final db = _database;
      if (db == null) return -1;
      return db.insert(_vt, v.toMap());
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
      final db = _database;
      if (db == null) return 0;
      return db.update(_vt, v.copyWith(updatedAt: DateTime.now()).toMap(), where: 'id = ?', whereArgs: [v.id]);
    } catch (e) { return 0; }
  }

  static Future<int> deleteVehicle(int id) async {
    if (_useMemory) {
      _memVehicles.removeWhere((v) => v.id == id);
      return 1;
    }
    try {
      final db = _database;
      if (db == null) return 0;
      return db.delete(_vt, where: 'id = ?', whereArgs: [id]);
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
      final db = _database;
      if (db == null) return List.from(_memRecords);
      final maps = await db.query(_mt, orderBy: 'maintenance_date DESC');
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
      final db = _database;
      if (db == null) return [];
      final maps = await db.query(_mt, where: 'vehicle_id = ?', whereArgs: [vid], orderBy: 'maintenance_date DESC');
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
      final db = _database;
      if (db == null) return -1;
      return db.insert(_mt, r.toMap());
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
      final db = _database;
      if (db == null) return 0;
      return db.update(_mt, r.copyWith(updatedAt: DateTime.now()).toMap(), where: 'id = ?', whereArgs: [r.id]);
    } catch (e) { return 0; }
  }

  static Future<int> deleteMaintenanceRecord(int id) async {
    if (_useMemory) {
      _memRecords.removeWhere((r) => r.id == id);
      return 1;
    }
    try {
      final db = _database;
      if (db == null) return 0;
      return db.delete(_mt, where: 'id = ?', whereArgs: [id]);
    } catch (e) { return 0; }
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
