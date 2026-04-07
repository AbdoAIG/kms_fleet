import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/trip_tracking.dart';
import '../providers/trip_tracking_provider.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_widget.dart';
import 'trip_tracking_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  final Vehicle vehicle;

  const TripHistoryScreen({super.key, required this.vehicle});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeFilter = 'all'; // all, active, completed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        setState(() => _activeFilter = 'all');
        break;
      case 1:
        setState(() => _activeFilter = 'active');
        break;
      case 2:
        setState(() => _activeFilter = 'completed');
        break;
    }
  }

  Future<void> _loadTrips() async {
    final tripProvider =
        Provider.of<TripTrackingProvider>(context, listen: false);
    await tripProvider.loadTripsByVehicleId(widget.vehicle.id ?? 0);
  }

  List<TripTracking> get _filteredTrips {
    final provider = context.watch<TripTrackingProvider>();
    switch (_activeFilter) {
      case 'active':
        return provider.vehicleTrips
            .where((t) => t.status == 'active')
            .toList();
      case 'completed':
        return provider.vehicleTrips
            .where((t) => t.status == 'completed')
            .toList();
      default:
        return provider.vehicleTrips;
    }
  }

  void _showRouteDialog(TripTracking trip) {
    final hasRoute = trip.startLat != null &&
        trip.startLng != null &&
        trip.endLat != null &&
        trip.endLng != null;

    if (!hasRoute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد بيانات كافية لعرض المسار'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final routePoints = <LatLng>[];

    // Use detailed trip points if available
    if (trip.tripPoints.length >= 2) {
      for (final p in trip.tripPoints) {
        routePoints.add(LatLng(p.lat, p.lng));
      }
    } else {
      // Otherwise use start and end
      routePoints.add(LatLng(trip.startLat!, trip.startLng!));
      routePoints.add(LatLng(trip.endLat!, trip.endLng!));
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.route,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مسار الرحلة',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Trip info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _RouteInfoChip(
                        icon: Icons.straighten,
                        label: trip.formattedDistance,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RouteInfoChip(
                        icon: Icons.access_time,
                        label: trip.formattedDuration,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RouteInfoChip(
                        icon: Icons.calendar_today,
                        label: AppFormatters.formatDate(trip.createdAt),
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
              // Map
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        (trip.startLat! + trip.endLat!) / 2,
                        (trip.startLng! + trip.endLng!) / 2,
                      ),
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.kms_fleet',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: AppColors.primary,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // Start marker
                          Marker(
                            point: LatLng(trip.startLat!, trip.startLng!),
                            width: 36,
                            height: 36,
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
                                size: 18,
                              ),
                            ),
                          ),
                          // End marker
                          Marker(
                            point: LatLng(trip.endLat!, trip.endLng!),
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.stop,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = _filteredTrips;
    final provider = context.watch<TripTrackingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الرحلات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            tooltip: 'تسجيل رحلة جديدة',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TripTrackingScreen(vehicle: widget.vehicle),
                ),
              );
              if (result == true) _loadTrips();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'الكل'),
                Tab(text: 'نشطة'),
                Tab(text: 'مكتملة'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Trips list
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  )
                : trips.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.route_outlined,
                        title: 'لا توجد رحلات',
                        subtitle: _activeFilter == 'all'
                            ? 'لم يتم تسجيل أي رحلة لهذه السيارة بعد'
                            : _activeFilter == 'active'
                                ? 'لا توجد رحلات جارية حالياً'
                                : 'لا توجد رحلات مكتملة',
                        actionText: 'تسجيل رحلة جديدة',
                        onAction: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripTrackingScreen(
                                  vehicle: widget.vehicle),
                            ),
                          );
                          if (result == true) _loadTrips();
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTrips,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: trips.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _TripCard(
                            trip: trips[index],
                            onTap: () => _showRouteDialog(trips[index]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Trip Card Widget ────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final TripTracking trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(trip.status);
    final statusLabel = trip.statusLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header row: status + date
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(trip.status),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppFormatters.formatDate(trip.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Route info: start → end
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.play_arrow,
                                  color: AppColors.success, size: 14),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                trip.startAddress ??
                                    '(${trip.startLat?.toStringAsFixed(3) ?? '-'}, ${trip.startLng?.toStringAsFixed(3) ?? '-'})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.stop,
                                  color: AppColors.error, size: 14),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                trip.endAddress ??
                                    (trip.endLat != null
                                        ? '(${trip.endLat!.toStringAsFixed(3)}, ${trip.endLng!.toStringAsFixed(3)})'
                                        : 'جارية...'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _TripStatItem(
                    icon: Icons.straighten,
                    label: trip.formattedDistance,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 16),
                  _TripStatItem(
                    icon: Icons.access_time,
                    label: trip.formattedDuration,
                    color: AppColors.accent,
                  ),
                  const Spacer(),
                  if (trip.notes != null && trip.notes!.isNotEmpty)
                    const Icon(Icons.note,
                        size: 16, color: AppColors.textHint),
                  if (trip.status == 'completed')
                    const Icon(Icons.route,
                        size: 16, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

// ── Trip Stat Item ─────────────────────────────────────────────────────────

class _TripStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TripStatItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Route Info Chip (for dialog) ───────────────────────────────────────────

class _RouteInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RouteInfoChip({
    required this.icon,
    required this.label,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
