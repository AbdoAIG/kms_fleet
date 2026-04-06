class Vehicle {
  final int? id;
  final String plateNumber;
  final String make;
  final String model;
  final int year;
  final String color;
  final String fuelType;
  final int currentOdometer;
  final String status;
  final String? driverName;
  final String? notes;
  final String? vehicleType;
  final int? passengerCapacity;
  final double? cargoCapacityTons;
  final String? purpose;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    this.id,
    required this.plateNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.fuelType,
    required this.currentOdometer,
    required this.status,
    this.driverName,
    this.notes,
    this.vehicleType,
    this.passengerCapacity,
    this.cargoCapacityTons,
    this.purpose,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Vehicle copyWith({
    int? id,
    String? plateNumber,
    String? make,
    String? model,
    int? year,
    String? color,
    String? fuelType,
    int? currentOdometer,
    String? status,
    String? driverName,
    String? notes,
    String? vehicleType,
    int? passengerCapacity,
    double? cargoCapacityTons,
    String? purpose,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      fuelType: fuelType ?? this.fuelType,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      notes: notes ?? this.notes,
      vehicleType: vehicleType ?? this.vehicleType,
      passengerCapacity: passengerCapacity ?? this.passengerCapacity,
      cargoCapacityTons: cargoCapacityTons ?? this.cargoCapacityTons,
      purpose: purpose ?? this.purpose,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plate_number': plateNumber,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'fuel_type': fuelType,
      'current_odometer': currentOdometer,
      'status': status,
      'driver_name': driverName,
      'notes': notes,
      'vehicle_type': vehicleType,
      'passenger_capacity': passengerCapacity,
      'cargo_capacity_tons': cargoCapacityTons,
      'purpose': purpose,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      plateNumber: map['plate_number'] as String? ?? '',
      make: map['make'] as String? ?? '',
      model: map['model'] as String? ?? '',
      year: map['year'] as int? ?? 2024,
      color: map['color'] as String? ?? '',
      fuelType: map['fuel_type'] as String? ?? 'petrol',
      currentOdometer: map['current_odometer'] as int? ?? 0,
      status: map['status'] as String? ?? 'active',
      driverName: map['driver_name'] as String?,
      notes: map['notes'] as String?,
      vehicleType: map['vehicle_type'] as String?,
      passengerCapacity: map['passenger_capacity'] as int?,
      cargoCapacityTons: (map['cargo_capacity_tons'] as num?)?.toDouble(),
      purpose: map['purpose'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  String get displayName => driverName != null && driverName!.isNotEmpty
      ? driverName!
      : '$make $model $year';
}
