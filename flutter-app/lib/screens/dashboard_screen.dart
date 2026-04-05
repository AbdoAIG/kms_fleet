import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/maintenance_record.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/stat_card.dart';
import '../widgets/maintenance_card.dart';
import '../providers/vehicle_provider.dart';
import '../providers/maintenance_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<MaintenanceRecord> _recentRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await DatabaseService.getDashboardStats();
      final records = await DatabaseService.getAllMaintenanceRecords();
      setState(() {
        _stats = stats;
        _recentRecords = records.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              // Stats Grid
              if (!_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.65,
                    ),
                    delegate: SliverChildListDelegate([
                      StatCard(
                        title: 'إجمالي المركبات',
                        value: AppFormatters.formatNumber(
                            _stats['vehicleCount'] as int? ?? 0),
                        icon: Icons.directions_car,
                        color: AppColors.primary,
                        subtitle:
                            '${_stats['activeVehicles'] as int? ?? 0} نشطة',
                      ),
                      StatCard(
                        title: 'تكاليف الصيانة',
                        value: AppFormatters.formatCurrencyCompact(
                            _stats['totalCost'] as double? ?? 0),
                        icon: Icons.attach_money,
                        color: AppColors.accent,
                        subtitle: 'إجمالي مكتمل',
                      ),
                      StatCard(
                        title: 'معلقة',
                        value: '${_stats['pendingRecords'] as int? ?? 0}',
                        icon: Icons.schedule,
                        color: AppColors.warning,
                        subtitle:
                            '${_stats['inProgressRecords'] as int? ?? 0} قيد التنفيذ',
                      ),
                      StatCard(
                        title: 'تكلفة هذا الشهر',
                        value: AppFormatters.formatCurrencyCompact(
                            _stats['thisMonthCost'] as double? ?? 0),
                        icon: Icons.trending_up,
                        color: _stats['thisMonthCost'] != null &&
                                (_stats['thisMonthCost'] as double) >
                                    (_stats['lastMonthCost'] as double? ?? 0)
                            ? AppColors.error
                            : AppColors.success,
                        subtitle: 'مقارنة بالشهر السابق',
                      ),
                    ]),
                  ),
                ),
              // Quick Actions
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),
              // Maintenance Type Chart
              SliverToBoxAdapter(
                child: _buildTypeChart(),
              ),
              // Recent Records
              SliverToBoxAdapter(
                child: _buildRecentRecords(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppConstants.appNameAr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'نظام إدارة صيانة الأسطول',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_none,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'تنبيهات',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if ((_stats['urgentRecords'] as int? ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_stats['urgentRecords'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_circle_outline,
                  label: 'إضافة مركبة',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pushNamed(context, '/add-vehicle');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.build,
                  label: 'طلب صيانة',
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.pushNamed(context, '/add-maintenance');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.search,
                  label: 'بحث شامل',
                  color: AppColors.info,
                  onTap: () {
                    // Navigate to maintenance with search
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService.getMaintenanceByType(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final total = data.fold<double>(
            0, (sum, item) => sum + ((item['total_cost'] as num?)?.toDouble() ?? 0));

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.border, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'توزيع الصيانة حسب النوع',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sections: data.map((item) {
                          final cost =
                              (item['total_cost'] as num?)?.toDouble() ?? 0;
                          final pct = total > 0 ? (cost / total) * 100 : 0;
                          final type = item['type'] as String? ?? 'other';
                          return PieChartSectionData(
                            value: cost,
                            title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '',
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            color: AppConstants.maintenanceTypeColors[type] ??
                                AppColors.otherColor,
                            radius: 60,
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: data.map((item) {
                      final type = item['type'] as String? ?? 'other';
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppConstants.maintenanceTypeColors[type] ??
                                  AppColors.otherColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppConstants.maintenanceTypes[type] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentRecords() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'أحدث سجلات الصيانة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to maintenance tab - handled by MainScreen
                },
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recentRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'لا توجد سجلات صيانة بعد',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ..._recentRecords.map((record) => MaintenanceCard(
                  record: record,
                  onTap: () {},
                )),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
