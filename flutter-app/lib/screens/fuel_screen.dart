import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fuel_record.dart';
import '../models/vehicle.dart';
import '../providers/fuel_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/stat_card.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  String _vehicleFilterLabel = 'جميع المركبات';
  int? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final fuelProvider = context.read<FuelProvider>();
    final vehicleProvider = context.read<VehicleProvider>();
    if (vehicleProvider.allVehicles.isEmpty) {
      await vehicleProvider.loadVehicles();
    }
    await fuelProvider.loadFuelRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الوقود'),
        actions: [
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_list_outlined),
            onSelected: (vehicleId) {
              setState(() {
                _selectedVehicleId = vehicleId;
                final vehicles = context.read<VehicleProvider>().allVehicles;
                if (vehicleId == null) {
                  _vehicleFilterLabel = 'جميع المركبات';
                } else {
                  final v = vehicles.firstWhere(
                    (v) => v.id == vehicleId,
                    orElse: () => Vehicle(
                      plateNumber: '',
                      make: '',
                      model: '',
                      year: 2024,
                      color: 'white',
                      fuelType: 'petrol',
                      currentOdometer: 0,
                      status: 'active',
                    ),
                  );
                  _vehicleFilterLabel = v.plateNumber.isNotEmpty
                      ? '${v.make} ${v.model} - ${v.plateNumber}'
                      : 'مركبة غير معروفة';
                }
              });
              context
                  .read<FuelProvider>()
                  .setVehicleFilter(vehicleId);
            },
            itemBuilder: (context) {
              final vehicles =
                  context.watch<VehicleProvider>().allVehicles;
              return [
                const PopupMenuItem<int?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.directions_car, size: 18),
                      SizedBox(width: 8),
                      Text('جميع المركبات'),
                    ],
                  ),
                ),
                if (vehicles.isNotEmpty) const PopupMenuDivider(),
                ...vehicles.map((v) => PopupMenuItem<int?>(
                      value: v.id,
                      child: Row(
                        children: [
                          Icon(Icons.directions_car, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${v.make} ${v.model} - ${v.plateNumber}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
              ];
            },
          ),
        ],
      ),
      body: Consumer<FuelProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingWidget(
              message: 'جاري تحميل سجلات الوقود...',
            );
          }

          if (provider.fuelRecords.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.local_gas_station_outlined,
              title: 'لا توجد سجلات وقود',
              subtitle: 'أضف سجل تعبئة وقود جديد',
              actionText: 'إضافة سجل وقود',
              onAction: () {
                Navigator.pushNamed(context, '/add-fuel');
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadFuelRecords(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Summary Cards
                SliverToBoxAdapter(
                  child: _buildSummaryCards(provider),
                ),
                // Consumption Chart
                SliverToBoxAdapter(
                  child: _buildConsumptionChart(provider),
                ),
                // Vehicle Filter Label
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          _vehicleFilterLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${provider.fuelRecords.length} سجل)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Fuel Records List
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = provider.fuelRecords[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildFuelRecordCard(
                              record, provider),
                        );
                      },
                      childCount: provider.fuelRecords.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-fuel');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ──────────────────────────── Summary Cards ────────────────────────────

  Widget _buildSummaryCards(FuelProvider provider) {
    final totalCost = provider.fuelRecords.fold<double>(
        0.0, (sum, r) => sum + r.totalCost);
    final avgConsumption = _calculateAverageConsumption(provider.fuelRecords);
    final alertCount = provider.fuelRecords
        .where((r) => r.isAbnormal == true)
        .length;

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          StatCard(
            title: 'إجمالي التكلفة',
            value: AppFormatters.formatCurrencyCompact(totalCost),
            icon: Icons.attach_money,
            color: AppColors.primary,
            subtitle: 'هذا الشهر',
          ),
          const SizedBox(width: 12),
          StatCard(
            title: 'متوسط الاستهلاك',
            value: avgConsumption > 0
                ? '${avgConsumption.toStringAsFixed(1)} لتر'
                : '—',
            icon: Icons.speed,
            color: AppColors.info,
            subtitle: 'لتر/100كم',
          ),
          const SizedBox(width: 12),
          StatCard(
            title: 'عدد التعبئات',
            value: provider.fuelRecords.length.toString(),
            icon: Icons.local_gas_station,
            color: AppColors.accent,
            subtitle: 'هذا الشهر',
          ),
          const SizedBox(width: 12),
          StatCard(
            title: 'تنبيهات',
            value: alertCount.toString(),
            icon: Icons.warning_amber_rounded,
            color: alertCount > 0 ? AppColors.error : AppColors.success,
            subtitle: alertCount > 0 ? 'استهلاك غير طبيعي' : 'لا توجد تنبيهات',
          ),
        ],
      ),
    );
  }

  double _calculateAverageConsumption(List<FuelRecord> records) {
    final withConsumption =
        records.where((r) => r.consumptionRate != null && r.consumptionRate! > 0).toList();
    if (withConsumption.isEmpty) return 0.0;
    return withConsumption
            .fold<double>(0.0, (sum, r) => sum + r.consumptionRate!) /
        withConsumption.length;
  }

  // ──────────────────────────── Consumption Chart ────────────────────────────

  Widget _buildConsumptionChart(FuelProvider provider) {
    final vehicles = context.read<VehicleProvider>().allVehicles;
    final filteredRecords = _selectedVehicleId != null
        ? provider.fuelRecords
            .where((r) => r.vehicleId == _selectedVehicleId)
            .toList()
        : provider.fuelRecords;

    // Group consumption rates by vehicle
    final Map<int, List<double>> vehicleConsumption = {};
    for (final record in filteredRecords) {
      if (record.consumptionRate != null && record.consumptionRate! > 0) {
        vehicleConsumption.putIfAbsent(record.vehicleId, () => []);
        vehicleConsumption[record.vehicleId]!.add(record.consumptionRate!);
      }
    }

    if (vehicleConsumption.isEmpty) {
      return const SizedBox.shrink();
    }

    final chartColors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
      AppColors.success,
      AppColors.error,
      AppColors.oilColor,
      AppColors.brakesColor,
      AppColors.electricalColor,
    ];

    double maxConsumption = 0;
    final barGroups = <BarChartGroupData>[];
    int groupIndex = 0;

    vehicleConsumption.forEach((vehicleId, rates) {
      final avg = rates.reduce((a, b) => a + b) / rates.length;
      if (avg > maxConsumption) maxConsumption = avg;

      final vehicle = vehicles.firstWhere(
        (v) => v.id == vehicleId,
        orElse: () => Vehicle(
          plateNumber: '',
          make: '',
          model: '',
          year: 2024,
          color: 'white',
          fuelType: 'petrol',
          currentOdometer: 0,
          status: 'active',
        ),
      );

      barGroups.add(
        BarChartGroupData(
          x: groupIndex,
          barRods: [
            BarChartRodData(
              toY: avg,
              color: chartColors[groupIndex % chartColors.length],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              width: 28,
            ),
          ],
          barsSpace: 4,
        ),
      );
      groupIndex++;
    });

    maxConsumption = maxConsumption * 1.2;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'متوسط الاستهلاك حسب المركبة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'لتر/100كم',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxConsumption > 0 ? maxConsumption : 20,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryDark,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final vid = vehicleConsumption.keys.elementAt(group.x);
                      final v = vehicles.firstWhere(
                        (v) => v.id == vid,
                        orElse: () => Vehicle(
                          plateNumber: '',
                          make: '',
                          model: '',
                          year: 2024,
                          color: 'white',
                          fuelType: 'petrol',
                          currentOdometer: 0,
                          status: 'active',
                        ),
                      );
                      return BarTooltipItem(
                        '${v.plateNumber.isNotEmpty ? v.plateNumber : "مركبة $vid"}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${rod.toY.toStringAsFixed(1)} لتر/100كم',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final vid = vehicleConsumption.keys
                            .elementAt(value.toInt());
                        final v = vehicles.firstWhere(
                          (v) => v.id == vid,
                          orElse: () => Vehicle(
                            plateNumber: '',
                            make: '',
                            model: '',
                            year: 2024,
                            color: 'white',
                            fuelType: 'petrol',
                            currentOdometer: 0,
                            status: 'active',
                          ),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            v.plateNumber.isNotEmpty
                                ? v.plateNumber
                                : '$vid',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                      reservedSize: 36,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxConsumption > 0
                      ? maxConsumption / 5
                      : 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── Fuel Record Card ────────────────────────────

  Widget _buildFuelRecordCard(FuelRecord record, FuelProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: record.isAbnormal == true
            ? Border.all(color: AppColors.error.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Vehicle + Date + Abnormal Badge
          Row(
            children: [
              // Fuel type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getFuelTypeColor(record.fuelType)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getFuelTypeIcon(record.fuelType),
                  color: _getFuelTypeColor(record.fuelType),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Vehicle info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.vehicle?.plateNumber ?? 'مركبة #${record.vehicleId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.vehicle?.make ?? ''} ${record.vehicle?.model ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatDate(record.fillDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (record.isAbnormal == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⚠ استهلاك غير طبيعي',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Details Row
          Row(
            children: [
              _buildDetailItem(
                icon: Icons.water_drop,
                label: 'الكمية',
                value: '${record.liters.toStringAsFixed(1)} لتر',
              ),
              const SizedBox(width: 20),
              _buildDetailItem(
                icon: Icons.monetization_on,
                label: 'التكلفة',
                value: AppFormatters.formatCurrency(record.totalCost),
              ),
              const Spacer(),
              if (record.consumptionRate != null &&
                  record.consumptionRate! > 0)
                _buildDetailItem(
                  icon: Icons.speed,
                  label: 'الاستهلاك',
                  value:
                      '${record.consumptionRate!.toStringAsFixed(1)} لتر/100كم',
                  valueColor: record.isAbnormal == true
                      ? AppColors.error
                      : null,
                ),
            ],
          ),
          // Actions Row
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (record.stationName != null &&
                  record.stationName!.isNotEmpty) ...[
                Icon(Icons.ev_station,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  record.stationName!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 12),
              ],
              if (record.fullTank)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'خزان كامل',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              // Edit
              InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/add-fuel',
                    arguments: record,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Delete
              InkWell(
                onTap: () => _confirmDelete(
                    context, record.id!, provider),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getFuelTypeColor(String fuelType) {
    switch (fuelType) {
      case 'petrol':
        return AppColors.accent;
      case 'diesel':
        return AppColors.info;
      case 'electric':
        return AppColors.success;
      case 'hybrid':
        return AppColors.primary;
      case 'gas':
        return AppColors.oilColor;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getFuelTypeIcon(String fuelType) {
    switch (fuelType) {
      case 'petrol':
        return Icons.local_gas_station;
      case 'diesel':
        return Icons.oil_barrel;
      case 'electric':
        return Icons.bolt;
      case 'hybrid':
        return Icons.electric_car;
      case 'gas':
        return Icons.propane_tank;
      default:
        return Icons.local_gas_station;
    }
  }

  // ──────────────────────────── Confirm Delete ────────────────────────────

  void _confirmDelete(
      BuildContext context, int id, FuelProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('حذف السجل'),
        content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteFuelRecord(id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف السجل بنجاح'),
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
