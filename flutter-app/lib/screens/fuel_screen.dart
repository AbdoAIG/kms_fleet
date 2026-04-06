import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fuel_record.dart';
import '../models/vehicle.dart';
import '../providers/fuel_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/stat_card.dart';
import 'package:fl_chart/fl_chart.dart';

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
      body: Column(
        children: [
          // ── Page Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                const Text(
                  'إدارة الوقود',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Vehicle filter popup
                PopupMenuButton<int?>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.filter_list_outlined, size: 18, color: AppColors.textSecondary),
                  ),
                  onSelected: (vehicleId) {
                    setState(() {
                      _selectedVehicleId = vehicleId;
                      final vehicles = context.read<VehicleProvider>().allVehicles;
                      if (vehicleId == null) {
                        _vehicleFilterLabel = 'جميع المركبات';
                      } else {
                        final v = vehicles.firstWhere(
                          (v) => v.id == vehicleId,
                          orElse: () => Vehicle(plateNumber: '', make: '', model: '', year: 2024, color: 'white', fuelType: 'petrol', currentOdometer: 0, status: 'active'),
                        );
                        _vehicleFilterLabel = v.plateNumber.isNotEmpty ? '${v.make} ${v.model}' : 'مركبة';
                      }
                    });
                    context.read<FuelProvider>().setVehicleFilter(vehicleId);
                  },
                  itemBuilder: (context) {
                    final vehicles = context.watch<VehicleProvider>().allVehicles;
                    return [
                      const PopupMenuItem<int?>(value: null, child: Row(children: [Icon(Icons.directions_car, size: 18), SizedBox(width: 8), Text('جميع المركبات')])),
                      if (vehicles.isNotEmpty) const PopupMenuDivider(),
                      ...vehicles.map((v) => PopupMenuItem<int?>(
                        value: v.id,
                        child: Row(children: [
                          Icon(Icons.directions_car, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${v.make} ${v.model} - ${v.plateNumber}', overflow: TextOverflow.ellipsis)),
                        ]),
                      )),
                    ];
                  },
                ),
              ],
            ),
          ),

          // ── Summary Cards ──
          Expanded(
            child: Consumer<FuelProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingWidget(message: 'جاري تحميل سجلات الوقود...');
                }

                if (provider.fuelRecords.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.local_gas_station_outlined,
                    title: 'لا توجد سجلات وقود',
                    subtitle: 'أضف سجل تعبئة وقود جديد',
                    actionText: 'إضافة سجل وقود',
                    onAction: () => Navigator.pushNamed(context, '/add-fuel'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadFuelRecords(),
                  color: AppColors.primary,
                  child: CustomScrollView(
                    slivers: [
                      // Summary stats row
                      SliverToBoxAdapter(child: _buildSummaryCards(provider)),
                      // Fuel records label
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                          child: Row(
                            children: [
                              Text(
                                _vehicleFilterLabel,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${provider.fuelRecords.length} سجل)',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Fuel records list
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final record = provider.fuelRecords[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildFuelRecordCard(record, provider),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-fuel'),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Summary Cards ──

  Widget _buildSummaryCards(FuelProvider provider) {
    final totalCost = provider.fuelRecords.fold<double>(0.0, (sum, r) => sum + r.totalCost);
    final avgConsumption = _calculateAverageConsumption(provider.fuelRecords);
    final alertCount = provider.fuelRecords.where((r) => r.isAbnormal == true).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _MiniStatCard(
              title: 'إجمالي التكلفة',
              value: AppFormatters.formatCurrencyCompact(totalCost),
              icon: Icons.attach_money,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStatCard(
              title: 'متوسط الاستهلاك',
              value: avgConsumption > 0 ? '${avgConsumption.toStringAsFixed(1)}' : '—',
              icon: Icons.speed,
              color: AppColors.info,
              unit: 'لتر/100كم',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStatCard(
              title: 'تنبيهات',
              value: '$alertCount',
              icon: Icons.warning_amber_rounded,
              color: alertCount > 0 ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAverageConsumption(List<FuelRecord> records) {
    final withConsumption = records.where((r) => r.consumptionRate != null && r.consumptionRate! > 0).toList();
    if (withConsumption.isEmpty) return 0.0;
    return withConsumption.fold<double>(0.0, (sum, r) => sum + r.consumptionRate!) / withConsumption.length;
  }

  // ── Fuel Record Card ──

  Widget _buildFuelRecordCard(FuelRecord record, FuelProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
          // Top Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getFuelTypeColor(record.fuelType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getFuelTypeIcon(record.fuelType), color: _getFuelTypeColor(record.fuelType), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.vehicle?.plateNumber ?? 'مركبة #${record.vehicleId}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.vehicle?.make ?? ''} ${record.vehicle?.model ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatDate(record.fillDate),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (record.isAbnormal == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⚠ استهلاك غير طبيعي',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Details Row
          Row(
            children: [
              _buildDetailItem(icon: Icons.water_drop, label: 'الكمية', value: '${record.liters.toStringAsFixed(1)} لتر'),
              const SizedBox(width: 20),
              _buildDetailItem(icon: Icons.monetization_on, label: 'التكلفة', value: AppFormatters.formatCurrency(record.totalCost)),
              const Spacer(),
              if (record.consumptionRate != null && record.consumptionRate! > 0)
                _buildDetailItem(
                  icon: Icons.speed,
                  label: 'الاستهلاك',
                  value: '${record.consumptionRate!.toStringAsFixed(1)} لتر/100كم',
                  valueColor: record.isAbnormal == true ? AppColors.error : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Bottom row
          Row(
            children: [
              if (record.fullTank)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('خزان كامل', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                ),
              if (record.stationName != null && record.stationName!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.ev_station, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(record.stationName!, style: const TextStyle(fontSize: 10, color: AppColors.textHint), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
              const Spacer(),
              // Actions
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/add-fuel', arguments: record),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 18, color: AppColors.textHint),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _confirmDelete(context, record.id!, provider),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 18, color: AppColors.textHint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label, required String value, Color? valueColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }

  Color _getFuelTypeColor(String fuelType) {
    switch (fuelType) {
      case 'petrol': return AppColors.accent;
      case 'diesel': return AppColors.info;
      case 'electric': return AppColors.success;
      case 'hybrid': return AppColors.primary;
      case 'gas': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  IconData _getFuelTypeIcon(String fuelType) {
    switch (fuelType) {
      case 'petrol': return Icons.local_gas_station;
      case 'diesel': return Icons.oil_barrel;
      case 'electric': return Icons.bolt;
      case 'hybrid': return Icons.electric_car;
      case 'gas': return Icons.propane_tank;
      default: return Icons.local_gas_station;
    }
  }

  void _confirmDelete(BuildContext context, int id, FuelProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف السجل'),
        content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteFuelRecord(id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف السجل بنجاح'), behavior: SnackBarBehavior.floating),
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

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? unit;

  const _MiniStatCard({required this.title, required this.value, required this.icon, required this.color, this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          if (unit != null)
            Text(unit!, style: const TextStyle(fontSize: 10, color: AppColors.textHint))
          else
            Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
