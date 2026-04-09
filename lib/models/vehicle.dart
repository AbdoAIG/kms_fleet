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
  final String? vin;
  final String? engineNumber;
  final String? vehicleCategory;
  final String? department;
  final String? driverName;
  final String? driverPhone;
  final String? driverLicense;
  final String? driverLicenseExpiry;
  final String? insuranceNumber;
  final String? insuranceExpiry;
  final String? registrationExpiry;
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
    this.vin,
    this.engineNumber,
    this.vehicleCategory,
    this.department,
    this.driverName,
    this.driverPhone,
    this.driverLicense,
    this.driverLicenseExpiry,
    this.insuranceNumber,
    this.insuranceExpiry,
    this.registrationExpiry,
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
    String? vin,
    String? engineNumber,
    String? vehicleCategory,
    String? department,
    String? driverName,
    String? driverPhone,
    String? driverLicense,
    String? driverLicenseExpiry,
    String? insuranceNumber,
    String? insuranceExpiry,
    String? registrationExpiry,
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
      vin: vin ?? this.vin,
      engineNumber: engineNumber ?? this.engineNumber,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      department: department ?? this.department,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverLicense: driverLicense ?? this.driverLicense,
      driverLicenseExpiry: driverLicenseExpiry ?? this.driverLicenseExpiry,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
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
      'notes': notes,
      'vin': vin,
      'engine_number': engineNumber,
      'vehicle_category': vehicleCategory,
      'department': department,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_license': driverLicense,
      'driver_license_expiry': driverLicenseExpiry,
      'insurance_number': insuranceNumber,
      'insurance_expiry': insuranceExpiry,
      'registration_expiry': registrationExpiry,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    // Helper للتحويل الآمن بين الأنواع
    int? toInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) : null);
    String? toString(dynamic v) => v?.toString();

    return Vehicle(
      id: toInt(map['id']),
      plateNumber: toString(map['plate_number']) ?? '',
      make: toString(map['make']) ?? '',
      model: toString(map['model']) ?? '',
      year: toInt(map['year']) ?? 2024,
      color: toString(map['color']) ?? '',
      fuelType: toString(map['fuel_type']) ?? 'petrol',
      currentOdometer: toInt(map['current_odometer']) ?? 0,
      status: toString(map['status']) ?? 'active',
      notes: toString(map['notes']),
      vin: toString(map['vin']),
      engineNumber: toString(map['engine_number']),
      vehicleCategory: toString(map['vehicle_category']) ?? 'light',
      department: toString(map['department']),
      driverName: toString(map['driver_name']),
      driverPhone: toString(map['driver_phone']),
      driverLicense: toString(map['driver_license']),
      driverLicenseExpiry: toString(map['driver_license_expiry']),
      insuranceNumber: toString(map['insurance_number']),
      insuranceExpiry: toString(map['insurance_expiry']),
      registrationExpiry: toString(map['registration_expiry']),
      createdAt: map['created_at'] != null
          ? (map['created_at'] is DateTime
              ? map['created_at'] as DateTime
              : DateTime.tryParse(toString(map['created_at'])!) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? (map['updated_at'] is DateTime
              ? map['updated_at'] as DateTime
              : DateTime.tryParse(toString(map['updated_at'])!) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  String get displayName => '$make $model $year';
}
