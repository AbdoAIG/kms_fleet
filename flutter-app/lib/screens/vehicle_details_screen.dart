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

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final records =
          await DatabaseService.getMaintenanceByVehicleId(widget.vehicle.id ?? 0);
      final total = records.fold<double>(
          0, (sum, r) => sum + r.totalCost);
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
                value:
                    AppConstants.fuelTypes[vehicle.fuelType] ?? '',
              ),
              _InfoItem(
                icon: Icons.palette,
                label: 'اللون',
                value:
                    AppConstants.vehicleColors[vehicle.color] ?? '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
      String title, String value, IconData icon, Color color) {
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
