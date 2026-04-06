import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/maintenance_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../providers/maintenance_provider.dart';
import '../providers/work_order_provider.dart';
import '../models/work_order.dart';
import 'add_work_order_screen.dart';
import 'work_order_details_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Maintenance records tab state ──
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  bool _showFilters = false;

  // ── Work orders tab state ──
  final TextEditingController _woSearchController = TextEditingController();
  String _woStatusFilter = 'all';
  String _woTypeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load work orders when created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkOrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _woSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Page Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: const Text(
              'الصيانة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // ── Tab Bar ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(3),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              padding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'سجلات الصيانة'),
                Tab(text: 'أوامر العمل'),
              ],
            ),
          ),

          // ── Tab Content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMaintenanceRecordsTab(),
                _buildWorkOrdersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddWorkOrderScreen(),
                  ),
                );
                if (result == true) {
                  context.read<WorkOrderProvider>().loadOrders();
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/add-maintenance'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            ),
    );
  }

  // ══════════════════════════════════════════
  // TAB 1: Maintenance Records
  // ══════════════════════════════════════════
  Widget _buildMaintenanceRecordsTab() {
    return Column(
      children: [
        // ── Search Bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
                context.read<MaintenanceProvider>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'البحث بالوصف أو مزود الخدمة...',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textHint, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textHint, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          context
                              .read<MaintenanceProvider>()
                              .setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ),

        // ── Status Filter Chips ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMaintenanceStatusChip('الكل', 'all'),
                _buildMaintenanceStatusChip('معلقة', 'pending'),
                _buildMaintenanceStatusChip('قيد التنفيذ', 'in_progress'),
                _buildMaintenanceStatusChip('مكتملة', 'completed'),
                _buildMaintenanceStatusChip('ملغية', 'cancelled'),
              ],
            ),
          ),
        ),

        // ── Extended Filters (if expanded) ──
        if (_showFilters) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'النوع',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildMaintenanceTypeChip('الكل', 'all'),
                      _buildMaintenanceTypeChip('إطارات', 'tires'),
                      _buildMaintenanceTypeChip('كهرباء', 'electrical'),
                      _buildMaintenanceTypeChip('ميكانيكا', 'mechanical'),
                      _buildMaintenanceTypeChip('فرامل', 'brakes'),
                      _buildMaintenanceTypeChip('زيت', 'oil_change'),
                      _buildMaintenanceTypeChip('فلتر', 'filter'),
                      _buildMaintenanceTypeChip('بطارية', 'battery'),
                      _buildMaintenanceTypeChip('تكييف', 'ac'),
                      _buildMaintenanceTypeChip('ناقل حركة', 'transmission'),
                      _buildMaintenanceTypeChip('فحص', 'inspection'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
        const SizedBox(height: 4),

        // ── Filter toggle + Records List ──
        Expanded(
          child: Consumer<MaintenanceProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const LoadingWidget(message: 'جاري تحميل السجلات...');
              }

              if (provider.records.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.build_outlined,
                  title: 'لا توجد سجلات صيانة',
                  subtitle: 'أضف سجل صيانة جديد',
                  actionText: 'إضافة سجل',
                  onAction: () =>
                      Navigator.pushNamed(context, '/add-maintenance'),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadRecords(),
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: provider.records.length + 1,
                  itemBuilder: (context, index) {
                    // Filter toggle as last item
                    if (index == provider.records.length) {
                      return const SizedBox(height: 8);
                    }
                    final record = provider.records[index];
                    return MaintenanceCard(
                      record: record,
                      onTap: () {},
                      onEdit: () => Navigator.pushNamed(
                          context, '/add-maintenance',
                          arguments: record),
                      onDelete: () =>
                          _confirmDeleteMaintenance(context, record.id!, provider),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceStatusChip(String label, String value) {
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
          context.read<MaintenanceProvider>().setStatusFilter(value);
        },
        backgroundColor: AppColors.surface,
        selectedColor:
            AppConstants.maintenanceStatusColors[value] ?? AppColors.primary,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide(
            color: isSelected
                ? (AppConstants.maintenanceStatusColors[value] ??
                    AppColors.primary)
                : AppColors.border),
      ),
    );
  }

  Widget _buildMaintenanceTypeChip(String label, String value) {
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
          context.read<MaintenanceProvider>().setTypeFilter(value);
        },
        backgroundColor: AppColors.surface,
        selectedColor:
            AppConstants.maintenanceTypeColors[value] ?? AppColors.primary,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide(
            color: isSelected
                ? (AppConstants.maintenanceTypeColors[value] ??
                    AppColors.primary)
                : AppColors.border),
      ),
    );
  }

  void _confirmDeleteMaintenance(
      BuildContext context, int id, MaintenanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف السجل'),
        content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteRecord(id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم حذف السجل بنجاح'),
                    behavior: SnackBarBehavior.floating),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // TAB 2: Work Orders
  // ══════════════════════════════════════════
  Widget _buildWorkOrdersTab() {
    return Column(
      children: [
        // ── Stats Bar ──
        Consumer<WorkOrderProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.allOrders.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  _buildStatChip(
                    count: provider.openCount,
                    label: 'مفتوح',
                    color: AppColors.warning,
                    icon: Icons.folder_open,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      count: provider.inProgressCount,
                      label: 'قيد التنفيذ',
                      color: AppColors.info,
                      icon: Icons.autorenew,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      count: provider.completedCount,
                      label: 'مكتمل',
                      color: AppColors.success,
                      icon: Icons.check_circle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // ── Search Bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _woSearchController,
              onChanged: (value) {
                setState(() {});
                context.read<WorkOrderProvider>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'البحث بالوصف أو الفني أو المركبة...',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textHint, size: 20),
                suffixIcon: _woSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textHint, size: 18),
                        onPressed: () {
                          _woSearchController.clear();
                          setState(() {});
                          context
                              .read<WorkOrderProvider>()
                              .setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ),

        // ── Status Filter Chips ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildWoStatusChip('الكل', 'all'),
                _buildWoStatusChip('مفتوح', 'open'),
                _buildWoStatusChip('قيد التنفيذ', 'in_progress'),
                _buildWoStatusChip('مكتمل', 'completed'),
              ],
            ),
          ),
        ),

        // ── Type Filter Chips ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildWoTypeChip('الكل', 'all'),
                _buildWoTypeChip('صيانة', 'maintenance'),
                _buildWoTypeChip('إصلاح', 'repair'),
                _buildWoTypeChip('فحص', 'inspection'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        // ── Orders List ──
        Expanded(
          child: Consumer<WorkOrderProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.allOrders.isEmpty) {
                return const LoadingWidget(
                    message: 'جاري تحميل أوامر العمل...');
              }

              if (provider.orders.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.assignment_outlined,
                  title: 'لا توجد أوامر عمل',
                  subtitle: 'أنشئ أمر عمل جديد لتتبع الصيانة والإصلاحات',
                  actionText: 'أمر عمل جديد',
                  onAction: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddWorkOrderScreen(),
                      ),
                    );
                    if (result == true) {
                      provider.loadOrders();
                    }
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadOrders(),
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: provider.orders.length,
                  itemBuilder: (context, index) {
                    final order = provider.orders[index];
                    return _buildWorkOrderCard(order);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWoStatusChip(String label, String value) {
    final isSelected = _woStatusFilter == value;
    final color = _woStatusColor(value);
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
          setState(() => _woStatusFilter = value);
          context.read<WorkOrderProvider>().setStatusFilter(value);
        },
        backgroundColor: AppColors.surface,
        selectedColor: color,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide(color: isSelected ? color : AppColors.border),
      ),
    );
  }

  Widget _buildWoTypeChip(String label, String value) {
    final isSelected = _woTypeFilter == value;
    final color = value == 'all'
        ? AppColors.primary
        : value == 'maintenance'
            ? AppColors.primary
            : value == 'repair'
                ? AppColors.accent
                : AppColors.info;
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
          setState(() => _woTypeFilter = value);
          context.read<WorkOrderProvider>().setTypeFilter(value);
        },
        backgroundColor: AppColors.surface,
        selectedColor: color,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide(color: isSelected ? color : AppColors.border),
      ),
    );
  }

  Widget _buildWorkOrderCard(WorkOrder order) {
    final statusColor = _woStatusColor(order.status);
    final typeColor = _woTypeColor(order.type);
    final priorityColor = AppConstants.priorityColors[order.priority] ??
        AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkOrderDetailsScreen(workOrder: order),
            ),
          );
          if (result == true) {
            context.read<WorkOrderProvider>().loadOrders();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: vehicle + status ──
            Row(
              children: [
                // Vehicle name
                Expanded(
                  child: Text(
                    order.vehicle != null
                        ? '${order.vehicle!.make} ${order.vehicle!.model}'
                        : 'مركبة #${order.vehicleId}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _woStatusIcon(order.status),
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        order.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Plate number ──
            if (order.vehicle != null)
              Text(
                order.vehicle!.plateNumber,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            const SizedBox(height: 8),

            // ── Description (truncated) ──
            if (order.description != null && order.description!.isNotEmpty) ...[
              Text(
                order.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Bottom row: type, priority, technician, cost ──
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Type chip
                _CardBadge(
                  icon: _woTypeIcon(order.type),
                  label: order.typeLabel,
                  color: typeColor,
                ),
                // Priority chip
                _CardBadge(
                  icon: AppHelpers.getPriorityIcon(order.priority),
                  label: AppConstants.priorities[order.priority] ?? '',
                  color: priorityColor,
                ),
                // Technician
                if (order.technicianName != null)
                  _CardBadge(
                    icon: Icons.person_outline,
                    label: order.technicianName!,
                    color: AppColors.textSecondary,
                  ),
                // Cost
                if (order.estimatedCost != null)
                  _CardBadge(
                    icon: Icons.attach_money,
                    label:
                        '${order.estimatedCost!.toStringAsFixed(0)} ج.م',
                    color: AppColors.primary,
                  ),
              ],
            ),

            // ── Date + over-budget warning ──
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  _getRelativeDate(order.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                const Spacer(),
                if (order.isOverBudget)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning,
                            size: 10, color: AppColors.error),
                        const SizedBox(width: 3),
                        const Text(
                          'تجاوز الميزانية',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
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
    );
  }

  // ── Work order color/icon helpers ──
  static Color _woStatusColor(String status) {
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

  static IconData _woStatusIcon(String status) {
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

  static Color _woTypeColor(String type) {
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

  static IconData _woTypeIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.build;
      case 'repair':
        return Icons.Handyman;
      case 'inspection':
        return Icons.fact_check;
      default:
        return Icons.build;
    }
  }

  static String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    if (diff == -1) return 'غداً';
    if (diff > 0 && diff < 7) return 'منذ $diff أيام';
    if (diff < 0 && diff > -7) return 'بعد ${-diff} أيام';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Small badge used inside work order cards ──
class _CardBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CardBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
