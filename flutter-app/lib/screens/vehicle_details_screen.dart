import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../services/database_service.dart';
import '../services/report_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/vehicle_type_config.dart';
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
  bool _isExporting = false;

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

  VehicleTypeConfig get _typeConfig =>
      getVehicleTypeConfig(widget.vehicle.vehicleType);

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final statusColor =
        AppConstants.vehicleStatusColors[vehicle.status] ?? AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.displayName),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download),
              onSelected: (value) async {
                setState(() { _isExporting = true; });
                try {
                  if (value == 'pdf') {
                    await ReportService.generateSingleVehiclePDF(vehicle);
                  } else if (value == 'excel') {
                    await ReportService.generateSingleVehicleExcel(vehicle);
                  }
                } finally {
                  if (mounted) setState(() { _isExporting = false; });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(children: [
                    Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('تصدير PDF'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(children: [
                    Icon(Icons.table_chart, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('تصدير Excel'),
                  ]),
                ),
              ],
            ),
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
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadRecords,
              color: _typeConfig.color,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Vehicle Image Card
                  _buildVehicleImageCard(statusColor),
                  const SizedBox(height: 14),

                  // 2. Vehicle Info Card
                  _buildVehicleInfoCard(),
                  const SizedBox(height: 14),

                  // 3. Driver Info Card
                  _buildDriverInfoCard(),
                  const SizedBox(height: 14),

                  // 4. Stats Row
                  _buildStatsRow(),
                  const SizedBox(height: 14),

                  // 5. Depreciation Card
                  _buildDepreciationCard(),
                  const SizedBox(height: 20),

                  // 6. Maintenance History
                  _buildMaintenanceSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Error State
  // ═══════════════════════════════════════════════════════════════════════════

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
            ElevatedButton(onPressed: _loadRecords, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. Vehicle Image Card
  // ═══════════════════════════════════════════════════════════════════════════

  static const _vehicleImages = {
    'half_truck': 'assets/images/vehicles/half_truck.png',
    'jumbo_truck': 'assets/images/vehicles/jumbo_truck.png',
    'double_cabin': 'assets/images/vehicles/double_cabin.png',
    'bus': 'assets/images/vehicles/bus.png',
    'microbus': 'assets/images/vehicles/microbus.png',
    'forklift': 'assets/images/vehicles/forklift.png',
  };

  Widget _buildVehicleImageCard(Color statusColor) {
    final vehicle = widget.vehicle;
    final config = _typeConfig;
    final vehicleImage = _vehicleImages[vehicle.vehicleType];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: config.color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Image area
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  config.color.withOpacity(0.12),
                  config.color.withOpacity(0.04),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                // Vehicle image
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: vehicleImage != null
                        ? Image.asset(
                            vehicleImage,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(config.detailIcon, size: 72, color: config.color.withOpacity(0.3)),
                            ),
                          )
                        : Center(
                            child: Icon(config.detailIcon, size: 72, color: config.color.withOpacity(0.3)),
                          ),
                  ),
                ),
                // Status badge (top-right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppConstants.vehicleStatuses[vehicle.status] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Type badge (top-left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: config.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(config.icon, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          config.shortLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Name + Plate
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFamily: 'Cairo',
                          height: 1.3,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.plateNumber,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. Vehicle Info Card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVehicleInfoCard() {
    final vehicle = widget.vehicle;
    final config = _typeConfig;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.directions_car, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'بيانات المركبة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Info grid
          Row(
            children: [
              Expanded(child: _InfoCell(icon: Icons.speed, label: 'العداد', value: AppFormatters.formatNumber(vehicle.currentOdometer), unit: 'كم')),
              Expanded(child: _InfoCell(icon: Icons.local_gas_station, label: 'الوقود', value: AppConstants.fuelTypes[vehicle.fuelType] ?? '')),
              Expanded(child: _InfoCell(icon: Icons.palette, label: 'اللون', value: AppConstants.vehicleColors[vehicle.color] ?? '')),
              Expanded(child: _InfoCell(icon: Icons.calendar_today, label: 'السنة', value: '${vehicle.year}')),
            ],
          ),
          const SizedBox(height: 10),
          // Capacity row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.straighten, color: config.color, size: 16),
                const SizedBox(width: 6),
                Text(
                  config.capacityLabel,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontFamily: 'Cairo'),
                ),
                const SizedBox(width: 6),
                Text(
                  config.capacityValue(vehicle.toMap()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. Driver Info Card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDriverInfoCard() {
    final vehicle = widget.vehicle;
    if (!vehicle.hasDriver) return const SizedBox.shrink();

    final isSuspended = vehicle.driverStatus == 'suspended';

    return Container(
      padding: const EdgeInsets.all(14),
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
              const Icon(Icons.person, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'بيانات السائق',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Cairo'),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSuspended ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSuspended ? Icons.person_off : Icons.check_circle,
                      size: 13,
                      color: isSuspended ? AppColors.error : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSuspended ? 'موقوف' : 'نشط',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSuspended ? AppColors.error : AppColors.success,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DriverRow(icon: Icons.person_outline, label: 'الاسم', value: vehicle.driverName ?? ''),
          _DriverRow(icon: Icons.phone_outlined, label: 'الهاتف', value: vehicle.driverPhone ?? 'غير محدد'),
          _DriverRow(icon: Icons.badge_outlined, label: 'رقم الرخصة', value: vehicle.driverLicenseNumber ?? 'غير محدد'),
          _DriverRow(
            icon: Icons.event_available_outlined,
            label: 'انتهاء الرخصة',
            value: vehicle.driverLicenseExpiry != null
                ? AppFormatters.formatDate(vehicle.driverLicenseExpiry!)
                : 'غير محدد',
            valueColor: vehicle.driverLicenseExpiry != null &&
                vehicle.driverLicenseExpiry!.isBefore(DateTime.now().add(const Duration(days: 30)))
                ? AppColors.error
                : null,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. Stats Row
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.build,
            title: 'إجمالي العمليات',
            value: '${_records.length}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            icon: Icons.attach_money,
            title: 'إجمالي التكاليف',
            value: AppFormatters.formatCurrencyCompact(_totalCost),
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. Depreciation (نولون) Calculator
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDepreciationCard() {
    final vehicle = widget.vehicle;
    final vehicleAge = DateTime.now().year - vehicle.year;
    final odometer = vehicle.currentOdometer;
    final purchasePrice = _estimatePurchasePrice(vehicle);
    final depreciation = _calculateDepreciation(purchasePrice, vehicleAge, odometer);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_down, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'حساب النولون (الاستهلاك)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Cairo'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Price row
          Row(
            children: [
              Expanded(
                child: _PriceBox(
                  label: 'سعر الشراء',
                  value: purchasePrice,
                  icon: Icons.monetization_on,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PriceBox(
                  label: 'القيمة الحالية',
                  value: depreciation.currentValue,
                  icon: Icons.account_balance_wallet,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('نسبة الاستهلاك', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
          const SizedBox(height: 6),
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
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          // Details
          Row(
            children: [
              Expanded(
                child: _DetailChip(icon: Icons.calendar_today, label: 'العمر', value: '$vehicleAge سنة'),
              ),
              Expanded(
                child: _DetailChip(icon: Icons.trending_down, label: 'السنوي', value: AppFormatters.formatCurrency(depreciation.yearlyDepreciation)),
              ),
              Expanded(
                child: _DetailChip(icon: Icons.speed, label: 'كم/سنة', value: '${AppFormatters.formatNumber(odometer ~/ (vehicleAge > 0 ? vehicleAge : 1))}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Cost per km
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تكلفة الصيانة/كم: ${odometer > 0 ? AppFormatters.formatCurrency(_totalCost / odometer) : "0 ج.م"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
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
    final basePrices = {
      'مرسيدس': 2500000, 'بي إم دبليو': 2200000, 'أودي': 2000000,
      'لكزس': 1800000, 'تويوتا': 800000, 'هيونداي': 650000,
      'نيسان': 600000, 'كيا': 550000, 'فورد': 700000,
      'شيفروليه': 550000, 'هوندا': 650000, 'فولكس واجن': 750000,
      'جيب': 1200000, 'لاند روفر': 2000000,
    };
    return basePrices[vehicle.make] ?? 500000;
  }

  _DepreciationResult _calculateDepreciation(int purchasePrice, int ageYears, int odometerKm) {
    if (ageYears <= 0) {
      return _DepreciationResult(purchasePrice: purchasePrice, currentValue: purchasePrice, depreciationRate: 0, yearlyDepreciation: 0);
    }
    double rate = 0.15;
    for (int i = 1; i < ageYears; i++) { rate += 0.10; }
    rate = rate.clamp(0.0, 0.80);

    double mileagePenalty = 0;
    if (odometerKm > 200000) { mileagePenalty = 0.10; }
    else if (odometerKm > 150000) { mileagePenalty = 0.07; }
    else if (odometerKm > 100000) { mileagePenalty = 0.05; }

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

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. Maintenance History
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMaintenanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'سجل الصيانة',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/add-maintenance',
                  arguments: widget.vehicle,
                );
                if (result == true) _loadRecords();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('إضافة'),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(Icons.build_outlined, size: 44, color: AppColors.textHint.withOpacity(0.4)),
                  const SizedBox(height: 10),
                  const Text(
                    'لا توجد سجلات صيانة',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
          )
        else
          ..._records.map((record) => MaintenanceCard(record: record)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;

  const _InfoCell({required this.icon, required this.label, required this.value, this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(
          unit != null ? '$value $unit' : value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Cairo'),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontFamily: 'Cairo'),
        ),
      ],
    );
  }
}

class _DriverRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DriverRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Cairo')),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatBox({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Cairo')),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
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

class _PriceBox extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _PriceBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'Cairo')),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    AppFormatters.formatCurrency(value.toDouble()),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
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

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 15, color: AppColors.textHint),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary), textAlign: TextAlign.center),
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

  const _DepreciationResult({
    required this.purchasePrice,
    required this.currentValue,
    required this.depreciationRate,
    required this.yearlyDepreciation,
  });
}
