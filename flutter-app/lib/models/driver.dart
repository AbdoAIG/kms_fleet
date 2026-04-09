class Driver {
  final int? id;
  final String name;
  final String phone;
  final String licenseNumber;
  final DateTime? licenseExpiryDate;
  final String status;
  final String? photoPath;
  final int? vehicleId;
  final DateTime? assignedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    this.id,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    this.licenseExpiryDate,
    required this.status,
    this.photoPath,
    this.vehicleId,
    this.assignedDate,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Driver copyWith({
    int? id,
    String? name,
    String? phone,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    String? status,
    String? photoPath,
    int? vehicleId,
    DateTime? assignedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      status: status ?? this.status,
      photoPath: photoPath ?? this.photoPath,
      vehicleId: vehicleId ?? this.vehicleId,
      assignedDate: assignedDate ?? this.assignedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName => name;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'license_number': licenseNumber,
      'license_expiry_date': licenseExpiryDate?.toIso8601String(),
      'status': status,
      'photo_path': photoPath,
      'vehicle_id': vehicleId,
      'assigned_date': assignedDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      licenseNumber: map['license_number'] as String? ?? '',
      licenseExpiryDate: map['license_expiry_date'] != null
          ? DateTime.parse(map['license_expiry_date'] as String)
          : null,
      status: map['status'] as String? ?? 'active',
      photoPath: map['photo_path'] as String?,
      vehicleId: map['vehicle_id'] as int?,
      assignedDate: map['assigned_date'] != null
          ? DateTime.parse(map['assigned_date'] as String)
          : null,
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
