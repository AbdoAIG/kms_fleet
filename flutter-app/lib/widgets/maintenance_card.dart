import 'package:flutter/material.dart';
import '../models/maintenance_record.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class MaintenanceCard extends StatelessWidget {
  final MaintenanceRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MaintenanceCard({
    super.key,
    required this.record,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color get _statusColor =>
      AppConstants.maintenanceStatusColors[record.status] ??
      AppColors.textSecondary;

  Color get _typeColor =>
      AppConstants.maintenanceTypeColors[record.type] ??
      AppColors.textSecondary;

  IconData get _typeIcon =>
      AppConstants.maintenanceTypeIcons[record.type] ?? Icons.build;

  Color get _priorityColor =>
      AppConstants.priorityColors[record.priority] ?? AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_typeIcon, color: _typeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                record.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (onEdit != null || onDelete != null)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert,
                                    color: AppColors.textHint, size: 18),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') onEdit?.call();
                                  if (value == 'delete') onDelete?.call();
                                },
                                itemBuilder: (context) => [
                                  if (onEdit != null)
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit,
                                              size: 18,
                                              color: AppColors.primary),
                                          SizedBox(width: 8),
                                          Text('تعديل'),
                                        ],
                                      ),
                                    ),
                                  if (onDelete != null)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              size: 18,
                                              color: AppColors.error),
                                          SizedBox(width: 8),
                                          Text('حذف',
                                              style: TextStyle(
                                                  color: AppColors.error)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (record.vehicle != null)
                          Text(
                            '${record.vehicle!.make} ${record.vehicle!.model} - ${record.vehicle!.plateNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Meta Info Row
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppConstants.maintenanceStatuses[record.status] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _priorityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppConstants.priorities[record.priority] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _priorityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppConstants.maintenanceTypes[record.type] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _typeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Bottom Details
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    AppFormatters.formatDate(record.maintenanceDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.speed, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    AppFormatters.formatOdometer(record.odometerReading),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppFormatters.formatCurrency(record.totalCost),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
