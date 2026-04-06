import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/checklist.dart';
import '../providers/checklist_provider.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  String _typeFilter = 'all';
  String _statusFilter = 'all';

  static const Map<String, String> _typeLabels = {
    'pre_trip': 'ما قبل الرحلة',
    'post_trip': 'ما بعد الرحلة',
    'weekly': 'أسبوعي',
  };

  static const Map<String, IconData> _typeIcons = {
    'pre_trip': Icons.exit_to_app,
    'post_trip': Icons.login,
    'weekly': Icons.calendar_view_week,
  };

  static const Map<String, Color> _typeColors = {
    'pre_trip': Color(0xFF0277BD),
    'post_trip': Color(0xFF6A1B9A),
    'weekly': Color(0xFFE65100),
  };

  static const Map<String, String> _statusLabels = {
    'passed': 'ناجح',
    'failed': 'فاشل',
    'pending': 'معلق',
  };

  static const Map<String, Color> _statusColors = {
    'passed': AppColors.success,
    'failed': AppColors.error,
    'pending': AppColors.warning,
  };

  static const Map<String, IconData> _statusIcons = {
    'passed': Icons.check_circle,
    'failed': Icons.cancel,
    'pending': Icons.schedule,
  };

  final List<MapEntry<String, String>> _typeFilterTabs = const [
    MapEntry('all', 'الكل'),
    MapEntry('pre_trip', 'ما قبل الرحلة'),
    MapEntry('post_trip', 'ما بعد الرحلة'),
    MapEntry('weekly', 'أسبوعي'),
  ];

  final List<MapEntry<String, String>> _statusFilterTabs = const [
    MapEntry('all', 'الكل'),
    MapEntry('passed', 'ناجح'),
    MapEntry('failed', 'فاشل'),
    MapEntry('pending', 'معلق'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Page Title ──
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'قوائم الفحص',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // ── Type Filter ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _typeFilterTabs
                    .map((tab) => _buildTypeChip(tab.key, tab.value))
                    .toList(),
              ),
            ),
          ),

          // ── Status Filter ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _statusFilterTabs
                    .map((tab) => _buildStatusChip(tab.key, tab.value))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Checklists List ──
          Expanded(
            child: Consumer<ChecklistProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingWidget(message: 'جاري تحميل قوائم الفحص...');
                }

                if (provider.checklists.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.fact_check_outlined,
                    title: 'لا توجد قوائم فحص',
                    subtitle: 'أضف قائمة فحص جديدة لبدء تفتيش المركبات',
                    actionText: 'إضافة قائمة فحص',
                    onAction: () => Navigator.pushNamed(context, '/add-checklist'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadChecklists(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: provider.checklists.length,
                    itemBuilder: (context, index) {
                      final checklist = provider.checklists[index];
                      return _buildChecklistCard(
                        checklist: checklist,
                        provider: provider,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-checklist'),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Filter Chips ──

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
        onSelected: (selected) {
          setState(() => _typeFilter = value);
          context.read<ChecklistProvider>().setTypeFilter(value);
        },
        backgroundColor: AppColors.surface,
        selectedColor: _typeColors[value] ?? AppColors.primary,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide(color: isSelected ? (_typeColors[value] ?? AppColors.primary) : AppColors.border),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
        onSelected: (selected) {
          setState(() => _statusFilter = value);
          context.read<ChecklistProvider>().setStatusFilter(value);
        },
        backgroundColor: AppColors.surface,
        selectedColor: _statusColors[value] ?? AppColors.primary,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide(color: isSelected ? (_statusColors[value] ?? AppColors.primary) : AppColors.border),
      ),
    );
  }

  // ── Checklist Card ──

  Widget _buildChecklistCard({
    required Checklist checklist,
    required ChecklistProvider provider,
  }) {
    final typeColor = _typeColors[checklist.type] ?? AppColors.textSecondary;
    final typeIcon = _typeIcons[checklist.type] ?? Icons.fact_check;
    final statusColor = _statusColors[checklist.status] ?? AppColors.textHint;
    final statusLabel = _statusLabels[checklist.status] ?? checklist.status;
    final statusIcon = _statusIcons[checklist.status] ?? Icons.help_outline;
    final typeLabel = _typeLabels[checklist.type] ?? checklist.type;

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
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, '/add-checklist', arguments: checklist);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ──
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              checklist.vehicle?.plateNumber ?? 'غير محدد',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: AppColors.textHint, size: 18),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (value) {
                              if (value == 'delete') _confirmDelete(context, checklist.id!, provider);
                            },
                            itemBuilder: (context) => [
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
                      if (checklist.vehicle != null)
                        Text(
                          '${checklist.vehicle!.make} ${checklist.vehicle!.model}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // ── Score Circle ──
                if (checklist.status != 'pending') ...[
                  const SizedBox(width: 12),
                  _buildScoreCircle(checklist.overallScore),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // ── Badges row ──
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Status Badge
                _buildBadge(statusIcon, statusLabel, statusColor),
                // Type Badge
                _buildBadge(null, typeLabel, typeColor),
                // Defects badge
                if (checklist.hasDefects)
                  _buildBadge(Icons.warning_amber, '${checklist.defectCount} عطل', AppColors.error),
              ],
            ),
            const SizedBox(height: 10),

            // ── Bottom row: date, inspector ──
            Row(
              children: [
                Icon(Icons.calendar_today, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  AppFormatters.formatDate(checklist.inspectionDate),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (checklist.inspectorName != null && checklist.inspectorName!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.person, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    checklist.inspectorName!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                // Score text
                if (checklist.status != 'pending')
                  Text(
                    AppFormatters.formatPercentage(checklist.overallScore),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _getScoreColor(checklist.overallScore),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCircle(double score) {
    final color = _getScoreColor(score);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              color: color,
            ),
          ),
          Text(
            '${score.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData? icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  void _confirmDelete(BuildContext context, int id, ChecklistProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف قائمة الفحص'),
        content: const Text('هل أنت متأكد من حذف قائمة الفحص هذه؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteChecklist(id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف قائمة الفحص بنجاح'), behavior: SnackBarBehavior.floating),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
