import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/vehicle_card.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Clear icon state handled in build
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 500;

    return Scaffold(
      body: Column(
        children: [
          // ── Page Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Text(
                  'أسطول المركبات',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                  context.read<VehicleProvider>().searchVehicles(value);
                },
                decoration: InputDecoration(
                  hintText: 'البحث بالماركة أو الموديل أو رقم اللوحة...',
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

          // ── Filter Chips ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('الكل', 'all'),
                  _buildFilterChip('نشطة', 'active'),
                  _buildFilterChip('في الصيانة', 'maintenance'),
                  _buildFilterChip('غير نشطة', 'inactive'),
                  _buildFilterChip('متقاعدة', 'retired'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Vehicles Grid/List ──
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
                    subtitle: 'أضف مركبة جديدة لبدء إدارة الأسطول',
                    actionText: 'إضافة مركبة',
                    onAction: () => Navigator.pushNamed(context, '/add-vehicle'),
                  );
                }

                if (isWide) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: provider.vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = provider.vehicles[index];
                      return VehicleCard(
                        vehicle: vehicle,
                        onTap: () => Navigator.pushNamed(
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
                        onDelete: () => _confirmDelete(context, vehicle),
                      );
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: provider.vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = provider.vehicles[index];
                    return VehicleCard(
                      vehicle: vehicle,
                      onTap: () => Navigator.pushNamed(
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
        onSelected: (selected) {
          setState(() => _statusFilter = value);
          context.read<VehicleProvider>().setStatusFilter(value);
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
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
