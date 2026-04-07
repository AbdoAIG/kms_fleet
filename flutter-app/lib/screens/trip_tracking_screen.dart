import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/trip_tracking.dart';
import '../providers/trip_tracking_provider.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';

class TripTrackingScreen extends StatefulWidget {
  final Vehicle vehicle;

  const TripTrackingScreen({super.key, required this.vehicle});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  bool _isSaving = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Trip data
  final List<TripPoint> _points = [];
  double _totalDistance = 0.0; // km
  Duration _duration = Duration.zero;
  double _currentSpeed = 0.0; // km/h
  String _currentCoords = '--';
  DateTime? _startTime;
  LatLng? _currentPosition;
  Timer? _durationTimer;

  // Polyline
  final List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _stopTracking();
    _durationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _hasError = true;
          _errorMessage = 'خدمة الموقع غير مفعلة. يرجى تفعيلها من إعدادات الجهاز.';
        });
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _hasError = true;
            _errorMessage = 'تم رفض إذن الموقع. لا يمكن تتبع الرحلة.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _hasError = true;
          _errorMessage = 'تم رفض إذن الموقع نهائياً. يرجى تفعيله من إعدادات التطبيق.';
        });
        return;
      }

      // Get initial position
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      if (!mounted) return;

      _startTime = DateTime.now();
      _currentPosition =
          LatLng(initialPosition.latitude, initialPosition.longitude);
      _routePoints.add(_currentPosition!);
      _currentCoords =
          '${initialPosition.latitude.toStringAsFixed(5)}, ${initialPosition.longitude.toStringAsFixed(5)}';

      _points.add(TripPoint(
        lat: initialPosition.latitude,
        lng: initialPosition.longitude,
        speed: initialPosition.speed,
        timestamp: DateTime.now(),
      ));

      _mapController.move(_currentPosition!, 16);

      // Start tracking stream (every 3 seconds)
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        _onPositionUpdate,
        onError: (error) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'خطأ في تتبع الموقع: ${error.toString()}';
            });
          }
        },
      );

      // Start duration timer (update every second)
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_startTime != null && mounted) {
          setState(() {
            _duration = DateTime.now().difference(_startTime!);
          });
        }
      });

      setState(() => _isTracking = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'حدث خطأ أثناء بدء التتبع: ${e.toString()}';
        });
      }
    }
  }

  void _onPositionUpdate(Position position) {
    if (!mounted || !_isTracking) return;

    final newPoint = LatLng(position.latitude, position.longitude);
    final newSpeedKmh = position.speed * 3.6;

    // Calculate distance from last point
    if (_points.isNotEmpty) {
      final lastPoint = _points.last;
      final distance = _calculateDistance(
        lastPoint.lat,
        lastPoint.lng,
        position.latitude,
        position.longitude,
      );

      // Only add point if moved more than 5 meters
      if (distance * 1000 >= 5) {
        setState(() {
          _totalDistance += distance;
          _currentSpeed = newSpeedKmh;
          _currentPosition = newPoint;
          _currentCoords =
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
          _routePoints.add(newPoint);
        });

        _points.add(TripPoint(
          lat: position.latitude,
          lng: position.longitude,
          speed: position.speed,
          timestamp: DateTime.now(),
        ));

        // Pan map to current position
        _mapController.move(newPoint, _mapController.camera.zoom);
      } else {
        // Still update speed even if not moving significantly
        setState(() => _currentSpeed = newSpeedKmh);
      }
    }
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    if (mounted) setState(() => _isTracking = false);
  }

  Future<void> _endTrip() async {
    // Prompt for end odometer reading
    final odometerController = TextEditingController(
      text: widget.vehicle.currentOdometer.toString(),
    );

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('إنهاء الرحلة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل قراءة العداد الحالية:'),
            const SizedBox(height: 16),
            TextField(
              controller: odometerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'قراءة العداد (كم)',
                prefixIcon: Icon(Icons.speed),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'المسافة المقطوعة: ${_totalDistance.toStringAsFixed(1)} كم',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(odometerController.text);
              Navigator.pop(context, val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _isSaving = true);
    _stopTracking();

    try {
      final firstPoint = _points.isNotEmpty ? _points.first : null;
      final lastPoint = _points.isNotEmpty ? _points.last : null;

      final trip = TripTracking(
        vehicleId: widget.vehicle.id ?? 0,
        status: 'completed',
        startLat: firstPoint?.lat,
        startLng: firstPoint?.lng,
        endLat: lastPoint?.lat,
        endLng: lastPoint?.lng,
        distanceKm: _totalDistance,
        durationMinutes: _duration.inMinutes.toDouble(),
        startOdometer: widget.vehicle.currentOdometer,
        endOdometer: result,
        driverName: widget.vehicle.driverName,
        tripPointsJson: jsonEncode(
          _points.map((p) => p.toMap()).toList(),
        ),
      );

      final tripProvider =
          Provider.of<TripTrackingProvider>(context, listen: false);
      await tripProvider.saveTrip(trip);

      if (mounted) {
        AppHelpers.showSnackBar(context, 'تم حفظ الرحلة بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء حفظ الرحلة',
          isError: true,
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _cancelTrip() async {
    final confirmed = await AppHelpers.showConfirmDialog(
      context,
      title: 'إلغاء الرحلة',
      message: 'هل أنت متأكد من إلغاء الرحلة الحالية؟ سيتم حذف جميع البيانات المسجلة.',
      confirmText: 'إلغاء الرحلة',
      cancelText: 'الاستمرار في التتبع',
      isDestructive: true,
    );

    if (confirmed) {
      _stopTracking();
      if (mounted) Navigator.pop(context, false);
    }
  }

  // ── Haversine Distance ──────────────────────────────────────────────────

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  // ── Formatting helpers ──────────────────────────────────────────────────

  String get _formattedDistance {
    if (_totalDistance < 1) {
      return '${(_totalDistance * 1000).toStringAsFixed(0)} م';
    }
    return '${_totalDistance.toStringAsFixed(2)} كم';
  }

  String get _formattedDuration {
    final hours = _duration.inHours;
    final minutes = _duration.inMinutes.remainder(60);
    final seconds = _duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _formattedSpeed => '${_currentSpeed.toStringAsFixed(0)} كم/س';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل رحلة جديدة'),
        actions: [
          if (_isTracking)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'جاري التتبع',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_off,
                        color: AppColors.error, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'خطأ في تتبع الموقع',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorMessage = '';
                        });
                        _startTracking();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition ??
                        const LatLng(30.0444, 31.2357),
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.kms_fleet',
                    ),
                    PolylineLayer(
                      polylines: [
                        if (_routePoints.length >= 2)
                          Polyline(
                            points: _routePoints,
                            color: AppColors.primary,
                            strokeWidth: 5,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentPosition != null)
                          Marker(
                            point: _currentPosition!,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        // Start marker
                        if (_routePoints.isNotEmpty)
                          Marker(
                            point: _routePoints.first,
                            width: 28,
                            height: 28,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Stats overlay panel (top)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: SafeArea(
                        bottom: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Vehicle info
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.vehicle.plateNumber,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${widget.vehicle.make} ${widget.vehicle.model}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Stats grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _TrackingStat(
                                      icon: Icons.straighten,
                                      label: 'المسافة',
                                      value: _formattedDistance,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _TrackingStat(
                                      icon: Icons.timer,
                                      label: 'المدة',
                                      value: _formattedDuration,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _TrackingStat(
                                      icon: Icons.speed,
                                      label: 'السرعة',
                                      value: _formattedSpeed,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Current location
                              Row(
                                children: [
                                  const Icon(Icons.place,
                                      color: AppColors.textHint, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _currentCoords,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textHint,
                                        fontFamily: 'monospace',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                // Bottom action buttons
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.95),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor,
                                blurRadius: 12,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: _isSaving
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'جاري حفظ الرحلة...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    // Cancel button
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _cancelTrip,
                                        icon: const Icon(Icons.close, size: 20),
                                        label: const Text('إلغاء'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(
                                              color: AppColors.error),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // End trip button
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: _endTrip,
                                        icon: const Icon(
                                            Icons.check_circle, size: 20),
                                        label: const Text('إنهاء الرحلة'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}

// ── Tracking Stat Widget ───────────────────────────────────────────────────

class _TrackingStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TrackingStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
