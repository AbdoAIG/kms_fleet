import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../providers/vehicle_provider.dart';
import 'vehicle_360_screen.dart';
import 'vehicle_details_screen.dart';

/// بيانات أنواع المركبات مع الأيقونات والألوان
class _FleetCategory {
  final String model; // مفتاح البحث في Vehicle.model
  final String label;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final Color darkColor;

  const _FleetCategory({
    required this.model,
    required this.label,
    required this.icon,
    required this.color,
    required this.lightColor,
    required this.darkColor,
  });
}

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  // أنواع المركبات في شركة الورق
  static const List<_FleetCategory> _categories = [
    _FleetCategory(
      model: 'جامبو',
      label: 'النقل الجامبو',
      icon: Icons.local_shipping_rounded,
      color: Color(0xFF1565C0),
      lightColor: Color(0xFFE3F2FD),
      darkColor: Color(0xFF0D47A1),
    ),
    _FleetCategory(
      model: 'دبابة',
      label: 'النقل',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF00695C),
      lightColor: Color(0xFFE0F2F1),
      darkColor: Color(0xFF004D40),
    ),
    _FleetCategory(
      model: 'كلارك',
      label: 'الكلركات',
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xFFE65100),
      lightColor: Color(0xFFFBE9E7),
      darkColor: Color(0xFFBF360C),
    ),
    _FleetCategory(
      model: 'أوتوبيس',
      label: 'الأتوبيسات',
      icon: Icons.directions_bus_rounded,
      color: Color(0xFF6A1B9A),
      lightColor: Color(0xFFF3E5F5),
      darkColor: Color(0xFF4A148C),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicles();
    });
  }

  @override
  void initState() {
    super.initState();
    // تحميل بيانات المركبات عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicles();
    });
  }

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
          // === فلتر أنواع المركبات (بطاقات احترافية) ===
          _buildCategoryFilter(),
          const SizedBox(height: 8),
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<VehicleProvider>().searchVehicles(value);
              },
              decoration: InputDecoration(
                hintText: 'البحث بالماركة أو الموديل أو رقم اللوحة...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textHint),
                        onPressed: () {
                          _searchController.clear();
                          context.read<VehicleProvider>().searchVehicles('');
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
                    subtitle: _typeFilter != 'all'
                        ? 'لا توجد مركبات من نوع ${_categories.firstWhere((c) => c.model == _typeFilter).label}'
                        : 'أضف مركبة جديدة لبدء إدارة الأسطول',
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Vehicle360Screen(vehicle: vehicle),
                          ),
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

  /// بطاقات الفلتر الاحترافية لأنواع المركبات
  Widget _buildCategoryFilter() {
    return Consumer<VehicleProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان القسم مع عدد المركبات
              Row(
                children: [
                  const Icon(Icons.category_rounded, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  const Text(
                    'أنواع المركبات',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // زر "الكل"
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _typeFilter == 'all'
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _typeFilter = 'all');
                        provider.setTypeFilter('all');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.apps_rounded,
                            size: 14,
                            color: _typeFilter == 'all' ? Colors.white : AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الكل',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _typeFilter == 'all' ? Colors.white : AppColors.textHint,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _typeFilter == 'all'
                                  ? Colors.white.withOpacity(0.25)
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${provider.totalCount}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _typeFilter == 'all' ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // بطاقات الأنواع
              Row(
                children: _categories.map((cat) {
                  final count = provider.getCountByType(cat.model);
                  final isSelected = _typeFilter == cat.model;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _typeFilter = isSelected ? 'all' : cat.model;
                        });
                        provider.setTypeFilter(_typeFilter);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? cat.color : cat.lightColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? cat.color : cat.color.withOpacity(0.15),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: cat.color.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // أيقونة مع خلفية دائرية
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : cat.color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                cat.icon,
                                size: 22,
                                color: isSelected ? Colors.white : cat.color,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // اسم النوع
                            Text(
                              cat.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : cat.darkColor,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // عدد المركبات
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : cat.color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count مركبة',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.9)
                                      : cat.color.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
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
