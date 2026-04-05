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
    return MaintenanceRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int? ?? 0,
      maintenanceDate: map['maintenance_date'] != null
          ? DateTime.parse(map['maintenance_date'] as String)
          : DateTime.now(),
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? 'other',
      odometerReading: map['odometer_reading'] as int? ?? 0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      laborCost: (map['labor_cost'] as num?)?.toDouble(),
      serviceProvider: map['service_provider'] as String?,
      invoiceNumber: map['invoice_number'] as String?,
      priority: map['priority'] as String? ?? 'medium',
      status: map['status'] as String? ?? 'pending',
      partsUsed: map['parts_used'] as String?,
      nextMaintenanceDate: map['next_maintenance_date'] != null
          ? DateTime.parse(map['next_maintenance_date'] as String)
          : null,
      nextMaintenanceKm: map['next_maintenance_km'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
