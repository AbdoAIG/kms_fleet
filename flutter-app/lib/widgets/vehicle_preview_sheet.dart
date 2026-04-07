import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/vehicle_type_config.dart';

/// Shows a bottom sheet with 3D vehicle model preview and quick info.
void showVehiclePreviewSheet(BuildContext context, {
  required Vehicle vehicle,
  VoidCallback? onEdit,
  VoidCallback? onMaintenance,
  VoidCallback? onDetails,
}) {
  final config = getVehicleTypeConfig(vehicle.vehicleType);
  final statusLabel = AppConstants.vehicleStatuses[vehicle.status] ?? vehicle.status;
  final statusColor = AppConstants.vehicleStatusColors[vehicle.status] ?? AppColors.textHint;
  final colorLabel = AppConstants.vehicleColors[vehicle.color] ?? vehicle.color;
  final fuelLabel = AppConstants.fuelTypes[vehicle.fuelType] ?? vehicle.fuelType;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _VehiclePreviewSheetContent(
      vehicle: vehicle,
      config: config,
      statusLabel: statusLabel,
      statusColor: statusColor,
      colorLabel: colorLabel,
      fuelLabel: fuelLabel,
      onEdit: onEdit,
      onMaintenance: onMaintenance,
      onDetails: onDetails,
    ),
  );
}

class _VehiclePreviewSheetContent extends StatelessWidget {
  final Vehicle vehicle;
  final VehicleTypeConfig config;
  final String statusLabel;
  final Color statusColor;
  final String colorLabel;
  final String fuelLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onMaintenance;
  final VoidCallback? onDetails;

  const _VehiclePreviewSheetContent({
    required this.vehicle,
    required this.config,
    required this.statusLabel,
    required this.statusColor,
    required this.colorLabel,
    required this.fuelLabel,
    this.onEdit,
    this.onMaintenance,
    this.onDetails,
  });

  static const _vehicleImages = {
    'half_truck': 'assets/images/vehicles/half_truck.png',
    'jumbo_truck': 'assets/images/vehicles/jumbo_truck.png',
    'double_cabin': 'assets/images/vehicles/double_cabin.png',
    'bus': 'assets/images/vehicles/bus.png',
    'microbus': 'assets/images/vehicles/microbus.png',
    'forklift': 'assets/images/vehicles/forklift.png',
  };

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // ── Handle bar ──
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 3D Vehicle Model ──
              _buildVehicleImage(),
              const SizedBox(height: 20),

              // ── Vehicle Name & Plate ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: config.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(config.icon, size: 12, color: config.color),
                              const SizedBox(width: 4),
                              Text(
                                config.shortLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: config.color,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vehicle.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                        height: 1.3,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.plateNumber,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Info Grid ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildInfoGrid(),
              ),
              const SizedBox(height: 16),

              // ── Driver Info ──
              if (vehicle.hasDriver) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDriverCard(),
                ),
                const SizedBox(height: 16),
              ],

              // ── Action Buttons ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildActionButtons(context),
              ),
              SizedBox(height: bottomInset + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleImage() {
    final imagePath = _vehicleImages[vehicle.vehicleType];
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            config.color.withOpacity(0.15),
            config.color.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imagePath != null
            ? Image.asset(
                imagePath,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    config.detailIcon,
                    size: 80,
                    color: config.color.withOpacity(0.4),
                  ),
                ),
              )
            : Center(
                child: Icon(
                  config.detailIcon,
                  size: 80,
                  color: config.color.withOpacity(0.4),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'معلومات المركبة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoItem(Icons.calendar_today, 'السنة', '${vehicle.year}'),
              const SizedBox(width: 8),
              _infoItem(Icons.color_lens, 'اللون', colorLabel),
              const SizedBox(width: 8),
              _infoItem(Icons.local_gas_station, 'الوقود', fuelLabel),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoItem(Icons.speed, 'العداد', '${vehicle.currentOdometer} كم'),
              const SizedBox(width: 8),
              _infoItem(
                Icons.accessibility,
                config.capacityLabel,
                _capacityText(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(icon, size: 12, color: AppColors.textHint),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capacityText() {
    if (vehicle.vehicleType == 'forklift' || vehicle.vehicleType == 'half_truck' || vehicle.vehicleType == 'jumbo_truck') {
      final tons = vehicle.cargoCapacityTons;
      if (tons != null && tons > 0) return '${tons} طن';
      return 'غير محدد';
    }
    final seats = vehicle.passengerCapacity;
    if (seats != null && seats > 0) return '$seats راكب';
    return 'غير محدد';
  }

  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                vehicle.driverName?.isNotEmpty == true
                    ? vehicle.driverName![0]
                    : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: config.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  vehicle.driverName ?? 'غير محدد',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.right,
                ),
                if (vehicle.driverPhone != null && vehicle.driverPhone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        vehicle.driverPhone!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.phone, size: 12, color: AppColors.textHint),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Details button
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                onDetails?.call();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: config.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'التفاصيل',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Maintenance button
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                onMaintenance?.call();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build, size: 18, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      'صيانة',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Edit button
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'تعديل',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
