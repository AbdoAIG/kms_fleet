import 'vehicle.dart';

class WorkOrder {
  final int? id;
  final int vehicleId;
  final Vehicle? vehicle;
  final String type; // maintenance, repair, inspection
  final String status; // open, in_progress, completed
  final String? description;
  final String? technicianName;
  final String? technicianPhone;
  final double? estimatedCost;
  final double? actualCost;
  final String priority; // low, medium, high, urgent
  final DateTime? startDate;
  final DateTime? completedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkOrder({
    this.id,
    required this.vehicleId,
    this.vehicle,
    required this.type,
    required this.status,
    this.description,
    this.technicianName,
    this.technicianPhone,
    this.estimatedCost,
    this.actualCost,
    this.priority = 'medium',
    this.startDate,
    this.completedDate,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  WorkOrder copyWith({
    int? id,
    int? vehicleId,
    Vehicle? vehicle,
    String? type,
    String? status,
    String? description,
    String? technicianName,
    String? technicianPhone,
    double? estimatedCost,
    double? actualCost,
    String? priority,
    DateTime? startDate,
    DateTime? completedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkOrder(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: vehicle ?? this.vehicle,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      technicianName: technicianName ?? this.technicianName,
      technicianPhone: technicianPhone ?? this.technicianPhone,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      completedDate: completedDate ?? this.completedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'maintenance': return 'صيانة';
      case 'repair': return 'إصلاح';
      case 'inspection': return 'فحص';
      default: return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'open': return 'مفتوح';
      case 'in_progress': return 'قيد التنفيذ';
      case 'completed': return 'مكتمل';
      default: return status;
    }
  }

  double get totalCost => actualCost ?? estimatedCost ?? 0;

  double get costVariance {
    if (estimatedCost == null || actualCost == null) return 0;
    return actualCost! - estimatedCost!;
  }

  bool get isOverBudget => costVariance > 0 && estimatedCost != null && estimatedCost! > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'type': type,
      'status': status,
      'description': description,
      'technician_name': technicianName,
      'technician_phone': technicianPhone,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'priority': priority,
      'start_date': startDate?.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WorkOrder.fromMap(Map<String, dynamic> map) {
    return WorkOrder(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int? ?? 0,
      type: map['type'] as String? ?? 'maintenance',
      status: map['status'] as String? ?? 'open',
      description: map['description'] as String?,
      technicianName: map['technician_name'] as String?,
      technicianPhone: map['technician_phone'] as String?,
      estimatedCost: (map['estimated_cost'] as num?)?.toDouble(),
      actualCost: (map['actual_cost'] as num?)?.toDouble(),
      priority: map['priority'] as String? ?? 'medium',
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date'] as String) : null,
      completedDate: map['completed_date'] != null ? DateTime.parse(map['completed_date'] as String) : null,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
    );
  }
}
