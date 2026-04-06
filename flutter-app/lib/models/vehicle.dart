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
  final String? notes;
  final String? vehicleType;
  final int? passengerCapacity;
  final double? cargoCapacityTons;
  final String? purpose;

  // ── Driver fields (merged from Driver model) ──
  final String? driverName;
  final String? driverPhone;
  final String? driverLicenseNumber;
  final DateTime? driverLicenseExpiry;
  final String? driverStatus; // active / suspended

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
    this.notes,
    this.vehicleType,
    this.passengerCapacity,
    this.cargoCapacityTons,
    this.purpose,
    this.driverName,
    this.driverPhone,
    this.driverLicenseNumber,
    this.driverLicenseExpiry,
    this.driverStatus,
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
    String? notes,
    String? vehicleType,
    int? passengerCapacity,
    double? cargoCapacityTons,
    String? purpose,
    String? driverName,
    String? driverPhone,
    String? driverLicenseNumber,
    DateTime? driverLicenseExpiry,
    String? driverStatus,
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
      notes: notes ?? this.notes,
      vehicleType: vehicleType ?? this.vehicleType,
      passengerCapacity: passengerCapacity ?? this.passengerCapacity,
      cargoCapacityTons: cargoCapacityTons ?? this.cargoCapacityTons,
      purpose: purpose ?? this.purpose,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      driverLicenseExpiry: driverLicenseExpiry ?? this.driverLicenseExpiry,
      driverStatus: driverStatus ?? this.driverStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasDriver => driverName != null && driverName!.isNotEmpty;

  /// Always shows the vehicle make/model/year.
  String get displayName => '$make $model $year';

  /// The driver name or empty string.
  String get driverDisplayName => hasDriver ? driverName! : '';

  /// The vehicle type label from constants.
  String get vehicleTypeLabel => vehicleType != null && vehicleType!.isNotEmpty
      ? vehicleType!
      : '';

  /// A short display label combining make + model.
  String get shortName => '$make $model';

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
      'notes': notes,
      'vehicle_type': vehicleType,
      'passenger_capacity': passengerCapacity,
      'cargo_capacity_tons': cargoCapacityTons,
      'purpose': purpose,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_license_number': driverLicenseNumber,
      'driver_license_expiry': driverLicenseExpiry?.toIso8601String(),
      'driver_status': driverStatus,
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
      notes: map['notes'] as String?,
      vehicleType: map['vehicle_type'] as String?,
      passengerCapacity: map['passenger_capacity'] as int?,
      cargoCapacityTons: (map['cargo_capacity_tons'] as num?)?.toDouble(),
      purpose: map['purpose'] as String?,
      driverName: map['driver_name'] as String?,
      driverPhone: map['driver_phone'] as String?,
      driverLicenseNumber: map['driver_license_number'] as String?,
      driverLicenseExpiry: map['driver_license_expiry'] != null
          ? DateTime.parse(map['driver_license_expiry'] as String)
          : null,
      driverStatus: map['driver_status'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
