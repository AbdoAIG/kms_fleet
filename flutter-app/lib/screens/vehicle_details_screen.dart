import 'dart:io';
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
import '../widgets/vehicle_rotating_image.dart';

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
                  String result = '';
                  String label = '';
                  if (value == 'pdf') {
                    result = await ReportService.generateSingleVehiclePDF(vehicle);
                    label = 'PDF';
                  } else if (value == 'excel') {
                    result = await ReportService.generateSingleVehicleExcel(vehicle);
                    label = 'Excel';
                  }
                  if (result.isNotEmpty && mounted) {
                    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
                    final msg = isDesktop
                        ? 'تم حفظ $label بنجاح ✅\n$result'
                        : 'تم حفظ $label بنجاح ✅';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: isDesktop ? 5 : 3),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فشل التصدير'), backgroundColor: AppColors.error),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
                    );
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
                  const SizedBox(height: 20),

                  // 5. Maintenance History
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
          // Rotating 3D Image
          Stack(
            children: [
              VehicleRotatingImage(
                imagePath: vehicleImage,
                fallbackIcon: config.detailIcon,
                accentColor: config.color,
                height: 220,
                borderRadius: 18,
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
                'بيانات السيارة',
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
  // 5. Maintenance History
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


