import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/vehicle_3d_card.dart';
import '../widgets/vehicle_preview_sheet.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../providers/vehicle_provider.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Header with title + count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                const Text(
                  'أسطول المركبات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                const Spacer(),
                Consumer<VehicleProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${provider.vehicles.length} مركبة',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                  context.read<VehicleProvider>().searchVehicles(value);
                },
                decoration: InputDecoration(
                  hintText: 'البحث بالماركة أو الموديل أو رقم اللوحة...',
                  hintStyle: const TextStyle(fontSize: 13, fontFamily: 'Cairo'),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textHint, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            context.read<VehicleProvider>().searchVehicles('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
          ),

          // ── Unified Filter Row (Type + Status combined) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Type filters
                  _buildTypeChip('الكل', 'all', null),
                  _buildTypeChip('نص نقل', 'half_truck', AppConstants.vehicleTypeColors['half_truck']),
                  _buildTypeChip('جامبو', 'jumbo_truck', AppConstants.vehicleTypeColors['jumbo_truck']),
                  _buildTypeChip('دبل كابينه', 'double_cabin', AppConstants.vehicleTypeColors['double_cabin']),
                  _buildTypeChip('أتوبيس', 'bus', AppConstants.vehicleTypeColors['bus']),
                  _buildTypeChip('ميكروباص', 'microbus', AppConstants.vehicleTypeColors['microbus']),
                  _buildTypeChip('كلارك', 'forklift', AppConstants.vehicleTypeColors['forklift']),
                  // Divider
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    color: AppColors.border,
                  ),
                  // Status filters
                  _buildStatusChip('نشطة', 'active'),
                  _buildStatusChip('صيانة', 'maintenance'),
                  _buildStatusChip('متوقفة', 'inactive'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Vehicles List ──
          Expanded(
            child: Consumer<VehicleProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingWidget(message: 'جاري تحميل المركبات...');
                }

                if (provider.vehicles.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.directions_car_outlined,
                    title: 'لا توجد مركبات',
                    subtitle: _typeFilter != 'all'
                        ? 'لا توجد مركبات من نوع ${AppConstants.vehicleTypes[_typeFilter] ?? _typeFilter}'
                        : 'أضف مركبة جديدة لبدء إدارة الأسطول',
                    actionText: 'إضافة مركبة',
                    onAction: () => Navigator.pushNamed(context, '/add-vehicle'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: provider.vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = provider.vehicles[index];
                    return Vehicle3DCard(
                      vehicle: vehicle,
                      onTap: () => showVehiclePreviewSheet(
                        context,
                        vehicle: vehicle,
                        onDetails: () => Navigator.pushNamed(
                          context,
                          '/vehicle-details',
                          arguments: vehicle,
                        ),
                        onEdit: () => Navigator.pushNamed(
                          context,
                          '/add-vehicle',
                          arguments: vehicle,
                        ),
                        onMaintenance: () => Navigator.pushNamed(
                          context,
                          '/add-maintenance',
                          arguments: vehicle,
                        ),
                      ),
                      onEdit: () => Navigator.pushNamed(
                        context,
                        '/add-vehicle',
                        arguments: vehicle,
                      ),
                      onMaintenance: () => Navigator.pushNamed(
                        context,
                        '/add-maintenance',
                        arguments: vehicle,
                      ),
                      onDelete: () => _confirmDelete(context, vehicle),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-vehicle'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, Color? color) {
    final isSelected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != 'all' && color != null) ...[
              Icon(
                AppConstants.vehicleTypeIcons[value] ?? Icons.directions_car,
                size: 13,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        onSelected: (selected) {
          setState(() => _typeFilter = value);
          context.read<VehicleProvider>().setTypeFilter(value);
        },
        backgroundColor: AppColors.surface,
        selectedColor: color ?? AppColors.primary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide(color: isSelected ? (color ?? AppColors.primary) : AppColors.border),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _statusFilter == value;
    final statusColor = AppConstants.vehicleStatusColors[value];
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textHint,
            fontFamily: 'Cairo',
          ),
        ),
        onSelected: (selected) {
          setState(() => _statusFilter = value);
          context.read<VehicleProvider>().setStatusFilter(value);
        },
        backgroundColor: AppColors.surface,
        selectedColor: statusColor ?? AppColors.primary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide(color: isSelected ? (statusColor ?? AppColors.primary) : AppColors.border.withOpacity(0.5)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _confirmDelete(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف المركبة'),
        content: Text('هل أنت متأكد من حذف ${vehicle.displayName}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<VehicleProvider>().deleteVehicle(vehicle.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف المركبة بنجاح'),
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
