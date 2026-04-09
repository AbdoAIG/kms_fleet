import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/driver.dart';
import '../models/driver_violation.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';
import '../providers/driver_provider.dart';
import '../services/database_service.dart';

class DriverDetailsScreen extends StatefulWidget {
  final Driver driver;

  const DriverDetailsScreen({super.key, required this.driver});

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  late Driver _driver;
  Vehicle? _assignedVehicle;
  bool _isLoadingVehicle = true;

  // Violation form controllers
  final _violationTypeController = TextEditingController();
  final _violationAmountController = TextEditingController();
  final _violationDescriptionController = TextEditingController();
  final _violationPointsController = TextEditingController();
  DateTime? _violationDate;
  String _violationStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _driver = widget.driver;
    _loadVehicle();
    _loadViolations();
  }

  Future<void> _loadVehicle() async {
    if (_driver.vehicleId != null) {
      final vehicle =
          await DatabaseService.getVehicleById(_driver.vehicleId!);
      if (mounted && vehicle != null) {
        setState(() {
          _assignedVehicle = vehicle;
          _isLoadingVehicle = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingVehicle = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingVehicle = false);
    }
  }

  Future<void> _loadViolations() async {
    if (_driver.id != null) {
      await context
          .read<DriverProvider>()
          .loadViolationsByDriver(_driver.id!);
    }
  }

  Future<void> _reloadDriver() async {
    if (_driver.id != null) {
      final updated = await DatabaseService.getDriverById(_driver.id!);
      if (updated != null && mounted) {
        setState(() => _driver = updated);
        await _loadVehicle();
        await _loadViolations();
      }
    }
  }

  void _confirmDelete() {
    AppHelpers.showConfirmDialog(
      context,
      title: 'حذف السائق',
      message: 'هل أنت متأكد من حذف "${_driver.name}"؟ سيتم حذف جميع بيانات السائق.',
      confirmText: 'حذف',
      isDestructive: true,
    ).then((confirmed) async {
      if (confirmed) {
        final success =
            await context.read<DriverProvider>().deleteDriver(_driver.id!);
        if (mounted) {
          if (success) {
            AppHelpers.showSnackBar(context, 'تم حذف السائق بنجاح');
            Navigator.pop(context, true);
          } else {
            AppHelpers.showSnackBar(context, 'حدث خطأ أثناء الحذف',
                isError: true);
          }
        }
      }
    });
  }

  bool _isLicenseExpired() {
    if (_driver.licenseExpiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      _driver.licenseExpiryDate!.year,
      _driver.licenseExpiryDate!.month,
      _driver.licenseExpiryDate!.day,
    );
    return expiry.isBefore(today);
  }

  bool _isLicenseNearExpiry() {
    if (_driver.licenseExpiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      _driver.licenseExpiryDate!.year,
      _driver.licenseExpiryDate!.month,
      _driver.licenseExpiryDate!.day,
    );
    final diff = expiry.difference(today).inDays;
    return diff >= 0 && diff <= 30;
  }

  Color _getLicenseStatusColor() {
    if (_isLicenseExpired()) return AppColors.error;
    if (_isLicenseNearExpiry()) return AppColors.warning;
    return AppColors.success;
  }

  String _getLicenseStatusText() {
    if (_driver.licenseExpiryDate == null) return 'غير محدد';
    if (_isLicenseExpired()) return 'منتهية';
    if (_isLicenseNearExpiry()) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiry = DateTime(
        _driver.licenseExpiryDate!.year,
        _driver.licenseExpiryDate!.month,
        _driver.licenseExpiryDate!.day,
      );
      return 'قاربت (${expiry.difference(today).inDays} يوم)';
    }
    return 'سارية';
  }

  void _showAddViolationSheet() {
    _violationTypeController.clear();
    _violationAmountController.clear();
    _violationDescriptionController.clear();
    _violationPointsController.clear();
    _violationDate = DateTime.now();
    _violationStatus = 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'إضافة مخالفة جديدة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Violation Type
                  DropdownButtonFormField<String>(
                    value: AppConstants.violationTypes.keys.first,
                    decoration: const InputDecoration(
                      labelText: 'نوع المخالفة',
                      prefixIcon: Icon(Icons.gavel),
                    ),
                    items: AppConstants.violationTypes.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _violationTypeController.text = value ?? 'other';
                    },
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  TextFormField(
                    controller: _violationAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (ج.م)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال المبلغ';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'مبلغ غير صالح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Points
                  TextFormField(
                    controller: _violationPointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'النقاط',
                      prefixIcon: Icon(Icons.star),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _violationDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        helpText: 'تاريخ المخالفة',
                        cancelText: 'إلغاء',
                        confirmText: 'تأكيد',
                        locale: const Locale('ar'),
                      );
                      if (picked != null) {
                        setSheetState(() => _violationDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'التاريخ',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _violationDate != null
                            ? AppFormatters.formatDate(_violationDate!)
                            : 'اختر التاريخ',
                        style: TextStyle(
                          fontSize: 16,
                          color: _violationDate != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status
                  DropdownButtonFormField<String>(
                    value: _violationStatus,
                    decoration: const InputDecoration(
                      labelText: 'الحالة',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    items: AppConstants.violationStatuses.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setSheetState(
                          () => _violationStatus = value ?? 'pending');
                    },
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _violationDescriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: () async {
                      if (_violationAmountController.text.trim().isEmpty) {
                        AppHelpers.showSnackBar(context, 'يرجى إدخال المبلغ',
                            isError: true);
                        return;
                      }
                      final violation = DriverViolation(
                        driverId: _driver.id!,
                        vehicleId: _driver.vehicleId,
                        type: _violationTypeController.text.isNotEmpty
                            ? _violationTypeController.text
                            : 'other',
                        amount: double.tryParse(
                                _violationAmountController.text.trim()) ??
                            0,
                        date: _violationDate ?? DateTime.now(),
                        description:
                            _violationDescriptionController.text.trim(),
                        points: int.tryParse(
                                _violationPointsController.text.trim()) ??
                            0,
                        status: _violationStatus,
                      );
                      await context
                          .read<DriverProvider>()
                          .addViolation(violation);
                      if (mounted) {
                        Navigator.pop(context);
                        AppHelpers.showSnackBar(
                            context, 'تم إضافة المخالفة بنجاح');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'إضافة المخالفة',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        AppConstants.driverStatusColors[_driver.status] ??
            AppColors.textSecondary;
    final statusText =
        AppConstants.driverStatuses[_driver.status] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_driver.name),
        centerTitle: true,
      ),
      body: Consumer<DriverProvider>(
        builder: (context, provider, _) {
          final violations = provider.driverViolations;

          return RefreshIndicator(
            onRefresh: () async {
              await _reloadDriver();
            },
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Profile Card ──
                _buildProfileCard(statusColor, statusText),
                const SizedBox(height: 16),

                // ── Action Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'تعديل',
                        icon: Icons.edit,
                        color: AppColors.primary,
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/add-driver',
                            arguments: _driver,
                          );
                          if (result == true) _reloadDriver();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        label: 'حذف',
                        icon: Icons.delete_outline,
                        color: AppColors.error,
                        onTap: _confirmDelete,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Violations Section ──
                _buildViolationsSection(violations),
                const SizedBox(height: 24),

                // ── Stats Summary ──
                _buildStatsSummary(violations),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Color statusColor, String statusText) {
    final firstLetter =
        _driver.name.isNotEmpty ? _driver.name[0] : '?';
    final avatarColors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
      const Color(0xFF7C3AED),
    ];
    int hash = 0;
    for (int i = 0; i < _driver.name.length; i++) {
      hash = _driver.name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final avatarColor = avatarColors[hash.abs() % avatarColors.length];

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
          // Header with avatar
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _driver.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          _driver.phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
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

          // Info Row
          Column(
            children: [
              // License Info
              _buildProfileInfoRow(
                icon: Icons.credit_card,
                label: 'رقم الرخصة',
                value: _driver.licenseNumber,
              ),
              const SizedBox(height: 12),
              // License Expiry
              _buildProfileInfoRow(
                icon: Icons.event,
                label: 'انتهاء الرخصة',
                value: _driver.licenseExpiryDate != null
                    ? AppFormatters.formatDate(_driver.licenseExpiryDate!)
                    : 'غير محدد',
                valueColor: _getLicenseStatusColor(),
                trailing: _driver.licenseExpiryDate != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getLicenseStatusColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getLicenseStatusText(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _getLicenseStatusColor(),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              // Assigned Vehicle
              _buildProfileInfoRow(
                icon: Icons.directions_car,
                label: 'المركبة المسندة',
                value: _isLoadingVehicle
                    ? '...'
                    : _assignedVehicle != null
                        ? '${_assignedVehicle!.plateNumber} (${_assignedVehicle!.make} ${_assignedVehicle!.model})'
                        : 'غير مسندة',
              ),
              // Notes
              if (_driver.notes != null &&
                  _driver.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildProfileInfoRow(
                  icon: Icons.notes,
                  label: 'ملاحظات',
                  value: _driver.notes!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
        const Spacer(),
        if (trailing != null) ...[
          trailing,
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViolationsSection(List<DriverViolation> violations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Text(
              'سجل المخالفات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${violations.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showAddViolationSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Violations List
        if (violations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 36, color: AppColors.success),
                SizedBox(height: 8),
                Text(
                  'لا توجد مخالفات',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...violations.map((v) => _buildViolationCard(v)),
      ],
    );
  }

  Widget _buildViolationCard(DriverViolation violation) {
    final typeLabel =
        AppConstants.violationTypes[violation.type] ?? violation.type;
    final statusColor =
        AppConstants.violationStatusColors[violation.status] ??
            AppColors.textSecondary;
    final statusText =
        AppConstants.violationStatuses[violation.status] ?? '';

    final violationIcons = <String, IconData>{
      'speeding': Icons.speed,
      'red_light': Icons.traffic,
      'parking': Icons.local_parking,
      'no_license': Icons.no_accounts,
      'overweight': Icons.line_weight,
      'other': Icons.gavel,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Type Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                violationIcons[violation.type] ?? Icons.gavel,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Violation Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Amount
                      Text(
                        AppFormatters.formatCurrency(violation.amount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Date
                      Icon(Icons.calendar_today,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(
                        AppFormatters.formatDate(violation.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (violation.points > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.star,
                            size: 12, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          '${violation.points} نقطة',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (violation.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      violation.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(List<DriverViolation> violations) {
    double totalFines = 0;
    int totalPoints = 0;
    for (final v in violations) {
      totalFines += v.amount;
      totalPoints += v.points;
    }

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
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'ملخص المخالفات',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'إجمالي المخالفات',
                  value: '${violations.length}',
                  color: AppColors.primary,
                  icon: Icons.gavel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  label: 'إجمالي الغرامات',
                  value: AppFormatters.formatCurrency(totalFines),
                  color: AppColors.error,
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  label: 'إجمالي النقاط',
                  value: '$totalPoints',
                  color: AppColors.warning,
                  icon: Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
