import 'driver.dart';
import 'vehicle.dart';

class DriverViolation {
  final int? id;
  final int driverId;
  final int? vehicleId;
  final Driver? driver;
  final Vehicle? vehicle;
  final String type;
  final double amount;
  final DateTime date;
  final String description;
  final int points;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverViolation({
    this.id,
    required this.driverId,
    this.vehicleId,
    this.driver,
    this.vehicle,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    required this.points,
    required this.status,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DriverViolation copyWith({
    int? id,
    int? driverId,
    int? vehicleId,
    Driver? driver,
    Vehicle? vehicle,
    String? type,
    double? amount,
    DateTime? date,
    String? description,
    int? points,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverViolation(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      driver: driver ?? this.driver,
      vehicle: vehicle ?? this.vehicle,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      points: points ?? this.points,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'points': points,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DriverViolation.fromMap(Map<String, dynamic> map) {
    return DriverViolation(
      id: map['id'] as int?,
      driverId: map['driver_id'] as int? ?? 0,
      vehicleId: map['vehicle_id'] as int?,
      type: map['type'] as String? ?? 'other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      description: map['description'] as String? ?? '',
      points: map['points'] as int? ?? 0,
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
