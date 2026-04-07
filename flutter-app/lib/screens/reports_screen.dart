import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/report_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  String? _error;
  bool _isSyncing = false;
  List<Map<String, dynamic>> _typeData = [];
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _vehicleData = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait<dynamic>([
        DatabaseService.getMaintenanceByType(),
        DatabaseService.getMonthlyCosts(),
        DatabaseService.getVehicleMaintenanceCosts(),
        DatabaseService.getDashboardStats(),
      ]);
      setState(() {
        _typeData = (results[0] as List<Map<String, dynamic>>);
        _monthlyData = (results[1] as List<Map<String, dynamic>>).reversed.toList();
        _vehicleData = (results[2] as List<Map<String, dynamic>>);
        _stats = (results[3] as Map<String, dynamic>);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذر تحميل التقارير. تحقق من اتصال الإنترنت.';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    try {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث البيانات بنجاح ✅'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحديث: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleExport(String type) async {
    try {
      String path = '';
      String label = '';
      switch (type) {
        case 'maintenance_pdf':
          path = await ReportService.generateMaintenancePDF();
          label = 'تقرير الصيانة';
          break;
        case 'vehicles_pdf':
          path = await ReportService.generateVehiclesPDF();
          label = 'تقرير السيارات';
          break;
        case 'fuel_excel':
          path = await ReportService.generateFuelExcel();
          label = 'تقرير الوقود';
          break;
        case 'work_orders_pdf':
          path = await ReportService.generateWorkOrdersPDF();
          label = 'تقرير أوامر العمل';
          break;
        case 'monthly_cost_pdf':
          path = await ReportService.generateMonthlyCostPDF();
          label = 'تقرير التكاليف الشهرية';
          break;
        case 'comprehensive_excel':
          path = await ReportService.generateComprehensiveExcel();
          label = 'تصدير شامل للمحاسبين';
          break;
      }
      if (path.isNotEmpty && mounted) {
        // On desktop, path is the full file path; on mobile, it's just the file name
        final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
        final msg = isDesktop
            ? 'تم حفظ $label بنجاح ✅\n$path'
            : 'تم حفظ $label بنجاح ✅';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: isDesktop ? 5 : 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التصدير: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 500;
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  // ── Page Title ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          const Text(
                            'التقارير والإحصائيات',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          // Sync button
                          InkWell(
                            onTap: _isSyncing ? null : _syncData,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isSyncing
                                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                  : const Icon(Icons.sync, size: 18, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Export Report Cards ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildExportCards(isWide),
                    ),
                  ),

                  // ── Summary Cards ──
                  SliverToBoxAdapter(child: _buildSummaryCards(isWide)),

                  // ── Monthly Cost Chart ──
                  SliverToBoxAdapter(child: _buildMonthlyChart()),

                  // ── Type Distribution ──
                  SliverToBoxAdapter(child: _buildTypeChart()),

                  // ── Vehicle Cost Table ──
                  SliverToBoxAdapter(child: _buildVehicleTable()),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
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

  // ── Export Cards ──

  Widget _buildExportCards(bool isWide) {
    final exportItems = [
      _ExportItem(
        title: 'تقرير الصيانة',
        description: 'تقرير مفصل بجميع سجلات الصيانة والتكاليف',
        icon: Icons.picture_as_pdf,
        format: 'PDF',
        formatColor: AppColors.error,
        type: 'maintenance_pdf',
      ),
      _ExportItem(
        title: 'تقرير الأسطول',
        description: 'تقرير شامل عن حالة ومعلومات الأسطول',
        icon: Icons.directions_car,
        format: 'PDF',
        formatColor: AppColors.error,
        type: 'vehicles_pdf',
      ),
      _ExportItem(
        title: 'سجلات الوقود',
        description: 'بيانات استهلاك الوقود والتكاليف',
        icon: Icons.table_chart,
        format: 'Excel',
        formatColor: AppColors.success,
        type: 'fuel_excel',
      ),
      _ExportItem(
        title: 'تقرير أوامر العمل',
        description: 'تقرير مفصل بأوامر العمل والتكاليف',
        icon: Icons.assignment,
        format: 'PDF',
        formatColor: AppColors.error,
        type: 'work_orders_pdf',
      ),
      _ExportItem(
        title: 'تقرير التكاليف الشهرية',
        description: 'تكاليف كل سيارة مقسمة حسب الشهر',
        icon: Icons.calendar_month,
        format: 'PDF',
        formatColor: AppColors.error,
        type: 'monthly_cost_pdf',
      ),
      _ExportItem(
        title: 'تصدير شامل للمحاسبين',
        description: 'ملف Excel شامل بجميع بيانات الأسطول',
        icon: Icons.account_balance,
        format: 'Excel',
        formatColor: AppColors.success,
        type: 'comprehensive_excel',
      ),
    ];

    if (isWide) {
      return Row(
        children: exportItems
            .map((item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildExportCard(item),
                  ),
                ))
            .toList(),
      );
    }
    return Column(
      children: exportItems
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildExportCard(item),
              ))
          .toList(),
    );
  }

  Widget _buildExportCard(_ExportItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.formatColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.formatColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.formatColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.format,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: item.formatColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _handleExport(item.type),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'تحميل',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary Cards ──

  Widget _buildSummaryCards(bool isWide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص التكاليف',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          if (isWide)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('إجمالي التكاليف', AppFormatters.formatCurrency(_stats['totalCost'] as double? ?? 0), Icons.account_balance_wallet, AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryItem('تكلفة الشهر', AppFormatters.formatCurrency(_stats['thisMonthCost'] as double? ?? 0), Icons.calendar_today, AppColors.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryItem('متوسط/صيانة', AppFormatters.formatCurrency((_stats['totalCost'] as double? ?? 0) / ((_stats['vehicleCount'] as int? ?? 1))), Icons.pie_chart, AppColors.info),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryItem('في الصيانة', '${_stats['maintenanceVehicles'] as int? ?? 0}', Icons.build, AppColors.warning),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('إجمالي التكاليف', AppFormatters.formatCurrency(_stats['totalCost'] as double? ?? 0), Icons.account_balance_wallet, AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryItem('تكلفة الشهر', AppFormatters.formatCurrency(_stats['thisMonthCost'] as double? ?? 0), Icons.calendar_today, AppColors.accent),
                ),
              ],
            ),
          if (!isWide) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('متوسط/صيانة', AppFormatters.formatCurrency((_stats['totalCost'] as double? ?? 0) / ((_stats['vehicleCount'] as int? ?? 1))), Icons.pie_chart, AppColors.info),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryItem('في الصيانة', '${_stats['maintenanceVehicles'] as int? ?? 0}', Icons.build, AppColors.warning),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }

  // ── Monthly Chart ──

  Widget _buildMonthlyChart() {
    if (_monthlyData.isEmpty) return const SizedBox.shrink();

    final maxCost = _monthlyData.fold<double>(0, (max, item) => ((item['total_cost'] as num?)?.toDouble() ?? 0) > max ? ((item['total_cost'] as num?)?.toDouble() ?? 0) : max);
    final safeMaxCost = maxCost > 0 ? maxCost : 1000;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('التكاليف الشهرية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: safeMaxCost * 1.2,
                  barGroups: _monthlyData.map((item) {
                    final cost = (item['total_cost'] as num?)?.toDouble() ?? 0;
                    return BarChartGroupData(
                      x: _monthlyData.indexOf(item),
                      barRods: [
                        BarChartRodData(
                          toY: cost,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            AppFormatters.formatCurrencyCompact(value),
                            style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _monthlyData.length) return const SizedBox.shrink();
                          final month = _monthlyData[index]['month'] as String? ?? '';
                          final parts = month.split('-');
                          return Text(parts.length == 2 ? parts[1] : '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [5, 5]),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Type Chart ──

  Widget _buildTypeChart() {
    if (_typeData.isEmpty) return const SizedBox.shrink();

    final total = _typeData.fold<double>(0, (sum, item) => sum + ((item['total_cost'] as num?)?.toDouble() ?? 0));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('توزيع التكاليف حسب النوع', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ..._typeData.map((item) {
              final type = item['type'] as String? ?? 'other';
              final cost = (item['total_cost'] as num?)?.toDouble() ?? 0;
              final count = item['count'] as int? ?? 0;
              final pct = total > 0 ? (cost / total) * 100 : 0;
              final color = AppConstants.maintenanceTypeColors[type] ?? AppColors.otherColor;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 10),
                        Expanded(child: Text(AppConstants.maintenanceTypes[type] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                        Text(AppFormatters.formatCurrency(cost), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        Text('($count)', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: AppColors.surfaceVariant,
                      color: color,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Vehicle Table ──

  Widget _buildVehicleTable() {
    if (_vehicleData.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تكاليف الصيانة حسب السيارة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('السيارة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                  Expanded(flex: 1, child: Text('العمليات', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                  Expanded(flex: 2, child: Text('التكلفة', textAlign: TextAlign.end, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                ],
              ),
            ),
            ..._vehicleData.map((item) {
              final plate = item['plate_number'] as String? ?? '';
              final make = item['make'] as String? ?? '';
              final model = item['model'] as String? ?? '';
              final count = item['record_count'] as int? ?? 0;
              final cost = (item['total_cost'] as num?)?.toDouble() ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$make $model', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                          Text(plate, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    Expanded(flex: 1, child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                    Expanded(flex: 2, child: Text(AppFormatters.formatCurrency(cost), textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ExportItem {
  final String title;
  final String description;
  final IconData icon;
  final String format;
  final Color formatColor;
  final String type;
  const _ExportItem({required this.title, required this.description, required this.icon, required this.format, required this.formatColor, required this.type});
}
