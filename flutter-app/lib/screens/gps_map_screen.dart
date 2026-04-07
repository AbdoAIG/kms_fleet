import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/trip_tracking.dart';
import '../providers/vehicle_provider.dart';
import '../providers/trip_tracking_provider.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_widget.dart';
import 'trip_history_screen.dart';

class GpsMapScreen extends StatefulWidget {
  const GpsMapScreen({super.key});

  @override
  State<GpsMapScreen> createState() => _GpsMapScreenState();
}

class _GpsMapScreenState extends State<GpsMapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  bool _isLoading = true;
  bool _isGettingLocation = false;
  String? _error;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tripProvider =
          Provider.of<TripTrackingProvider>(context, listen: false);
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);

      await vehicleProvider.loadVehicles();
      await tripProvider.loadTrips();

      _buildMarkers(vehicleProvider.allVehicles, tripProvider.trips);
      _getCurrentLocation();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _buildMarkers(List<Vehicle> vehicles, List<TripTracking> trips) {
    final markers = <Marker>[];
    final polylines = <Polyline>[];

    // Show last completed trip per vehicle
    final Map<int, TripTracking> latestByVehicle = {};
    for (final trip in trips) {
      if (trip.status == 'completed' &&
          (trip.startLat != null && trip.startLng != null)) {
        latestByVehicle[trip.vehicleId] = trip;
      }
    }

    if (latestByVehicle.isEmpty) {
      setState(() {
        _markers = markers;
        _polylines = polylines;
      });
      return;
    }

    for (final entry in latestByVehicle.entries) {
      final trip = entry.value;
      final vehicle =
          vehicles.where((v) => v.id == trip.vehicleId).firstOrNull;
      final plateNumber =
          vehicle?.plateNumber ?? 'سيارة #${trip.vehicleId}';

      // Use end position as "last known location" marker
      final endLat = trip.endLat ?? trip.startLat!;
      final endLng = trip.endLng ?? trip.startLng!;

      markers.add(
        Marker(
          point: LatLng(endLat, endLng),
          width: 180,
          height: 60,
          child: _VehicleMarker(
            plateNumber: plateNumber,
            vehicleName:
                vehicle != null ? '${vehicle.make} ${vehicle.model}' : '',
            onTap: () => _showVehicleBottomSheet(trip, vehicle),
          ),
        ),
      );

      // Draw route polyline if we have start and end
      if (trip.startLat != null &&
          trip.startLng != null &&
          trip.endLat != null &&
          trip.endLng != null &&
          (trip.startLat != trip.endLat || trip.startLng != trip.endLng)) {
        // If we have detailed trip points, use them
        if (trip.tripPoints.length >= 2) {
          final routePoints = trip.tripPoints
              .map((p) => LatLng(p.lat, p.lng))
              .toList();
          polylines.add(
            Polyline(
              points: routePoints,
              color: AppColors.primary.withOpacity(0.6),
              strokeWidth: 3,
            ),
          );
        } else {
          // Otherwise draw a straight line
          polylines.add(
            Polyline(
              points: [
                LatLng(trip.startLat!, trip.startLng!),
                LatLng(trip.endLat!, trip.endLng!),
              ],
              color: AppColors.primary.withOpacity(0.4),
              strokeWidth: 3,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _polylines = polylines;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isGettingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isGettingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _zoomToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15);
    } else {
      _getCurrentLocation().then((_) {
        if (_currentPosition != null) {
          _mapController.move(_currentPosition!, 15);
        }
      });
    }
  }

  void _showVehicleBottomSheet(TripTracking trip, Vehicle? vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Vehicle header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle?.displayName ??
                              'سيارة #${trip.vehicleId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vehicle?.plateNumber ??
                                'سيارة #${trip.vehicleId}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trip.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: trip.status == 'completed'
                            ? AppColors.success
                            : trip.status == 'active'
                                ? AppColors.info
                                : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Trip stats row
            Row(
              children: [
                Expanded(
                  child: _BottomSheetStat(
                    icon: Icons.straighten,
                    label: 'المسافة',
                    value: trip.formattedDistance,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BottomSheetStat(
                    icon: Icons.access_time,
                    label: 'المدة',
                    value: trip.formattedDuration,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Start/End info
            Row(
              children: [
                Expanded(
                  child: _BottomSheetStat(
                    icon: Icons.play_circle,
                    label: 'من',
                    value: trip.startAddress ??
                        '(${trip.startLat?.toStringAsFixed(3) ?? '-'}، ${trip.startLng?.toStringAsFixed(3) ?? '-'})',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BottomSheetStat(
                    icon: Icons.stop_circle,
                    label: 'إلى',
                    value: trip.endAddress ??
                        (trip.endLat != null
                            ? '(${trip.endLat!.toStringAsFixed(3)}، ${trip.endLng!.toStringAsFixed(3)})'
                            : 'غير محدد'),
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppFormatters.formatDateTime(trip.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // View history button
            if (vehicle != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TripHistoryScreen(vehicle: vehicle),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('سجل الرحلات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع السيارات'),
        actions: [
          if (_isGettingLocation)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'حدث خطأ في تحميل البيانات',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          : _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                )
              : _markers.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.map_outlined,
                      title: 'لا توجد رحلات مسجلة',
                      subtitle:
                          'قم بتسجيل رحلة جديدة لتظهر موقع السيارات على الخريطة',
                    )
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: const LatLng(30.0444, 31.2357),
                            initialZoom: 10,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.kms_fleet',
                            ),
                            PolylineLayer(polylines: _polylines),
                            MarkerLayer(markers: _markers),
                            if (_currentPosition != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _currentPosition!,
                                    width: 40,
                                    height: 40,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.info,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.info
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.my_location,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _zoomToCurrentLocation,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}

// ── Vehicle Marker Widget ──────────────────────────────────────────────────

class _VehicleMarker extends StatelessWidget {
  final String plateNumber;
  final String vehicleName;
  final VoidCallback? onTap;

  const _VehicleMarker({
    required this.plateNumber,
    this.vehicleName = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plateNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (vehicleName.isNotEmpty)
                    Text(
                      vehicleName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 9,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Sheet Stat Widget ───────────────────────────────────────────────

class _BottomSheetStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BottomSheetStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
