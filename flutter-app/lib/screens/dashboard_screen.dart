import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../providers/vehicle_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<MaintenanceRecord> _recentRecords = [];
  List<MaintenanceRecord> _upcomingRecords = [];
  bool _isLoading = true;
  String? _error;

  final _searchController = TextEditingController();
  List<Vehicle> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final stats = await DatabaseService.getDashboardStats();
      final records = await DatabaseService.getAllMaintenanceRecords();
      final sorted = List<MaintenanceRecord>.from(records)
        ..sort((a, b) => a.maintenanceDate.compareTo(b.maintenanceDate));

      final now = DateTime.now();
      final upcoming = sorted
          .where((r) =>
              (r.status == 'pending' || r.status == 'in_progress') &&
              (r.nextMaintenanceDate == null || !r.nextMaintenanceDate!.isBefore(now)))
          .take(5)
          .toList();

      if (mounted) {
        setState(() {
          _stats = stats;
          _recentRecords = records.take(5).toList();
          _upcomingRecords = upcoming;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذر تحميل البيانات. تحقق من اتصال الإنترنت.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await DatabaseService.searchVehicles(query.trim());
      if (mounted) setState(() { _searchResults = results; _isSearching = false; });
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showSearchResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchResultsSheet(
        results: _searchResults,
        isSearching: _isSearching,
        query: _searchController.text,
      ),
    );
  }

  // Safe helper to get double from stats
  double _getStatDouble(String key) {
    final val = _stats[key];
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is num) return val.toDouble();
    return 0.0;
  }

  int _getStatInt(String key) {
    final val = _stats[key];
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.userMetadata?['display_name'] ??
        auth.user?.email?.split('@').first ?? 'المدير';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 140),
          children: [
            _buildGreetingHeader(userName),
            _buildQuickSearch(),
            const SizedBox(height: 8),
            _buildKPICards(),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 12),
            if (isWide) _buildWideCharts() else _buildNarrowCharts(),
            const SizedBox(height: 8),
            if (isWide) _buildWideSections() else _buildNarrowSections(),
          ],
        ),
      ),
    );
  }

  // ── Loading State ──────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.local_shipping, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          const SizedBox(height: 12),
          const Text('جاري تحميل البيانات...', style: TextStyle(fontSize: 14, color: AppColors.textHint, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text('حدث خطأ في تحميل البيانات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Greeting Header ─────────────────────────────────────────────────────

  Widget _buildGreetingHeader(String userName) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) { greeting = 'صباح الخير'; }
    else if (hour < 17) { greeting = 'مساء الخير'; }
    else { greeting = 'مساء النور'; }

    final arabicDate = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);
    final urgentCount = _getStatInt('urgentRecords');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                    const SizedBox(height: 6),
                    Text(arabicDate, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (urgentCount > 0)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                      const SizedBox(height: 4),
                      Text('$urgentCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('تنبيه عاجل', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick Search ───────────────────────────────────────────────────────

  Widget _buildQuickSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            if (value.length >= 1) { _performSearch(value); }
            else { setState(() { _searchResults = []; }); }
          },
          onSubmitted: (_) {
            if (_searchController.text.trim().isNotEmpty) { _performSearch(_searchController.text); _showSearchResults(); }
          },
          decoration: InputDecoration(
            hintText: 'ابحث عن مركبة بالاسم أو الرقم...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint, fontWeight: FontWeight.w500),
            prefixIcon: _isSearching
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                : const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 20),
                    onPressed: () { _performSearch(_searchController.text); _showSearchResults(); },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── KPI Cards ──────────────────────────────────────────────────────────

  Widget _buildKPICards() {
    final vehicleCount = _getStatInt('vehicleCount');
    final activeVehicles = _getStatInt('activeVehicles');
    final maintenanceVehicles = _getStatInt('maintenanceVehicles');
    final urgentRecords = _getStatInt('urgentRecords');
    final pendingRecords = _getStatInt('pendingRecords');
    final thisMonthCost = _getStatDouble('thisMonthCost');

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildKPICard('إجمالي المركبات', '$vehicleCount', Icons.directions_car, AppColors.primary, '$activeVehicles نشطة'),
          const SizedBox(width: 10),
          _buildKPICard('في الصيانة', '$maintenanceVehicles', Icons.build_circle_outlined, AppColors.warning, '$urgentRecords عاجلة'),
          const SizedBox(width: 10),
          _buildKPICard('تنبيهات عاجلة', '$urgentRecords', Icons.notifications_active, AppColors.error, '$pendingRecords معلقة'),
          const SizedBox(width: 10),
          _buildKPICard('تكاليف الشهر', AppFormatters.formatCurrencyCompact(thisMonthCost), Icons.account_balance_wallet, AppColors.accent, 'مقارنة بالسابق'),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: const Offset(0, 2))],
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1.1))),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textHint), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('إجراءات سريعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          Row(
            children: [
              Expanded(child: _QuickActionCard(icon: Icons.add_circle_outline, label: 'إضافة مركبة', color: AppColors.primary, gradient: [AppColors.primary, AppColors.primaryLight], onTap: () => Navigator.pushNamed(context, '/add-vehicle'))),
              const SizedBox(width: 10),
              Expanded(child: _QuickActionCard(icon: Icons.build, label: 'إضافة صيانة', color: AppColors.accent, gradient: [AppColors.accent, AppColors.accentLight], onTap: () => Navigator.pushNamed(context, '/add-maintenance'))),
              const SizedBox(width: 10),
              Expanded(child: _QuickActionCard(icon: Icons.assignment, label: 'أمر عمل', color: AppColors.info, gradient: [AppColors.info, const Color(0xFF60A5FA)], onTap: () => Navigator.pushNamed(context, '/add-work-order'))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _QuickActionCard(icon: Icons.bar_chart, label: 'التقارير', color: AppColors.success, gradient: [AppColors.success, const Color(0xFF4ADE80)], onTap: () => widget.onNavigateToTab?.call(5))),
              const SizedBox(width: 10),
              Expanded(child: _QuickActionCard(icon: Icons.location_on, label: 'تتبع GPS', color: AppColors.info, gradient: [AppColors.info, const Color(0xFF60A5FA)], onTap: () => Navigator.pushNamed(context, '/gps-map'))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Charts ──────────────────────────────────────────────────────────────

  Widget _buildWideCharts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildMonthlyCostChart()),
          const SizedBox(width: 12),
          Expanded(child: _buildTypePieChart()),
        ],
      ),
    );
  }

  Widget _buildNarrowCharts() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildMonthlyCostChart()),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildTypePieChart()),
      ],
    );
  }

  Widget _buildMonthlyCostChart() {
    return _SectionCard(
      title: 'التكاليف الشهرية',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseService.getMonthlyCosts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox(height: 160, child: Center(child: Text('خطأ في تحميل البيانات', style: TextStyle(fontSize: 13, color: AppColors.textHint))));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) return const SizedBox(height: 160, child: Center(child: Text('لا توجد بيانات', style: TextStyle(fontSize: 13, color: AppColors.textHint))));

          double maxCost = 0;
          for (final item in data) { final c = (item['total_cost'] as num?)?.toDouble() ?? 0; if (c > maxCost) maxCost = c; }
          maxCost = maxCost > 0 ? maxCost * 1.2 : 1000;

          return SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCost,
                barGroups: data.asMap().entries.map((entry) {
                  final cost = (entry.value['total_cost'] as num?)?.toDouble() ?? 0;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [BarChartRodData(toY: cost, gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.bottomCenter, end: Alignment.topCenter), borderRadius: const BorderRadius.vertical(top: Radius.circular(6)), width: 20)],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(AppFormatters.formatCurrencyCompact(value), style: const TextStyle(fontSize: 9, color: AppColors.textHint));
                  })),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                    final parts = (data[idx]['month'] as String? ?? '').split('-');
                    return Text(parts.length == 2 ? parts[1] : '', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                  })),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [4, 4])),
                borderData: FlBorderData(show: false),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypePieChart() {
    return _SectionCard(
      title: 'توزيع الصيانة',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseService.getMaintenanceByType(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox(height: 160, child: Center(child: Text('خطأ في تحميل البيانات', style: TextStyle(fontSize: 13, color: AppColors.textHint))));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 160, child: Center(child: Text('لا توجد بيانات', style: TextStyle(fontSize: 13, color: AppColors.textHint))));
          final data = snapshot.data!;
          final total = data.fold<double>(0, (sum, item) => sum + ((item['total_cost'] as num?)?.toDouble() ?? 0));

          return Column(
            children: [
              SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sections: data.map((item) {
                      final cost = (item['total_cost'] as num?)?.toDouble() ?? 0;
                      final pct = total > 0 ? (cost / total) * 100 : 0;
                      final type = item['type'] as String? ?? 'other';
                      final color = AppConstants.maintenanceTypeColors[type] ?? AppColors.otherColor;
                      return PieChartSectionData(value: cost, title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white), color: color, radius: 55);
                    }).toList(),
                    sectionsSpace: 2, centerSpaceRadius: 35,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10, runSpacing: 4,
                children: data.map((item) {
                  final type = item['type'] as String? ?? 'other';
                  final color = AppConstants.maintenanceTypeColors[type] ?? AppColors.otherColor;
                  final label = AppConstants.maintenanceTypes[type] ?? '';
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ]);
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Activity Sections ──────────────────────────────────────────────────

  Widget _buildWideSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildUpcomingMaintenance()),
          const SizedBox(width: 12),
          Expanded(child: _buildRecentActivity()),
        ],
      ),
    );
  }

  Widget _buildNarrowSections() {
    return Column(
      children: [
        _buildUpcomingMaintenance(),
        const SizedBox(height: 12),
        _buildRecentActivity(),
      ],
    );
  }

  Widget _buildUpcomingMaintenance() {
    return _SectionCard(
      title: 'الصيانة القادمة',
      trailing: TextButton(
        onPressed: () => widget.onNavigateToTab?.call(2),
        child: const Text('عرض الكل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ),
      child: _upcomingRecords.isEmpty
          ? _buildEmpty('لا توجد صيانات قادمة', Icons.event_available_outlined)
          : Column(children: _upcomingRecords.map((r) => _buildMaintenanceItem(r)).toList()),
    );
  }

  Widget _buildRecentActivity() {
    return _SectionCard(
      title: 'أحدث النشاطات',
      trailing: TextButton(
        onPressed: () => widget.onNavigateToTab?.call(2),
        child: const Text('عرض الكل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ),
      child: _recentRecords.isEmpty
          ? _buildEmpty('لا توجد سجلات بعد', Icons.history)
          : Column(children: _recentRecords.map((r) => _buildActivityItem(r)).toList()),
    );
  }

  Widget _buildMaintenanceItem(MaintenanceRecord record) {
    final priorityColor = AppConstants.priorityColors[record.priority] ?? AppColors.textHint;
    final plateNumber = record.vehicle?.plateNumber ?? 'مركبة #${record.vehicleId}';
    final typeName = AppConstants.maintenanceTypes[record.type] ?? record.description;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 4, height: 36, decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plateNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(typeName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppFormatters.formatCurrency(record.totalCost), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(AppFormatters.formatDate(record.maintenanceDate), style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(MaintenanceRecord record) {
    final statusColor = AppConstants.maintenanceStatusColors[record.status] ?? AppColors.textHint;
    final statusLabel = AppConstants.maintenanceStatuses[record.status] ?? '';
    final plateNumber = record.vehicle?.plateNumber ?? 'مركبة #${record.vehicleId}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plateNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(record.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.textHint.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// ── Section Card ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: const Offset(0, 2))],
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Quick Action Card ────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
            color: color.withOpacity(0.06),
          ),
          child: Column(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search Results Sheet ─────────────────────────────────────────────────

class _SearchResultsSheet extends StatelessWidget {
  final List<Vehicle> results;
  final bool isSearching;
  final String query;

  const _SearchResultsSheet({required this.results, required this.isSearching, required this.query});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, minChildSize: 0.25, maxChildSize: 0.85, expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.only(top: 12), child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('نتائج البحث عن "$query"', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                    if (!isSearching)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                        child: Text('${results.length} نتيجة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: isSearching
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : results.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.search_off, size: 48, color: AppColors.textHint.withOpacity(0.4)),
                            SizedBox(height: 12),
                            Text('لا توجد نتائج', style: TextStyle(fontSize: 14, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                            SizedBox(height: 4),
                            Text('جرب البحث بكلمات مختلفة', style: TextStyle(fontSize: 12, color: AppColors.textHint.withOpacity(0.7))),
                          ]))
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) => _VehicleResultCard(vehicle: results[index]),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Vehicle Result Card ──────────────────────────────────────────────────

class _VehicleResultCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleResultCard({required this.vehicle});

  Color get _statusColor {
    switch (vehicle.status) {
      case 'active': return AppColors.success;
      case 'maintenance': return AppColors.warning;
      case 'inactive': return AppColors.error;
      default: return AppColors.textHint;
    }
  }

  String get _statusLabel {
    switch (vehicle.status) {
      case 'active': return 'نشطة';
      case 'maintenance': return 'في الصيانة';
      case 'inactive': return 'غير نشطة';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/vehicle-details', arguments: vehicle); },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.directions_car, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.driverName != null && vehicle.driverName!.isNotEmpty ? vehicle.driverName! : vehicle.plateNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text('${vehicle.make} ${vehicle.model} - ${vehicle.plateNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text(_statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor)),
                  ),
                  const SizedBox(height: 4),
                  Text('${vehicle.currentOdometer} كم', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
