import 'dart:convert';
import 'vehicle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChecklistItem
// ─────────────────────────────────────────────────────────────────────────────

class ChecklistItem {
  final String title;
  final String description;
  final bool isChecked;
  final bool hasDefect;
  final String? defectNotes;
  final String? defectPhotoPath;

  ChecklistItem({
    required this.title,
    this.description = '',
    this.isChecked = false,
    this.hasDefect = false,
    this.defectNotes,
    this.defectPhotoPath,
  });

  ChecklistItem copyWith({
    String? title,
    String? description,
    bool? isChecked,
    bool? hasDefect,
    String? defectNotes,
    String? defectPhotoPath,
  }) {
    return ChecklistItem(
      title: title ?? this.title,
      description: description ?? this.description,
      isChecked: isChecked ?? this.isChecked,
      hasDefect: hasDefect ?? this.hasDefect,
      defectNotes: defectNotes ?? this.defectNotes,
      defectPhotoPath: defectPhotoPath ?? this.defectPhotoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'is_checked': isChecked,
      'has_defect': hasDefect,
      'defect_notes': defectNotes,
      'defect_photo_path': defectPhotoPath,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isChecked: map['is_checked'] as bool? ?? false,
      hasDefect: map['has_defect'] as bool? ?? false,
      defectNotes: map['defect_notes'] as String?,
      defectPhotoPath: map['defect_photo_path'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checklist
// ─────────────────────────────────────────────────────────────────────────────

class Checklist {
  final int? id;
  final int vehicleId;
  final Vehicle? vehicle;
  final String type;
  final DateTime inspectionDate;
  final int odometerReading;
  final List<ChecklistItem> items;
  final String? inspectorName;
  final String? signaturePath;
  final String? notes;
  final String status;
  final double overallScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  Checklist({
    this.id,
    required this.vehicleId,
    this.vehicle,
    required this.type,
    required this.inspectionDate,
    required this.odometerReading,
    required this.items,
    this.inspectorName,
    this.signaturePath,
    this.notes,
    required this.status,
    required this.overallScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Arabic display label for the checklist type.
  static String typeLabel(String type) {
    switch (type) {
      case 'pre_trip':
        return 'فحص ما قبل الرحلة';
      case 'post_trip':
        return 'فحص ما بعد الرحلة';
      case 'weekly':
        return 'فحص أسبوعي';
      default:
        return type;
    }
  }

  /// Number of items that were checked.
  int get checkedCount =>
      items.where((item) => item.isChecked).length;

  /// Number of items with reported defects.
  int get defectCount =>
      items.where((item) => item.hasDefect).length;

  /// Convenience: does this checklist have any defects?
  bool get hasDefects => defectCount > 0;

  // ── copyWith ─────────────────────────────────────────────────────────────

  Checklist copyWith({
    int? id,
    int? vehicleId,
    Vehicle? vehicle,
    String? type,
    DateTime? inspectionDate,
    int? odometerReading,
    List<ChecklistItem>? items,
    String? inspectorName,
    String? signaturePath,
    String? notes,
    String? status,
    double? overallScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Checklist(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: vehicle ?? this.vehicle,
      type: type ?? this.type,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      odometerReading: odometerReading ?? this.odometerReading,
      items: items ?? this.items,
      inspectorName: inspectorName ?? this.inspectorName,
      signaturePath: signaturePath ?? this.signaturePath,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      overallScore: overallScore ?? this.overallScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Serialization ────────────────────────────────────────────────────────

  /// Serialises the model to a map suitable for database storage.
  ///
  /// Checklist items are encoded as a JSON string under the `items` key.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'type': type,
      'inspection_date': inspectionDate.toIso8601String(),
      'odometer_reading': odometerReading,
      'items': jsonEncode(items.map((item) => item.toMap()).toList()),
      'inspector_name': inspectorName,
      'signature_path': signaturePath,
      'notes': notes,
      'status': status,
      'overall_score': overallScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Deserialises a map (e.g. from a database row) into a [Checklist].
  ///
  /// The `items` key is expected to be a JSON string of item maps.
  /// If parsing fails an empty list is used as a safe fallback.
  factory Checklist.fromMap(Map<String, dynamic> map) {
    List<ChecklistItem> parsedItems;

    try {
      final rawItems = map['items'];
      if (rawItems is String && rawItems.isNotEmpty) {
        final list = jsonDecode(rawItems) as List<dynamic>;
        parsedItems = list
            .map((e) => ChecklistItem.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        parsedItems = [];
      }
    } catch (_) {
      parsedItems = [];
    }

    return Checklist(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int? ?? 0,
      type: map['type'] as String? ?? 'pre_trip',
      inspectionDate: map['inspection_date'] != null
          ? DateTime.parse(map['inspection_date'] as String)
          : DateTime.now(),
      odometerReading: map['odometer_reading'] as int? ?? 0,
      items: parsedItems,
      inspectorName: map['inspector_name'] as String?,
      signaturePath: map['signature_path'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'pending',
      overallScore: (map['overall_score'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
