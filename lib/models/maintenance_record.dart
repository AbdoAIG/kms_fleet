import 'vehicle.dart';

class MaintenanceRecord {
  final int? id;
  final int vehicleId;
  final Vehicle? vehicle;
  final DateTime maintenanceDate;
  final String description;
  final String type;
  final int odometerReading;
  final double cost;
  final double? laborCost;
  final String? serviceProvider;
  final String? invoiceNumber;
  final String priority;
  final String status;
  final String? partsUsed;
  final DateTime? nextMaintenanceDate;
  final int? nextMaintenanceKm;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceRecord({
    this.id,
    required this.vehicleId,
    this.vehicle,
    required this.maintenanceDate,
    required this.description,
    required this.type,
    required this.odometerReading,
    required this.cost,
    this.laborCost,
    this.serviceProvider,
    this.invoiceNumber,
    required this.priority,
    required this.status,
    this.partsUsed,
    this.nextMaintenanceDate,
    this.nextMaintenanceKm,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  MaintenanceRecord copyWith({
    int? id,
    int? vehicleId,
    Vehicle? vehicle,
    DateTime? maintenanceDate,
    String? description,
    String? type,
    int? odometerReading,
    double? cost,
    double? laborCost,
    String? serviceProvider,
    String? invoiceNumber,
    String? priority,
    String? status,
    String? partsUsed,
    DateTime? nextMaintenanceDate,
    int? nextMaintenanceKm,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: vehicle ?? this.vehicle,
      maintenanceDate: maintenanceDate ?? this.maintenanceDate,
      description: description ?? this.description,
      type: type ?? this.type,
      odometerReading: odometerReading ?? this.odometerReading,
      cost: cost ?? this.cost,
      laborCost: laborCost ?? this.laborCost,
      serviceProvider: serviceProvider ?? this.serviceProvider,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      partsUsed: partsUsed ?? this.partsUsed,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      nextMaintenanceKm: nextMaintenanceKm ?? this.nextMaintenanceKm,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get totalCost => cost + (laborCost ?? 0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'maintenance_date': maintenanceDate.toIso8601String(),
      'description': description,
      'type': type,
      'odometer_reading': odometerReading,
      'cost': cost,
      'labor_cost': laborCost,
      'service_provider': serviceProvider,
      'invoice_number': invoiceNumber,
      'priority': priority,
      'status': status,
      'parts_used': partsUsed,
      'next_maintenance_date': nextMaintenanceDate?.toIso8601String(),
      'next_maintenance_km': nextMaintenanceKm,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    // Helper للتحويل الآمن بين الأنواع
    int? toInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) : null);
    double? toDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }
    String? toStr(dynamic v) => v?.toString();

    return MaintenanceRecord(
      id: toInt(map['id']),
      vehicleId: toInt(map['vehicle_id']) ?? 0,
      maintenanceDate: map['maintenance_date'] != null
          ? (map['maintenance_date'] is DateTime
              ? map['maintenance_date'] as DateTime
              : DateTime.tryParse(toStr(map['maintenance_date'])!) ?? DateTime.now())
          : DateTime.now(),
      description: toStr(map['description']) ?? '',
      type: toStr(map['type']) ?? 'other',
      odometerReading: toInt(map['odometer_reading']) ?? 0,
      cost: toDouble(map['cost']) ?? 0.0,
      laborCost: toDouble(map['labor_cost']),
      serviceProvider: toStr(map['service_provider']),
      invoiceNumber: toStr(map['invoice_number']),
      priority: toStr(map['priority']) ?? 'medium',
      status: toStr(map['status']) ?? 'pending',
      partsUsed: toStr(map['parts_used']),
      nextMaintenanceDate: map['next_maintenance_date'] != null
          ? (map['next_maintenance_date'] is DateTime
              ? map['next_maintenance_date'] as DateTime
              : DateTime.tryParse(toStr(map['next_maintenance_date'])!))
          : null,
      nextMaintenanceKm: toInt(map['next_maintenance_km']),
      notes: toStr(map['notes']),
      createdAt: map['created_at'] != null
          ? (map['created_at'] is DateTime
              ? map['created_at'] as DateTime
              : DateTime.tryParse(toStr(map['created_at'])!) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? (map['updated_at'] is DateTime
              ? map['updated_at'] as DateTime
              : DateTime.tryParse(toStr(map['updated_at'])!) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
