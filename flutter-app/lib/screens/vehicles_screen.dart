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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسطول المركبات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context
                    .read<VehicleProvider>()
                    .searchVehicles(value);
              },
              decoration: InputDecoration(
                hintText: 'البحث بالماركة أو الموديل أو رقم اللوحة...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textHint),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<VehicleProvider>()
                              .searchVehicles('');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
          // Status Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('الكل', 'all'),
                  _buildFilterChip('نشط', 'active'),
                  _buildFilterChip('صيانة', 'maintenance'),
                  _buildFilterChip('غير نشط', 'inactive'),
                  _buildFilterChip('متقاعد', 'retired'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Vehicle List
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
                    onAction: () {
                      Navigator.pushNamed(context, '/add-vehicle');
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = provider.vehicles[index];
                    return VehicleCard(
                      vehicle: vehicle,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/vehicle-details',
                          arguments: vehicle,
                        );
                      },
                      onEdit: () {
                        Navigator.pushNamed(
                          context,
                          '/add-vehicle',
                          arguments: vehicle,
                        );
                      },
                      onMaintenance: () {
                        Navigator.pushNamed(
                          context,
                          '/add-maintenance',
                          arguments: vehicle,
                        );
                      },
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
        onPressed: () {
          Navigator.pushNamed(context, '/add-vehicle');
        },
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
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
        onSelected: (selected) {
          setState(() => _statusFilter = value);
          context.read<VehicleProvider>().setStatusFilter(value);
        },
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide.none,
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'تصفية حسب الحالة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.all_inclusive, color: AppColors.primary),
              title: const Text('جميع المركبات'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _statusFilter = 'all');
                context.read<VehicleProvider>().setStatusFilter('all');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('نشطة'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _statusFilter = 'active');
                context.read<VehicleProvider>().setStatusFilter('active');
              },
            ),
            ListTile(
              leading: const Icon(Icons.build, color: Colors.amber),
              title: const Text('في الصيانة'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _statusFilter = 'maintenance');
                context.read<VehicleProvider>().setStatusFilter('maintenance');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('حذف المركبة'),
        content: Text('هل أنت متأكد من حذف ${vehicle.displayName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
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
