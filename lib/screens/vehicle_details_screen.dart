import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/maintenance_card.dart';
import 'vehicle_360_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  List<MaintenanceRecord> _records = [];
  bool _isLoading = true;
  bool _isExporting = false;
  double _totalCost = 0;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final path = await ExportService.exportVehiclePdf(widget.vehicle.id ?? 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء التقرير بنجاح\n$path'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إنشاء تقرير PDF: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _loadRecords() async {
    try {
      final records =
          await DatabaseService.getMaintenanceByVehicleId(widget.vehicle.id ?? 0);
      final total = records.fold<double>(0, (sum, r) => sum + r.totalCost);
      if (mounted) {
        setState(() {
          _records = records;
          _totalCost = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.displayName),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'تصدير تقرير PDF',
              onPressed: _exportPdf,
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/add-vehicle',
                arguments: widget.vehicle,
              );
              if (result == true) Navigator.pop(context, true);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle Info Card
          _buildVehicleInfoCard(),
          const SizedBox(height: 16),

          // Technical Info Section
          _buildTechnicalInfoSection(),
          const SizedBox(height: 16),

          // Driver Info Section
          _buildDriverInfoSection(),
          const SizedBox(height: 16),

          // Insurance & Registration Section
          _buildInsuranceRegistrationSection(),
          const SizedBox(height: 16),

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
                    arguments: widget.vehicle,
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
    );
  }

  Widget _buildVehicleInfoCard() {
    final vehicle = widget.vehicle;
    final statusColor =
        AppConstants.vehicleStatusColors[vehicle.status] ?? AppColors.textSecondary;

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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
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
              const SizedBox(width: 8),
              // زر عرض ثلاثي الأبعاد
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Vehicle360Screen(vehicle: vehicle),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.view_in_ar_rounded,
                    color: Colors.white,
                    size: 20,
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

  Widget _buildTechnicalInfoSection() {
    final vehicle = widget.vehicle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'بيانات فنية',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.vpn_key, 'رقم الشاسيه (VIN)', vehicle.vin ?? 'غير محدد', isLtr: true),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.engineering, 'رقم المحرك', vehicle.engineNumber ?? 'غير محدد', isLtr: true),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.category, 'فئة المركبة', AppConstants.vehicleCategories[vehicle.vehicleCategory] ?? 'غير محدد'),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.local_gas_station, 'نوع الوقود', AppConstants.fuelTypes[vehicle.fuelType] ?? ''),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.calendar_today, 'سنة الصنع', vehicle.year.toString()),
        ],
      ),
    );
  }

  Widget _buildDriverInfoSection() {
    final vehicle = widget.vehicle;
    final hasDriverData = vehicle.driverName != null && vehicle.driverName!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              const Text(
                'بيانات السائق',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasDriverData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'لم يتم تحديد سائق',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else ...[
            _buildDetailRow(Icons.person_outline, 'اسم السائق', vehicle.driverName ?? ''),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.phone, 'رقم الهاتف', vehicle.driverPhone ?? 'غير محدد', isLtr: true),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.card_membership, 'رقم الرخصة', vehicle.driverLicense ?? 'غير محدد', isLtr: true),
            if (vehicle.driverLicenseExpiry != null) ...[
              const SizedBox(height: 10),
              _buildExpiryRow(Icons.event, 'انتهاء الرخصة', vehicle.driverLicenseExpiry!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInsuranceRegistrationSection() {
    final vehicle = widget.vehicle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'التأمين والترخيص',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.security, 'رقم التأمين', vehicle.insuranceNumber ?? 'غير محدد', isLtr: true),
          if (vehicle.insuranceExpiry != null) ...[
            const SizedBox(height: 10),
            _buildExpiryRow(Icons.shield, 'انتهاء التأمين', vehicle.insuranceExpiry!),
          ] else ...[
            const SizedBox(height: 10),
            _buildDetailRow(Icons.shield, 'انتهاء التأمين', 'غير محدد'),
          ],
          if (vehicle.registrationExpiry != null) ...[
            const SizedBox(height: 10),
            _buildExpiryRow(Icons.assignment, 'انتهاء الترخيص', vehicle.registrationExpiry!),
          ] else ...[
            const SizedBox(height: 10),
            _buildDetailRow(Icons.assignment, 'انتهاء الترخيص', 'غير محدد'),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isLtr = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (isLtr)
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryRow(IconData icon, String label, String dateStr) {
    final remainingDays = _calculateRemainingDays(dateStr);
    final (color, bgColor) = _getExpiryColorStyle(remainingDays);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateString(dateStr),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  remainingDays < 0
                      ? 'منتهي'
                      : remainingDays == 0
                          ? 'اليوم'
                          : '$remainingDays يوم',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _calculateRemainingDays(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);
      return target.difference(today).inDays;
    } catch (_) {
      return 0;
    }
  }

  (Color, Color) _getExpiryColorStyle(int remainingDays) {
    if (remainingDays < 0) return (AppColors.error, AppColors.errorLight);
    if (remainingDays <= 7) return (AppColors.error, AppColors.errorLight);
    if (remainingDays <= 30) return (AppColors.warning, AppColors.warningLight);
    return (AppColors.success, AppColors.successLight);
  }

  String _formatDateString(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return dateStr;
    }
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (unit != null)
          Text(
            unit!,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white60,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}
