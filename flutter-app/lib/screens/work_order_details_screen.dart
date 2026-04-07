import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/work_order.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';
import '../providers/work_order_provider.dart';
import 'add_work_order_screen.dart';

class WorkOrderDetailsScreen extends StatefulWidget {
  final WorkOrder workOrder;

  const WorkOrderDetailsScreen({super.key, required this.workOrder});

  @override
  State<WorkOrderDetailsScreen> createState() => _WorkOrderDetailsScreenState();
}

class _WorkOrderDetailsScreenState extends State<WorkOrderDetailsScreen> {
  late WorkOrder _workOrder;
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _workOrder = widget.workOrder;
  }

  // ── Color / icon / label helpers ──
  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.folder_open;
      case 'in_progress':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'maintenance':
        return AppColors.primary;
      case 'repair':
        return AppColors.accent;
      case 'inspection':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.build;
      case 'repair':
        return Icons.construction;
      case 'inspection':
        return Icons.fact_check;
      default:
        return Icons.build;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'maintenance':
        return 'صيانة';
      case 'repair':
        return 'إصلاح';
      case 'inspection':
        return 'فحص';
      default:
        return type;
    }
  }

  String _priorityLabel(String priority) {
    return AppConstants.priorities[priority] ?? priority;
  }

  Color _priorityColor(String priority) {
    return AppConstants.priorityColors[priority] ?? AppColors.textSecondary;
  }

  String _nextStatusLabel() {
    switch (_workOrder.status) {
      case 'open':
        return 'بدء التنفيذ';
      case 'in_progress':
        return 'إنهاء العمل';
      default:
        return '';
    }
  }

  Future<void> _advanceStatus() async {
    setState(() => _isAdvancing = true);
    try {
      final success =
          await context.read<WorkOrderProvider>().advanceStatus(_workOrder);
      if (success) {
        // Refresh the order from provider
        final updated = context.read<WorkOrderProvider>().allOrders.firstWhere(
              (o) => o.id == _workOrder.id,
              orElse: () => _workOrder,
            );
        setState(() => _workOrder = updated);
        final newStatus = _workOrder.status == 'completed' ? 'مكتمل' : 'قيد التنفيذ';
        AppHelpers.showSnackBar(context, 'تم تحديث حالة أمر العمل إلى: $newStatus');
      }
    } catch (e) {
      AppHelpers.showSnackBar(context, 'حدث خطأ أثناء تحديث الحالة', isError: true);
    }
    setState(() => _isAdvancing = false);
  }

  Future<void> _deleteOrder() async {
    final confirmed = await AppHelpers.showConfirmDialog(
      context,
      title: 'حذف أمر العمل',
      message: 'هل أنت متأكد من حذف هذا أمر العمل؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await context.read<WorkOrderProvider>().deleteOrder(_workOrder.id!);
      AppHelpers.showSnackBar(context, 'تم حذف أمر العمل بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      AppHelpers.showSnackBar(context, 'حدث خطأ أثناء الحذف', isError: true);
    }
  }

  Future<void> _editOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddWorkOrderScreen(workOrder: _workOrder),
      ),
    );
    if (result == true && mounted) {
      // Refresh from provider
      final updated = context.read<WorkOrderProvider>().allOrders.firstWhere(
            (o) => o.id == _workOrder.id,
            orElse: () => _workOrder,
          );
      setState(() => _workOrder = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wo = _workOrder;
    final canAdvance = wo.status != 'completed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل أمر العمل'),
        actions: [
          // Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل',
            onPressed: _editOrder,
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outlined, color: AppColors.error),
            tooltip: 'حذف',
            onPressed: _deleteOrder,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header with badges ──
          _buildHeaderCard(wo),
          const SizedBox(height: 16),

          // ── Vehicle info card ──
          if (wo.vehicle != null) ...[
            _buildVehicleCard(wo),
            const SizedBox(height: 16),
          ],

          // ── Technician info card ──
          if (wo.technicianName != null) ...[
            _buildTechnicianCard(wo),
            const SizedBox(height: 16),
          ],

          // ── Cost comparison ──
          if (wo.estimatedCost != null || wo.actualCost != null) ...[
            _buildCostCard(wo),
            const SizedBox(height: 16),
          ],

          // ── Status timeline ──
          _buildTimelineCard(wo),
          const SizedBox(height: 16),

          // ── Description ──
          if (wo.description != null && wo.description!.isNotEmpty) ...[
            _buildInfoCard(
              icon: Icons.description,
              title: 'الوصف',
              content: wo.description!,
            ),
            const SizedBox(height: 16),
          ],

          // ── Notes ──
          if (wo.notes != null && wo.notes!.isNotEmpty) ...[
            _buildInfoCard(
              icon: Icons.notes,
              title: 'ملاحظات',
              content: wo.notes!,
            ),
            const SizedBox(height: 16),
          ],

          // ── Created date ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.textHint),
                const SizedBox(width: 8),
                Text(
                  'تم الإنشاء: ${AppFormatters.formatDateTime(wo.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                if (wo.updatedAt.difference(wo.createdAt).inMinutes > 1) ...[
                  const Spacer(),
                  Text(
                    'آخر تعديل: ${AppFormatters.formatDateTime(wo.updatedAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Space for bottom button
          SizedBox(height: canAdvance ? 80 : 24),
        ],
      ),
      // ── Advance status button ──
      bottomNavigationBar: canAdvance
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isAdvancing ? null : _advanceStatus,
                  icon: _isAdvancing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          wo.status == 'open'
                              ? Icons.play_arrow
                              : Icons.check,
                        ),
                  label: Text(
                    _nextStatusLabel(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wo.status == 'open'
                        ? AppColors.info
                        : AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ── Header Card ──
  Widget _buildHeaderCard(WorkOrder wo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_statusColor(wo.status), _statusColor(wo.status).withOpacity(0.85)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'أمر عمل #${wo.id ?? '-'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _Badge(
                label: wo.statusLabel,
                color: Colors.white.withOpacity(0.25),
                textColor: Colors.white,
                icon: _statusIcon(wo.status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Badge(
                label: _typeLabel(wo.type),
                color: Colors.white.withOpacity(0.2),
                textColor: Colors.white,
                icon: _typeIcon(wo.type),
              ),
              const SizedBox(width: 8),
              _Badge(
                label: _priorityLabel(wo.priority),
                color: Colors.white.withOpacity(0.2),
                textColor: Colors.white,
                icon: AppHelpers.getPriorityIcon(wo.priority),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Vehicle Card ──
  Widget _buildVehicleCard(WorkOrder wo) {
    final v = wo.vehicle!;
    return _SectionCard(
      icon: Icons.directions_car,
      title: 'بيانات السيارة',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge,
            label: 'السيارة',
            value: '${v.make} ${v.model}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.credit_card,
            label: 'رقم اللوحة',
            value: v.plateNumber,
          ),
        ],
      ),
    );
  }

  // ── Technician Card ──
  Widget _buildTechnicianCard(WorkOrder wo) {
    return _SectionCard(
      icon: Icons.person,
      title: 'بيانات الفني',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline,
            label: 'الاسم',
            value: wo.technicianName ?? '',
          ),
          if (wo.technicianPhone != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'الهاتف',
              value: wo.technicianPhone!,
            ),
          ],
        ],
      ),
    );
  }

  // ── Cost Card ──
  Widget _buildCostCard(WorkOrder wo) {
    final hasBoth = wo.estimatedCost != null && wo.actualCost != null;
    final isOver = wo.isOverBudget;
    final variance = wo.costVariance;

    return _SectionCard(
      icon: Icons.attach_money,
      title: 'التكاليف',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CostBox(
                  label: 'التقديرية',
                  value: wo.estimatedCost,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CostBox(
                  label: 'الفعلية',
                  value: wo.actualCost,
                  color: hasBoth
                      ? (isOver ? AppColors.error : AppColors.success)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (hasBoth && wo.estimatedCost! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOver
                    ? AppColors.error.withOpacity(0.08)
                    : AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isOver ? Icons.trending_up : Icons.trending_down,
                    size: 18,
                    color: isOver ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOver
                          ? 'تجاوز الميزانية بـ ${variance.abs().toStringAsFixed(2)} ج.م'
                          : variance == 0
                              ? 'التكلفة مطابقة للتقدير'
                              : 'توفير ${variance.abs().toStringAsFixed(2)} ج.م',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOver ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Timeline Card ──
  Widget _buildTimelineCard(WorkOrder wo) {
    final steps = [
      _TimelineStep(
        label: 'مفتوح',
        subtitle: AppFormatters.formatDateTime(wo.createdAt),
        isCompleted: true,
        color: AppColors.warning,
        icon: Icons.folder_open,
      ),
      if (wo.startDate != null)
        _TimelineStep(
          label: 'قيد التنفيذ',
          subtitle: AppFormatters.formatDateTime(wo.startDate!),
          isCompleted: wo.status == 'in_progress' || wo.status == 'completed',
          isCurrent: wo.status == 'in_progress',
          color: AppColors.info,
          icon: Icons.autorenew,
        )
      else
        _TimelineStep(
          label: 'قيد التنفيذ',
          subtitle: 'لم يبدأ بعد',
          isCompleted: false,
          color: AppColors.info,
          icon: Icons.autorenew,
        ),
      if (wo.completedDate != null)
        _TimelineStep(
          label: 'مكتمل',
          subtitle: AppFormatters.formatDateTime(wo.completedDate!),
          isCompleted: wo.status == 'completed',
          isCurrent: wo.status == 'completed',
          color: AppColors.success,
          icon: Icons.check_circle,
        )
      else
        _TimelineStep(
          label: 'مكتمل',
          subtitle: 'لم يكتمل بعد',
          isCompleted: false,
          color: AppColors.success,
          icon: Icons.check_circle,
        ),
    ];

    return _SectionCard(
      icon: Icons.timeline,
      title: 'مسار الحالة',
      child: Column(
        children: steps.map((step) {
          final index = steps.indexOf(step);
          final isLast = index == steps.length - 1;
          return Column(
            children: [
              _buildTimelineRow(step, isLast),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineRow(_TimelineStep step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted
                        ? step.color
                        : step.color.withOpacity(0.15),
                    border: step.isCurrent
                        ? Border.all(
                            color: step.color,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Icon(
                    step.icon,
                    size: 14,
                    color: step.isCompleted ? Colors.white : step.color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.isCompleted
                          ? step.color.withOpacity(0.4)
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          step.isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color: step.isCompleted
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: step.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Card (Description / Notes) ──
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Sub-Widgets ──

  Widget _InfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 12),
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Badge widget ──
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Card ──
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Cost Box ──
class _CostBox extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _CostBox({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value != null ? AppFormatters.formatCurrency(value!) : 'غير محدد',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline Step ──
class _TimelineStep {
  final String label;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final Color color;
  final IconData icon;

  _TimelineStep({
    required this.label,
    required this.subtitle,
    this.isCompleted = false,
    this.isCurrent = false,
    required this.color,
    required this.icon,
  });
}
