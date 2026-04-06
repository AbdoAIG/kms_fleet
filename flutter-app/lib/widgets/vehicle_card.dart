import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMaintenance;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onMaintenance,
  });

  Color get _statusColor =>
      AppConstants.vehicleStatusColors[vehicle.status] ?? AppColors.textSecondary;

  /// Get vehicle type icon, or fallback to directions_car.
  IconData get _typeIcon {
    if (vehicle.vehicleType != null && vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypeIcons[vehicle.vehicleType] ?? Icons.directions_car;
    }
    return Icons.directions_car;
  }

  /// Get vehicle type color, or fallback to primary.
  Color get _typeColor {
    if (vehicle.vehicleType != null && vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypeColors[vehicle.vehicleType] ?? AppColors.primary;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + vehicle info + status ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_typeColor, _typeColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle name (make + model + year)
                      Text(
                        vehicle.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Plate number badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              vehicle.plateNumber,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Year
                          Text(
                            vehicle.year.toString(),
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                      // Driver name (if exists) — shown below vehicle info
                      if (vehicle.hasDriver) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 13, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              vehicle.driverDisplayName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppConstants.vehicleStatuses[vehicle.status] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ── Bottom info row ──
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  _InfoChip(icon: Icons.speed, label: AppFormatters.formatOdometer(vehicle.currentOdometer)),
                  const SizedBox(width: 14),
                  _InfoChip(icon: Icons.local_gas_station, label: AppConstants.fuelTypes[vehicle.fuelType] ?? ''),
                  const SizedBox(width: 14),
                  // Vehicle type badge
                  if (vehicle.vehicleType != null && vehicle.vehicleType!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppConstants.vehicleTypes[vehicle.vehicleType] ?? vehicle.vehicleType!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _typeColor,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Actions menu
                  if (onEdit != null || onMaintenance != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textHint, size: 18),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit': onEdit?.call();
                          case 'maintenance': onMaintenance?.call();
                          case 'delete': onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit, size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('تعديل'),
                            ]),
                          ),
                        if (onMaintenance != null)
                          const PopupMenuItem(
                            value: 'maintenance',
                            child: Row(children: [
                              Icon(Icons.build, size: 18, color: AppColors.accent),
                              SizedBox(width: 8),
                              Text('سجل الصيانة'),
                            ]),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete, size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('حذف', style: TextStyle(color: AppColors.error)),
                            ]),
                          ),
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

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white': return const Color(0xFFFFFFFF);
      case 'black': return const Color(0xFF1A1A1A);
      case 'silver': return const Color(0xFFC0C0C0);
      case 'gray': case 'grey': return const Color(0xFF808080);
      case 'red': return const Color(0xFFDC2626);
      case 'blue': return const Color(0xFF2563EB);
      case 'green': return const Color(0xFF16A34A);
      case 'brown': return const Color(0xFF78350F);
      case 'gold': return const Color(0xFFD4A017);
      case 'beige': return const Color(0xFFF5F5DC);
      default: return AppColors.primary;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
