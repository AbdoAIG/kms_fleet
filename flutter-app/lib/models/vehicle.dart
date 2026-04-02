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
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  String get displayName => '$make $model $year';
}
