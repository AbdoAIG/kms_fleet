import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/vehicle_rotating_image.dart';

// ═══════════════════════════════════════════════════════════════
//  VEHICLE IMAGE MAP
// ═══════════════════════════════════════════════════════════════

const _vehicleImages = {
  'half_truck': 'assets/images/vehicles/half_truck.png',
  'jumbo_truck': 'assets/images/vehicles/jumbo_truck.png',
  'double_cabin': 'assets/images/vehicles/double_cabin.png',
  'bus': 'assets/images/vehicles/bus.png',
  'microbus': 'assets/images/vehicles/microbus.png',
  'forklift': 'assets/images/vehicles/forklift.png',
};

// ═══════════════════════════════════════════════════════════════
//  VEHICLE CARD — Modern Horizontal Design
// ═══════════════════════════════════════════════════════════════

class Vehicle3DCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMaintenance;

  const Vehicle3DCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onMaintenance,
  });

  Color get _typeColor {
    if (vehicle.vehicleType != null && vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypeColors[vehicle.vehicleType] ?? AppColors.primary;
    }
    return AppColors.primary;
  }

  String get _typeLabel {
    if (vehicle.vehicleType != null && vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypes[vehicle.vehicleType] ?? '';
    }
    return '';
  }

  IconData get _typeIcon {
    if (vehicle.vehicleType != null && vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypeIcons[vehicle.vehicleType] ?? Icons.directions_car;
    }
    return Icons.directions_car;
  }

  Color get _statusColor =>
      AppConstants.vehicleStatusColors[vehicle.status] ?? AppColors.textSecondary;

  String get _statusLabel =>
      AppConstants.vehicleStatuses[vehicle.status] ?? '';

  String? get _vehicleImage => _vehicleImages[vehicle.vehicleType];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // ── Vehicle Image (with rotating preview) ──
              _buildVehicleImage(),
              // ── Vehicle Info ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges row
                      Row(
                        children: [
                          // Status pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: _statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Type pill - use short label to prevent overflow
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_typeIcon, color: _typeColor, size: 10),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      _typeLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _typeColor,
                                        fontFamily: 'Cairo',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Menu
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.more_vert, color: AppColors.textHint.withOpacity(0.5), size: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  onEdit?.call();
                                  break;
                                case 'maintenance':
                                  onMaintenance?.call();
                                  break;
                                case 'delete':
                                  onDelete?.call();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              _PopupMenuItem(icon: Icons.edit_outlined, label: 'تعديل', value: 'edit'),
                              _PopupMenuItem(icon: Icons.build_outlined, label: 'صيانة', value: 'maintenance'),
                              _PopupMenuItem(icon: Icons.delete_outline, label: 'حذف', value: 'delete', isDestructive: true),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Vehicle name
                      Text(
                        vehicle.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo',
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Plate number
                      Text(
                        vehicle.plateNumber,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _typeColor,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Quick stats
                      Row(
                        children: [
                          _QuickStat(
                            icon: Icons.speed,
                            value: AppFormatters.formatNumber(vehicle.currentOdometer),
                            unit: 'كم',
                          ),
                          const SizedBox(width: 14),
                          _QuickStat(
                            icon: Icons.local_gas_station,
                            value: AppConstants.fuelTypes[vehicle.fuelType] ?? '',
                          ),
                          const Spacer(),
                          if (vehicle.hasDriver)
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_outline, size: 12, color: AppColors.textHint),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      vehicle.driverName ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontFamily: 'Cairo',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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

  Widget _buildVehicleImage() {
    return SizedBox(
      width: 110,
      height: 120,
      child: VehicleRotatingImage(
        imagePath: _vehicleImage,
        fallbackIcon: _typeIcon,
        accentColor: _typeColor,
        height: 120,
        borderRadius: 0,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? unit;

  const _QuickStat({
    required this.icon,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(
          unit != null ? '$value $unit' : value,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PopupMenuItem extends PopupMenuItem<String> {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _PopupMenuItem({
    required this.icon,
    required this.label,
    required String value,
    this.isDestructive = false,
  }) : super(value: value, child: const SizedBox.shrink());

  @override
  PopupMenuItemState<String, _PopupMenuItem> createState() =>
      _PopupMenuItemState();
}

class _PopupMenuItemState extends PopupMenuItemState<String, _PopupMenuItem> {
  @override
  Widget buildChild() {
    return Row(
      children: [
        Icon(
          widget.icon,
          size: 18,
          color: widget.isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            color: widget.isDestructive ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
