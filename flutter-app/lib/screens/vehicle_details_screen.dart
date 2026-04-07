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
import '../widgets/attachment_picker_widget.dart';

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
  String? _expandedPointId;

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

  /// Returns a set of all maintenance types that have any records (history)
  Set<String> get _allRecordTypes {
    return _records.map((r) => r.type).toSet();
  }

  /// Get the vehicle type config for the current vehicle
  VehicleTypeConfig get _typeConfig =>
      getVehicleTypeConfig(widget.vehicle.vehicleType);

  /// Determine inspection point status: 'healthy', 'warning', 'unknown'
  String _getPointStatus(InspectionPoint point) {
    if (point.maintenanceType == null) return 'unknown';
    if (_activeFaults.contains(point.maintenanceType)) return 'warning';
    if (_allRecordTypes.contains(point.maintenanceType)) return 'healthy';
    return 'unknown';
  }

  /// Get the active fault record for an inspection point
  MaintenanceRecord? _getFaultRecord(InspectionPoint point) {
    if (point.maintenanceType == null) return null;
    try {
      return _records.firstWhere(
        (r) => r.type == point.maintenanceType &&
            (r.status == 'pending' || r.status == 'in_progress'),
      );
    } catch (_) {
      return null;
    }
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
                    Text('📄 تصدير PDF المركبة'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(children: [
                    Icon(Icons.table_chart, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('📊 تصدير Excel المركبة'),
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
              color: _typeConfig.color,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vehicle Info Card (type-specific)
                  _buildVehicleInfoCard(statusColor),
                  const SizedBox(height: 16),

                  // Driver Info Card
                  _buildDriverInfoCard(),
                  const SizedBox(height: 16),

                  // Type-Specific Inspection Checkpoints
                  _buildTypeSpecificInspection(),
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

                  // GPS Trip Actions
                  _buildGpsActions(vehicle),
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

                  // Vehicle Photos
                  if (widget.vehicle.id != null)
                    AttachmentPickerWidget(
                      entityType: 'vehicle',
                      entityId: widget.vehicle.id!,
                      onAttachmentsChanged: (paths) {
                        debugPrint('Vehicle attachments updated: ${paths.length}');
                      },
                      maxAttachments: 10,
                      title: 'صور المركبة',
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // Vehicle Info Card — Type-Specific Header with Vehicle Image
  // ═══════════════════════════════════════════════════════════════════════════════

  static const _vehicleImages = {
    'half_truck': 'assets/images/vehicles/half_truck.png',
    'jumbo_truck': 'assets/images/vehicles/jumbo_truck.png',
    'double_cabin': 'assets/images/vehicles/double_cabin.png',
    'bus': 'assets/images/vehicles/bus.png',
    'microbus': 'assets/images/vehicles/microbus.png',
    'forklift': 'assets/images/vehicles/forklift.png',
  };

  Widget _buildVehicleInfoCard(Color statusColor) {
    final vehicle = widget.vehicle;
    final config = _typeConfig;
    final vehicleImage = _vehicleImages[vehicle.vehicleType];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: config.color.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // ── Vehicle Image Header ──
          Container(
            height: 200,
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                // Vehicle image
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: vehicleImage != null
                        ? Image.asset(
                            vehicleImage,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                config.detailIcon,
                                size: 80,
                                color: config.color.withOpacity(0.3),
                              ),
                            ),
                          )
                        : Center(
                          child: Icon(
                            config.detailIcon,
                            size: 80,
                            color: config.color.withOpacity(0.3),
                          ),
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
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
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
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
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
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: config.color.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
          // ── Vehicle Info Section ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Vehicle name + plate
                Text(
                  vehicle.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.plateNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                // Info row: odometer, fuel, color, year
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
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
                          _InfoItem(
                            icon: Icons.calendar_today,
                            label: 'السنة',
                            value: '${vehicle.year}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Capacity row (type-specific)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.straighten, color: AppColors.textHint, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            config.capacityLabel,
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Cairo'),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            config.capacityValue(vehicle.toMap()),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // Type-Specific Inspection Checkpoints (replaces old vehicle diagram)
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildTypeSpecificInspection() {
    final config = _typeConfig;
    final points = config.inspectionPoints;
    final hasAnyFaults = points.any((p) => _getPointStatus(p) == 'warning');
    final allHealthy = points.every((p) => _getPointStatus(p) == 'healthy');

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
          // Section header
          Row(
            children: [
              Icon(config.detailIcon, color: config.color, size: 20),
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
              if (hasAnyFaults)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: AppColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_activeFaults.length} عطل',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                )
              else if (allHealthy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'سليمة 100%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline, color: AppColors.textHint, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${points.length} نقطة فحص',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // "100% healthy" banner when no faults
          if (allHealthy && points.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.08),
                    AppColors.success.withOpacity(0.04),
                  ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.2), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'سليمة 100% — جميع الأجزاء بحالة جيدة',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

          // Inspection points grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: points.length,
            itemBuilder: (context, index) {
              final point = points[index];
              final status = _getPointStatus(point);
              final faultRecord = _getFaultRecord(point);
              final isExpanded = _expandedPointId == point.id;

              return _buildInspectionCard(
                point: point,
                status: status,
                faultRecord: faultRecord,
                isExpanded: isExpanded,
                onTap: () {
                  setState(() {
                    _expandedPointId = isExpanded ? null : point.id;
                  });
                  if (faultRecord != null) {
                    debugPrint(
                      'Inspection point tapped: ${point.label} — '
                      '${faultRecord.description} (status: ${faultRecord.status})',
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionCard({
    required InspectionPoint point,
    required String status,
    required MaintenanceRecord? faultRecord,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    Color statusColor;
    Color backgroundColor;
    Color borderColor;

    switch (status) {
      case 'healthy':
        statusColor = AppColors.success;
        backgroundColor = AppColors.success.withOpacity(0.06);
        borderColor = AppColors.success.withOpacity(0.15);
        break;
      case 'warning':
        statusColor = AppColors.warning;
        backgroundColor = AppColors.warning.withOpacity(0.08);
        borderColor = AppColors.warning.withOpacity(0.25);
        break;
      default: // 'unknown'
        statusColor = AppColors.textHint;
        backgroundColor = AppColors.surfaceVariant;
        borderColor = AppColors.border;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isExpanded
              ? statusColor.withOpacity(0.12)
              : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? statusColor.withOpacity(0.5)
                : borderColor,
            width: isExpanded ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with status indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: point.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    point.icon,
                    color: point.color,
                    size: 20,
                  ),
                ),
                // Status dot
                Positioned(
                  top: -2,
                  left: -2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Label
            Text(
              point.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: status == 'unknown'
                    ? AppColors.textHint
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Expanded fault description
            if (isExpanded && faultRecord != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  faultRecord.description,
                  style: TextStyle(
                    fontSize: 8,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // Driver Info Card (unchanged)
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildDriverInfoCard() {
    final vehicle = widget.vehicle;
    if (!vehicle.hasDriver) return const SizedBox.shrink();

    final isSuspended = vehicle.driverStatus == 'suspended';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Icon(Icons.person, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'بيانات السائق',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSuspended ? AppColors.error.withOpacity(0.12) : AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSuspended ? Icons.person_off : Icons.check_circle,
                      size: 14,
                      color: isSuspended ? AppColors.error : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSuspended ? 'موقوف' : 'نشط',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSuspended ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DriverInfoRow(icon: Icons.person_outline, label: 'اسم السائق', value: vehicle.driverName ?? ''),
          const SizedBox(height: 10),
          _DriverInfoRow(icon: Icons.phone_outlined, label: 'رقم الهاتف', value: vehicle.driverPhone ?? 'غير محدد'),
          const SizedBox(height: 10),
          _DriverInfoRow(icon: Icons.badge_outlined, label: 'رقم الرخصة', value: vehicle.driverLicenseNumber ?? 'غير محدد'),
          const SizedBox(height: 10),
          _DriverInfoRow(
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

  Widget _DriverInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // Faults Legend (unchanged)
  // ═══════════════════════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════════════════════
  // GPS Trip Actions Card (unchanged)
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildGpsActions(Vehicle vehicle) {
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
              const Icon(Icons.location_on, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              const Text(
                'تتبع الرحلات',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(
                    context,
                    '/trip-history',
                    arguments: vehicle,
                  );
                },
                icon: const Icon(Icons.history, size: 18),
                label: const Text('السجل'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/trip-tracking',
                  arguments: vehicle,
                );
                if (result == true) _loadRecords();
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('بدء رحلة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // Depreciation (نولون) Calculator (unchanged)
  // ═══════════════════════════════════════════════════════════════════════════════

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
                    'تكلفة الصيانة لكل كم: ${odometer > 0 ? AppFormatters.formatCurrency(_totalCost / odometer) : "0 ج.م"}',
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // Stat Box (unchanged)
  // ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// Helper Widgets (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

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
