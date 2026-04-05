import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/maintenance_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../providers/maintenance_provider.dart';
import '../providers/vehicle_provider.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجلات الصيانة'),
        actions: [
          IconButton(
            icon: Icon(_showFilters
                ? Icons.filter_list
                : Icons.filter_list_outlined),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context
                    .read<MaintenanceProvider>()
                    .setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'البحث بالوصف أو مزود الخدمة...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textHint),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textHint, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<MaintenanceProvider>()
                              .setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Filter Row
          if (_showFilters) ...[
            const SizedBox(height: 4),
            // Status Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الحالة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildStatusChip('الكل', 'all'),
                        _buildStatusChip('معلقة', 'pending'),
                        _buildStatusChip('قيد التنفيذ', 'in_progress'),
                        _buildStatusChip('مكتملة', 'completed'),
                        _buildStatusChip('ملغية', 'cancelled'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Type Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'النوع',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildTypeChip('الكل', 'all'),
                        _buildTypeChip('إطارات', 'tires'),
                        _buildTypeChip('كهرباء', 'electrical'),
                        _buildTypeChip('ميكانيكا', 'mechanical'),
                        _buildTypeChip('فرامل', 'brakes'),
                        _buildTypeChip('زيت', 'oil_change'),
                        _buildTypeChip('فلتر', 'filter'),
                        _buildTypeChip('بطارية', 'battery'),
                        _buildTypeChip('تكييف', 'ac'),
                        _buildTypeChip('ناقل حركة', 'transmission'),
                        _buildTypeChip('فحص', 'inspection'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Records List
          Expanded(
            child: Consumer<MaintenanceProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingWidget(
                      message: 'جاري تحميل السجلات...');
                }

                if (provider.records.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.build_outlined,
                    title: 'لا توجد سجلات صيانة',
                    subtitle: 'أضف سجل صيانة جديد',
                    actionText: 'إضافة سجل',
                    onAction: () {
                      Navigator.pushNamed(context, '/add-maintenance');
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadRecords(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.records.length,
                    itemBuilder: (context, index) {
                      final record = provider.records[index];
                      return MaintenanceCard(
                        record: record,
                        onTap: () {},
                        onEdit: () {
                          Navigator.pushNamed(
                            context,
                            '/add-maintenance',
                            arguments: record,
                          );
                        },
                        onDelete: () =>
                            _confirmDelete(context, record.id!, provider),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-maintenance');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
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
          context.read<MaintenanceProvider>().setStatusFilter(value);
        },
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppConstants.maintenanceStatusColors[value] ??
            AppColors.primary,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
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
          setState(() => _typeFilter = value);
          context.read<MaintenanceProvider>().setTypeFilter(value);
        },
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppConstants.maintenanceTypeColors[value] ??
            AppColors.primary,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide.none,
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, int id, MaintenanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('حذف السجل'),
        content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteRecord(id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف السجل بنجاح'),
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
