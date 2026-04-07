import 'vehicle.dart';

class Expense {
  final int? id;
  final int vehicleId;
  final Vehicle? vehicle;
  final String type;
  final double amount;
  final DateTime date;
  final String description;
  final String? serviceProvider;
  final String? invoiceNumber;
  final int? odometerReading;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    this.id,
    required this.vehicleId,
    this.vehicle,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    this.serviceProvider,
    this.invoiceNumber,
    this.odometerReading,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Expense copyWith({
    int? id,
    int? vehicleId,
    Vehicle? vehicle,
    String? type,
    double? amount,
    DateTime? date,
    String? description,
    String? serviceProvider,
    String? invoiceNumber,
    int? odometerReading,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: vehicle ?? this.vehicle,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      serviceProvider: serviceProvider ?? this.serviceProvider,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      odometerReading: odometerReading ?? this.odometerReading,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'service_provider': serviceProvider,
      'invoice_number': invoiceNumber,
      'odometer_reading': odometerReading,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int? ?? 0,
      type: map['type'] as String? ?? 'miscellaneous',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      description: map['description'] as String? ?? '',
      serviceProvider: map['service_provider'] as String?,
      invoiceNumber: map['invoice_number'] as String?,
      odometerReading: map['odometer_reading'] as int?,
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
