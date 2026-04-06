import 'package:flutter/material.dart';
import '../models/maintenance_record.dart';
import '../services/report_service.dart';
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
      AppConstants.maintenanceStatusColors[record.status] ?? AppColors.textSecondary;

  Color get _typeColor =>
      AppConstants.maintenanceTypeColors[record.type] ?? AppColors.textSecondary;

  IconData get _typeIcon =>
      AppConstants.maintenanceTypeIcons[record.type] ?? Icons.build;

  Color get _priorityColor =>
      AppConstants.priorityColors[record.priority] ?? AppColors.textSecondary;

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
            // ── Top row ──
            Row(
              children: [
                // Priority dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: _priorityColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                // Type icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon, color: _typeColor, size: 20),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          // Export PDF button
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'تصدير تقرير العطل',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('جاري تصدير التقرير...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              ReportService.generateSingleMaintenancePDF(record);
                            },
                          ),
                          if (onEdit != null || onDelete != null)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: AppColors.textHint, size: 18),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onSelected: (value) {
                                if (value == 'edit') onEdit?.call();
                                if (value == 'delete') onDelete?.call();
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
                      if (record.vehicle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${record.vehicle!.make} ${record.vehicle!.model} - ${record.vehicle!.plateNumber}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Badges row ──
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildBadge(AppConstants.maintenanceStatuses[record.status] ?? '', _statusColor),
                _buildBadge(AppConstants.priorities[record.priority] ?? '', _priorityColor),
                _buildBadge(AppConstants.maintenanceTypes[record.type] ?? '', _typeColor),
              ],
            ),
            const SizedBox(height: 10),

            // ── Bottom details row ──
            Row(
              children: [
                Icon(Icons.calendar_today, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  AppFormatters.formatDate(record.maintenanceDate),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                Icon(Icons.speed, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  AppFormatters.formatOdometer(record.odometerReading),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
