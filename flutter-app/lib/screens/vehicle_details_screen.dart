import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/maintenance_card.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  List<MaintenanceRecord> _records = [];
  bool _isLoading = true;
  double _totalCost = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      final records =
          await DatabaseService.getMaintenanceByVehicleId(widget.vehicle.id ?? 0);
      double total = 0;
      for (final r in records) { total += r.totalCost; }
      if (mounted) {
        setState(() {
          _records = records;
          _totalCost = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Returns a set of maintenance types that have non-completed records (faults)
  Set<String> get _activeFaults {
    final faults = <String>{};
    for (final r in _records) {
      if (r.status == 'pending' || r.status == 'in_progress') {
        faults.add(r.type);
      }
    }
    return faults;
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final statusColor =
        AppConstants.vehicleStatusColors[vehicle.status] ?? AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/add-vehicle',
                arguments: vehicle,
              );
              if (result == true) Navigator.pop(context, true);
            },
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text('حدث خطأ في تحميل البيانات',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadRecords,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRecords,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vehicle Info Card
                  _buildVehicleInfoCard(statusColor),
                  const SizedBox(height: 16),

                  // Interactive Vehicle Diagram
                  _buildVehicleDiagram(),
                  const SizedBox(height: 16),

                  // Faults Legend
                  if (_activeFaults.isNotEmpty) ...[
                    _buildFaultsLegend(),
                    const SizedBox(height: 16),
                  ],

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          'إجمالي العمليات',
                          '${_records.length}',
                          Icons.build,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          'إجمالي التكاليف',
                          AppFormatters.formatCurrencyCompact(_totalCost),
                          Icons.attach_money,
                          AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Depreciation (نولون) Calculator
                  _buildDepreciationCard(),
                  const SizedBox(height: 20),

                  // Maintenance History
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'سجل الصيانة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/add-maintenance',
                            arguments: vehicle,
                          );
                          if (result == true) _loadRecords();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('إضافة'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (_records.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.build_outlined,
                                size: 48, color: AppColors.textHint.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد سجلات صيانة',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._records.map((record) => MaintenanceCard(record: record)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildVehicleInfoCard(Color statusColor) {
    final vehicle = widget.vehicle;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vehicle.plateNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppConstants.vehicleStatuses[vehicle.status] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoItem(
                icon: Icons.speed,
                label: 'عداد الكيلومتر',
                value: AppFormatters.formatNumber(vehicle.currentOdometer),
                unit: 'كم',
              ),
              _InfoItem(
                icon: Icons.local_gas_station,
                label: 'الوقود',
                value: AppConstants.fuelTypes[vehicle.fuelType] ?? '',
              ),
              _InfoItem(
                icon: Icons.palette,
                label: 'اللون',
                value: AppConstants.vehicleColors[vehicle.color] ?? '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Interactive Vehicle Diagram
  Widget _buildVehicleDiagram() {
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
              const Icon(Icons.car_repair, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'معاينة حالة المركبة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_activeFaults.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: AppColors.error, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_activeFaults.length} عطل',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        'سليمة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: CustomPaint(
              size: const Size(double.infinity, 220),
              painter: _VehicleDiagramPainter(
                activeFaults: _activeFaults,
                allRecordTypes: _records.map((r) => r.type).toSet(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Faults Legend
  Widget _buildFaultsLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              const Text(
                'أعطال تحتاج متابعة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _activeFaults.map((type) {
              final record = _records.firstWhere(
                (r) => r.type == type && (r.status == 'pending' || r.status == 'in_progress'),
                orElse: () => _records.firstWhere((r) => r.type == type),
              );
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppConstants.maintenanceTypeIcons[type] ?? Icons.build,
                      size: 14,
                      color: AppConstants.maintenanceTypeColors[type] ?? AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppConstants.maintenanceTypes[type] ?? type,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '- ${record.description}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Depreciation (نولون) Calculator
  Widget _buildDepreciationCard() {
    final vehicle = widget.vehicle;
    final now = DateTime.now();
    final vehicleAge = now.year - vehicle.year;
    final odometer = vehicle.currentOdometer;

    // Default purchase price based on make (Egyptian market estimates in EGP)
    final purchasePrice = _estimatePurchasePrice(vehicle);
    final depreciation = _calculateDepreciation(purchasePrice, vehicleAge, odometer);

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
              const Icon(Icons.trending_down, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'حساب النولون (الاستهلاك)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Price inputs row
          Row(
            children: [
              Expanded(
                child: _DeprecInputField(
                  label: 'سعر الشراء (جنيه)',
                  value: purchasePrice,
                  icon: Icons.monetization_on,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DeprecInputField(
                  label: 'القيمة الحالية (جنيه)',
                  value: depreciation.currentValue,
                  icon: Icons.account_balance_wallet,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Depreciation progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('نسبة الاستهلاك',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    AppFormatters.formatPercentage(depreciation.depreciationRate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: depreciation.depreciationRate > 50
                          ? AppColors.error
                          : depreciation.depreciationRate > 30
                              ? AppColors.accent
                              : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: depreciation.depreciationRate / 100,
                  backgroundColor: AppColors.surfaceVariant,
                  color: depreciation.depreciationRate > 50
                      ? AppColors.error
                      : depreciation.depreciationRate > 30
                          ? AppColors.accent
                          : AppColors.success,
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Detail row
          Row(
            children: [
              Expanded(
                child: _DeprecDetailItem(
                  label: 'عمر المركبة',
                  value: '$vehicleAge سنة',
                  icon: Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _DeprecDetailItem(
                  label: 'الاستهلاك السنوي',
                  value: AppFormatters.formatCurrency(depreciation.yearlyDepreciation),
                  icon: Icons.trending_down,
                ),
              ),
              Expanded(
                child: _DeprecDetailItem(
                  label: 'معدل الكيلومتر',
                  value: '${AppFormatters.formatNumber(odometer ~/ (vehicleAge > 0 ? vehicleAge : 1))} كم/سنة',
                  icon: Icons.speed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cost per km
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تكلفة الصيانة لكل كم: ${odometer > 0 ? AppFormatters.formatCurrency(_totalCost / odometer) : "0 ر.س"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _estimatePurchasePrice(Vehicle vehicle) {
    // Rough Egyptian market estimates for fleet vehicles
    final basePrices = {
      'مرسيدس': 2500000,
      'بي إم دبليو': 2200000,
      'أودي': 2000000,
      'لكزس': 1800000,
      'تويوتا': 800000,
      'هيونداي': 650000,
      'نيسان': 600000,
      'كيا': 550000,
      'فورد': 700000,
      'شيفروليه': 550000,
      'هوندا': 650000,
      'فولكس واجن': 750000,
      'جيب': 1200000,
      'لاند روفر': 2000000,
    };
    int base = basePrices[vehicle.make] ?? 500000;
    // Adjust for model
    if (vehicle.model.contains('C-Class') || vehicle.model.contains('الفئة 3')) base = (base * 0.9).toInt();
    if (vehicle.model.contains('لاند كروزر') || vehicle.model.contains('تاهو')) base = (base * 1.5).toInt();
    if (vehicle.model.contains('كامري') || vehicle.model.contains('إلنترا')) base = (base * 1.1).toInt();
    return base;
  }

  _DepreciationResult _calculateDepreciation(int purchasePrice, int ageYears, int odometerKm) {
    if (ageYears <= 0) {
      return _DepreciationResult(
        purchasePrice: purchasePrice,
        currentValue: purchasePrice,
        depreciationRate: 0,
        yearlyDepreciation: 0,
      );
    }

    // Egyptian market depreciation: ~15-20% first year, ~10% per subsequent year
    double rate = 0.15; // first year
    for (int i = 1; i < ageYears; i++) {
      rate += 0.10;
    }
    rate = rate.clamp(0.0, 0.80);

    // Extra depreciation for high mileage (>100k km)
    double mileagePenalty = 0;
    if (odometerKm > 200000) {
      mileagePenalty = 0.10;
    } else if (odometerKm > 150000) {
      mileagePenalty = 0.07;
    } else if (odometerKm > 100000) {
      mileagePenalty = 0.05;
    }

    final totalRate = (rate + mileagePenalty).clamp(0.0, 0.85);
    final currentValue = (purchasePrice * (1 - totalRate)).toInt();
    final totalDepreciation = purchasePrice - currentValue;
    final yearlyDepreciation = totalDepreciation / ageYears;

    return _DepreciationResult(
      purchasePrice: purchasePrice,
      currentValue: currentValue,
      depreciationRate: totalRate * 100,
      yearlyDepreciation: yearlyDepreciation,
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        if (unit != null)
          Text(
            unit!,
            style: const TextStyle(fontSize: 10, color: Colors.white60),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }
}

class _DeprecInputField extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _DeprecInputField({
    required this.label,
    required this.value,
    required this.icon,
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
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    AppFormatters.formatCurrency(value.toDouble()),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeprecDetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DeprecDetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DepreciationResult {
  final int purchasePrice;
  final int currentValue;
  final double depreciationRate;
  final double yearlyDepreciation;

  _DepreciationResult({
    required this.purchasePrice,
    required this.currentValue,
    required this.depreciationRate,
    required this.yearlyDepreciation,
  });
}

// ========================
// Vehicle Diagram Painter
// ========================

class _VehicleDiagramPainter extends CustomPainter {
  final Set<String> activeFaults;
  final Set<String> allRecordTypes;

  _VehicleDiagramPainter({
    required this.activeFaults,
    required this.allRecordTypes,
  });

  bool _hasFault(String type) => activeFaults.contains(type);
  bool _hasHistory(String type) => allRecordTypes.contains(type);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Paints
    final bodyPaint = Paint()
      ..color = const Color(0xFF4A90D9)
      ..style = PaintingStyle.fill;

    final bodyOutlinePaint = Paint()
      ..color = const Color(0xFF2C5F8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final windowPaint = Paint()
      ..color = const Color(0xFFB3D4FC)
      ..style = PaintingStyle.fill;

    final normalPartPaint = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.fill;

    final faultPartPaint = Paint()
      ..color = AppColors.error
      ..style = PaintingStyle.fill;

    final historyPartPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final labelPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    final whiteTextPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // ========== Car Body ==========
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, h * 0.55), width: w * 0.7, height: h * 0.3),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, bodyOutlinePaint);

    // ========== Cabin/Windows ==========
    final cabinRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, h * 0.38), width: w * 0.4, height: h * 0.22),
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
    );
    canvas.drawRRect(cabinRect, windowPaint);

    // Cabin outline
    final cabinOutlinePaint = Paint()
      ..color = const Color(0xFF2C5F8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(cabinRect, cabinOutlinePaint);

    // ========== Headlights ==========
    final headlightLeftPaint = _hasFault('electrical') ? faultPartPaint : normalPartPaint;
    canvas.drawCircle(Offset(cx + w * 0.32, h * 0.52), 8, headlightLeftPaint);
    final headlightRightPaint = _hasFault('electrical') ? faultPartPaint : normalPartPaint;
    canvas.drawCircle(Offset(cx - w * 0.32, h * 0.52), 8, headlightRightPaint);

    // ========== Tires ==========
    final tireRadius = 18.0;
    final tirePositions = [
      Offset(cx + w * 0.32, h * 0.72), // front-right
      Offset(cx - w * 0.32, h * 0.72), // front-left
      Offset(cx + w * 0.28, h * 0.80), // rear-right
      Offset(cx - w * 0.28, h * 0.80), // rear-left
    ];

    for (final pos in tirePositions) {
      final tirePaint = _hasFault('tires') ? faultPartPaint : normalPartPaint;
      canvas.drawCircle(pos, tireRadius, tirePaint);
      // Hubcap
      final hubPaint = Paint()..color = const Color(0xFFD1D5DB);
      canvas.drawCircle(pos, tireRadius * 0.5, hubPaint);
    }

    // ========== Engine (front) ==========
    final enginePaint = _hasFault('oil_change') || _hasFault('mechanical')
        ? faultPartPaint
        : _hasHistory('oil_change') || _hasHistory('mechanical')
            ? historyPartPaint
            : normalPartPaint;
    final engineRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + w * 0.22, h * 0.48), width: 36, height: 24),
      const Radius.circular(6),
    );
    canvas.drawRRect(engineRect, enginePaint);

    // ========== Battery ==========
    final batteryPaint = _hasFault('battery') ? faultPartPaint : normalPartPaint;
    final batteryRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + w * 0.08, h * 0.38), width: 28, height: 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(batteryRect, batteryPaint);

    // ========== Brakes (at wheels) ==========
    final brakePaint = _hasFault('brakes') ? faultPartPaint : normalPartPaint;
    // Draw brake indicators near front tires
    canvas.drawCircle(Offset(cx + w * 0.37, h * 0.66), 6, brakePaint);
    canvas.drawCircle(Offset(cx - w * 0.37, h * 0.66), 6, brakePaint);

    // ========== AC ==========
    final acPaint = _hasFault('ac') ? faultPartPaint : normalPartPaint;
    canvas.drawCircle(Offset(cx - w * 0.08, h * 0.38), 8, acPaint);

    // ========== Transmission ==========
    final transPaint = _hasFault('transmission') ? faultPartPaint : normalPartPaint;
    final transRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.62), width: 30, height: 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(transRect, transPaint);

    // ========== Filter ==========
    final filterPaint = _hasFault('filter') ? faultPartPaint : normalPartPaint;
    canvas.drawCircle(Offset(cx + w * 0.12, h * 0.58), 7, filterPaint);

    // ========== Body (hood/trunk indicator) ==========
    final bodyPaintIndicator = _hasFault('body') ? faultPartPaint : normalPartPaint;
    canvas.drawCircle(Offset(cx + w * 0.28, h * 0.42), 6, bodyPaintIndicator);
    canvas.drawCircle(Offset(cx - w * 0.28, h * 0.42), 6, bodyPaintIndicator);

    // ========== Labels ==========
    final smallTextStyle = const TextStyle(color: Color(0xFF6B7280), fontSize: 9, fontFamily: 'Cairo');
    final faultTextStyle = const TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'Cairo');

    _drawLabel(canvas, 'ماتور', cx + w * 0.22, h * 0.33,
        _hasFault('oil_change') || _hasFault('mechanical') ? faultTextStyle : smallTextStyle);
    _drawLabel(canvas, 'إطارات', cx + w * 0.22, h * 0.90,
        _hasFault('tires') ? faultTextStyle : smallTextStyle);
    _drawLabel(canvas, 'بطارية', cx + w * 0.08, h * 0.28,
        _hasFault('battery') ? faultTextStyle : smallTextStyle);
    _drawLabel(canvas, 'فرامل', cx - w * 0.22, h * 0.90,
        _hasFault('brakes') ? faultTextStyle : smallTextStyle);
    _drawLabel(canvas, 'تكييف', cx - w * 0.08, h * 0.28,
        _hasFault('ac') ? faultTextStyle : smallTextStyle);
    _drawLabel(canvas, 'ناقل', cx, h * 0.74,
        _hasFault('transmission') ? faultTextStyle : smallTextStyle);
    _drawLabel(canvas, 'فلتر', cx + w * 0.12, h * 0.52,
        _hasFault('filter') ? faultTextStyle : smallTextStyle);
    _drawLabel(canvas, 'هيكل', cx - w * 0.22, h * 0.33,
        _hasFault('body') ? faultTextStyle : smallTextStyle);
    _drawLabel(canvas, 'كهرباء', cx - w * 0.30, h * 0.45,
        _hasFault('electrical') ? faultTextStyle : smallTextStyle);

    // ========== Pulsing red circle for faults ==========
    if (activeFaults.isNotEmpty) {
      final pulsePaint = Paint()
        ..color = AppColors.error.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, h * 0.5), w * 0.38, pulsePaint);
    }
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, TextStyle style) {
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textDirection: TextDirection.rtl,
      fontSize: style.fontSize,
      fontFamily: style.fontFamily,
      fontWeight: style.fontWeight,
    ))
      ..pushStyle(ui.TextStyle(color: style.color))
      ..addText(text);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: 60));
    canvas.drawParagraph(
      paragraph,
      Offset(x - paragraph.width / 2, y - paragraph.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _VehicleDiagramPainter oldDelegate) {
    return oldDelegate.activeFaults != activeFaults ||
        oldDelegate.allRecordTypes != allRecordTypes;
  }
}
