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

  // ── Type metadata ──────────────────────────────────────────────────────

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

  final List<MapEntry<String, String>> _filterTabs = const [
    MapEntry('all', 'الكل'),
    MapEntry('pre_trip', 'ما قبل الرحلة'),
    MapEntry('post_trip', 'ما بعد الرحلة'),
    MapEntry('weekly', 'أسبوعي'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قوائم الفحص'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: _filterTabs
                  .map((tab) => _buildFilterChip(tab.key, tab.value))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
          // Checklists List
          Expanded(
            child: Consumer<ChecklistProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingWidget(
                      message: 'جاري تحميل قوائم الفحص...');
                }

                if (provider.checklists.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.fact_check_outlined,
                    title: 'لا توجد قوائم فحص',
                    subtitle: 'أضف قائمة فحص جديدة لبدء تفتيش المركبات',
                    actionText: 'إضافة قائمة فحص',
                    onAction: () {
                      Navigator.pushNamed(context, '/add-checklist');
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadChecklists(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
        onPressed: () {
          Navigator.pushNamed(context, '/add-checklist');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Filter Chip ────────────────────────────────────────────────────────

  Widget _buildFilterChip(String value, String label) {
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
        backgroundColor: AppColors.surfaceVariant,
        selectedColor:
            _typeColors[value] ?? AppColors.primary,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide.none,
      ),
    );
  }

  // ── Checklist Card ─────────────────────────────────────────────────────

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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: icon + info + menu ──
              Row(
                children: [
                  // Type Icon
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
                  // Info
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
                              icon: const Icon(Icons.more_vert,
                                  color: AppColors.textHint, size: 18),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _confirmDelete(
                                      context, checklist.id!, provider);
                                }
                              },
                              itemBuilder: (context) => [
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
                        if (checklist.vehicle != null)
                          Text(
                            '${checklist.vehicle!.make} ${checklist.vehicle!.model}',
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

              // ── Badges row ──
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
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
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ),
                  if (checklist.hasDefects) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber,
                              size: 13, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text(
                            '${checklist.defectCount} عطل',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // ── Bottom row: date, score ──
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    AppFormatters.formatDate(checklist.inspectionDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (checklist.inspectorName != null &&
                      checklist.inspectorName!.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.person,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      checklist.inspectorName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  // Score
                  if (checklist.status != 'pending') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(checklist.overallScore)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppFormatters.formatPercentage(checklist.overallScore),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              _getScoreColor(checklist.overallScore),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  void _confirmDelete(
      BuildContext context, int id, ChecklistProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('حذف قائمة الفحص'),
        content: const Text('هل أنت متأكد من حذف قائمة الفحص هذه؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteChecklist(id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف قائمة الفحص بنجاح'),
                  behavior: SnackBarBehavior.floating,
                ),
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
