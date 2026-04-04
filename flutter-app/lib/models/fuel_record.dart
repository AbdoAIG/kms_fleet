import 'vehicle.dart';

class FuelRecord {
  final int? id;
  final int vehicleId;
  final Vehicle? vehicle;
  final DateTime fillDate;
  final int odometerReading;
  final double liters;
  final double costPerLiter;
  final String fuelType;
  final String? stationName;
  final String? stationLocation;
  final bool fullTank;
  final String? notes;
  final double? consumptionRate;
  final bool? isAbnormal;
  final DateTime createdAt;
  final DateTime updatedAt;

  FuelRecord({
    this.id,
    required this.vehicleId,
    this.vehicle,
    required this.fillDate,
    required this.odometerReading,
    required this.liters,
    required this.costPerLiter,
    required this.fuelType,
    this.stationName,
    this.stationLocation,
    this.fullTank = true,
    this.notes,
    this.consumptionRate,
    this.isAbnormal,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  FuelRecord copyWith({
    int? id,
    int? vehicleId,
    Vehicle? vehicle,
    DateTime? fillDate,
    int? odometerReading,
    double? liters,
    double? costPerLiter,
    String? fuelType,
    String? stationName,
    String? stationLocation,
    bool? fullTank,
    String? notes,
    double? consumptionRate,
    bool? isAbnormal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FuelRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: vehicle ?? this.vehicle,
      fillDate: fillDate ?? this.fillDate,
      odometerReading: odometerReading ?? this.odometerReading,
      liters: liters ?? this.liters,
      costPerLiter: costPerLiter ?? this.costPerLiter,
      fuelType: fuelType ?? this.fuelType,
      stationName: stationName ?? this.stationName,
      stationLocation: stationLocation ?? this.stationLocation,
      fullTank: fullTank ?? this.fullTank,
      notes: notes ?? this.notes,
      consumptionRate: consumptionRate ?? this.consumptionRate,
      isAbnormal: isAbnormal ?? this.isAbnormal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get totalCost => liters * costPerLiter;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'fill_date': fillDate.toIso8601String(),
      'odometer_reading': odometerReading,
      'liters': liters,
      'cost_per_liter': costPerLiter,
      'fuel_type': fuelType,
      'station_name': stationName,
      'station_location': stationLocation,
      'full_tank': fullTank ? 1 : 0,
      'notes': notes,
      'consumption_rate': consumptionRate,
      'is_abnormal': isAbnormal ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FuelRecord.fromMap(Map<String, dynamic> map) {
    return FuelRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int? ?? 0,
      fillDate: map['fill_date'] != null
          ? DateTime.parse(map['fill_date'] as String)
          : DateTime.now(),
      odometerReading: map['odometer_reading'] as int? ?? 0,
      liters: (map['liters'] as num?)?.toDouble() ?? 0.0,
      costPerLiter: (map['cost_per_liter'] as num?)?.toDouble() ?? 0.0,
      fuelType: map['fuel_type'] as String? ?? 'petrol',
      stationName: map['station_name'] as String?,
      stationLocation: map['station_location'] as String?,
      fullTank: (map['full_tank'] as int?) == 1 ? true : false,
      notes: map['notes'] as String?,
      consumptionRate: (map['consumption_rate'] as num?)?.toDouble(),
      isAbnormal: (map['is_abnormal'] as int?) == 1 ? true : false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
