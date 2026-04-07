import 'dart:convert';
import 'vehicle.dart';

class TripPoint {
  final double lat;
  final double lng;
  final double? speed;
  final DateTime timestamp;

  TripPoint({
    required this.lat,
    required this.lng,
    this.speed,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TripPoint.fromMap(Map<String, dynamic> map) {
    return TripPoint(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

class TripTracking {
  final int? id;
  final int vehicleId;
  final Vehicle? vehicle;
  final String status; // active, completed, cancelled
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final String? startAddress;
  final String? endAddress;
  final double distanceKm;
  final double durationMinutes;
  final int? startOdometer;
  final int? endOdometer;
  final String? notes;
  final String? tripPointsJson; // JSON encoded list of TripPoint maps
  final String? driverName;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripTracking({
    this.id,
    required this.vehicleId,
    this.vehicle,
    required this.status,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.startAddress,
    this.endAddress,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.startOdometer,
    this.endOdometer,
    this.notes,
    this.tripPointsJson,
    this.driverName,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TripTracking copyWith({
    int? id,
    int? vehicleId,
    Vehicle? vehicle,
    String? status,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    String? startAddress,
    String? endAddress,
    double? distanceKm,
    double? durationMinutes,
    int? startOdometer,
    int? endOdometer,
    String? notes,
    String? tripPointsJson,
    String? driverName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripTracking(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: vehicle ?? this.vehicle,
      status: status ?? this.status,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      startAddress: startAddress ?? this.startAddress,
      endAddress: endAddress ?? this.endAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startOdometer: startOdometer ?? this.startOdometer,
      endOdometer: endOdometer ?? this.endOdometer,
      notes: notes ?? this.notes,
      tripPointsJson: tripPointsJson ?? this.tripPointsJson,
      driverName: driverName ?? this.driverName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Computed getters ──

  String get statusLabel {
    switch (status) {
      case 'active': return 'جارية';
      case 'completed': return 'مكتملة';
      case 'cancelled': return 'ملغاة';
      default: return status;
    }
  }

  bool get isActive => status == 'active';

  String get formattedDistance {
    if (distanceKm == 0) return '0 كم';
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} م';
    }
    return '${distanceKm.toStringAsFixed(1)} كم';
  }

  String get formattedDuration {
    if (durationMinutes == 0) return '0 دقيقة';
    final hours = durationMinutes ~/ 60;
    final minutes = (durationMinutes % 60).round();
    if (hours == 0) return '$minutes دقيقة';
    if (minutes == 0) return '$hours ساعة';
    return '$hours ساعة $minutes دقيقة';
  }

  List<TripPoint> get tripPoints {
    if (tripPointsJson == null || tripPointsJson!.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(tripPointsJson!);
      return decoded.map((e) => TripPoint.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Serialization ──

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'status': status,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'start_address': startAddress,
      'end_address': endAddress,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'start_odometer': startOdometer,
      'end_odometer': endOdometer,
      'notes': notes,
      'trip_points_json': tripPointsJson,
      'driver_name': driverName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TripTracking.fromMap(Map<String, dynamic> map) {
    return TripTracking(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int? ?? 0,
      status: map['status'] as String? ?? 'active',
      startLat: (map['start_lat'] as num?)?.toDouble(),
      startLng: (map['start_lng'] as num?)?.toDouble(),
      endLat: (map['end_lat'] as num?)?.toDouble(),
      endLng: (map['end_lng'] as num?)?.toDouble(),
      startAddress: map['start_address'] as String?,
      endAddress: map['end_address'] as String?,
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
      durationMinutes: (map['duration_minutes'] as num?)?.toDouble() ?? 0,
      startOdometer: map['start_odometer'] as int?,
      endOdometer: map['end_odometer'] as int?,
      notes: map['notes'] as String?,
      tripPointsJson: map['trip_points_json'] as String?,
      driverName: map['driver_name'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
