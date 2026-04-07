import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/vehicle_type_config.dart';

/// Shows a bottom sheet with vehicle preview and quick actions.
void showVehiclePreviewSheet(BuildContext context, {
  required Vehicle vehicle,
  VoidCallback? onEdit,
  VoidCallback? onMaintenance,
  VoidCallback? onDetails,
}) {
  final config = getVehicleTypeConfig(vehicle.vehicleType);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VehiclePreviewSheetContent(
      vehicle: vehicle,
      config: config,
      onEdit: onEdit,
      onMaintenance: onMaintenance,
      onDetails: onDetails,
    ),
  );
}

class _VehiclePreviewSheetContent extends StatelessWidget {
  final Vehicle vehicle;
  final VehicleTypeConfig config;
  final VoidCallback? onEdit;
  final VoidCallback? onMaintenance;
  final VoidCallback? onDetails;

  const _VehiclePreviewSheetContent({
    required this.vehicle,
    required this.config,
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
    final statusColor = AppConstants.vehicleStatusColors[vehicle.status] ?? AppColors.textHint;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.88,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 10),
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Vehicle Image ──
              _buildVehicleImage(),
              const SizedBox(height: 16),

              // ── Name + Badges ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildPill(
                          color: statusColor,
                          icon: null,
                          label: AppConstants.vehicleStatuses[vehicle.status] ?? '',
                        ),
                        const SizedBox(width: 6),
                        _buildPill(
                          color: config.color,
                          icon: config.icon,
                          label: config.shortLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Name
                    Text(
                      vehicle.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                        height: 1.3,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    // Plate
                    Text(
                      vehicle.plateNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Quick Info Grid ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildInfoGrid(),
              ),
              const SizedBox(height: 12),

              // ── Driver Quick Info ──
              if (vehicle.hasDriver)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDriverRow(),
                ),
              const SizedBox(height: 16),

              // ── Action Buttons ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildActionButtons(context),
              ),
              SizedBox(height: bottomInset + 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPill({required Color color, required IconData? icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 11),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleImage() {
    final imagePath = _vehicleImages[vehicle.vehicleType];
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            config.color.withOpacity(0.12),
            config.color.withOpacity(0.04),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imagePath != null
            ? Image.asset(
                imagePath,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(config.detailIcon, size: 64, color: config.color.withOpacity(0.3)),
                ),
              )
            : Center(
                child: Icon(config.detailIcon, size: 64, color: config.color.withOpacity(0.3)),
              ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    final colorLabel = AppConstants.vehicleColors[vehicle.color] ?? vehicle.color;
    final fuelLabel = AppConstants.fuelTypes[vehicle.fuelType] ?? vehicle.fuelType;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _infoCell(Icons.calendar_today, 'السنة', '${vehicle.year}')),
          const SizedBox(width: 6),
          Expanded(child: _infoCell(Icons.color_lens, 'اللون', colorLabel)),
          const SizedBox(width: 6),
          Expanded(child: _infoCell(Icons.local_gas_station, 'الوقود', fuelLabel)),
          const SizedBox(width: 6),
          Expanded(child: _infoCell(Icons.speed, 'العداد', '${vehicle.currentOdometer} كم')),
        ],
      ),
    );
  }

  Widget _infoCell(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textHint, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: config.color.withOpacity(0.1),
            child: Text(
              vehicle.driverName?.isNotEmpty == true ? vehicle.driverName![0] : '?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: config.color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.driverName ?? 'غير محدد',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                if (vehicle.driverPhone != null && vehicle.driverPhone!.isNotEmpty)
                  Text(
                    vehicle.driverPhone!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Cairo'),
                    textDirection: TextDirection.ltr,
                  ),
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
        // Details
        Expanded(
          child: _ActionButton(
            label: 'التفاصيل',
            icon: Icons.visibility,
            color: config.color,
            onTap: () {
              Navigator.pop(context);
              onDetails?.call();
            },
          ),
        ),
        const SizedBox(width: 10),
        // Maintenance
        Expanded(
          child: _ActionButton(
            label: 'صيانة',
            icon: Icons.build,
            color: AppColors.warning,
            isOutline: true,
            onTap: () {
              Navigator.pop(context);
              onMaintenance?.call();
            },
          ),
        ),
        const SizedBox(width: 10),
        // Edit
        Expanded(
          child: _ActionButton(
            label: 'تعديل',
            icon: Icons.edit,
            color: AppColors.textSecondary,
            isOutline: true,
            onTap: () {
              Navigator.pop(context);
              onEdit?.call();
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isOutline;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.isOutline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(12),
            border: isOutline ? Border.all(color: AppColors.border) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isOutline ? color : Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isOutline ? color : Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
