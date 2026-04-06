import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/maintenance_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../providers/maintenance_provider.dart';

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
      body: Column(
        children: [
          // ── Page Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                const Text(
                  'سجلات الصيانة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Filter toggle
                InkWell(
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showFilters ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tune,
                      size: 18,
                      color: _showFilters ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
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
                  context.read<MaintenanceProvider>().setSearchQuery(value);
                },
                decoration: InputDecoration(
                  hintText: 'البحث بالوصف أو مزود الخدمة...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textHint, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            context.read<MaintenanceProvider>().setSearchQuery('');
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

          // ── Status Filter Chips ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: SizedBox(
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
          ),

          // ── Extended Filters (if expanded) ──
          if (_showFilters) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'النوع',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
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
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 4),

          // ── Records List ──
          Expanded(
            child: Consumer<MaintenanceProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingWidget(message: 'جاري تحميل السجلات...');
                }

                if (provider.records.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.build_outlined,
                    title: 'لا توجد سجلات صيانة',
                    subtitle: 'أضف سجل صيانة جديد',
                    actionText: 'إضافة سجل',
                    onAction: () => Navigator.pushNamed(context, '/add-maintenance'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadRecords(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: provider.records.length,
                    itemBuilder: (context, index) {
                      final record = provider.records[index];
                      return MaintenanceCard(
                        record: record,
                        onTap: () {},
                        onEdit: () => Navigator.pushNamed(context, '/add-maintenance', arguments: record),
                        onDelete: () => _confirmDelete(context, record.id!, provider),
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
        onPressed: () => Navigator.pushNamed(context, '/add-maintenance'),
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
        backgroundColor: AppColors.surface,
        selectedColor: AppConstants.maintenanceStatusColors[value] ?? AppColors.primary,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide(color: isSelected ? (AppConstants.maintenanceStatusColors[value] ?? AppColors.primary) : AppColors.border),
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
        backgroundColor: AppColors.surface,
        selectedColor: AppConstants.maintenanceTypeColors[value] ?? AppColors.primary,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        side: BorderSide(color: isSelected ? (AppConstants.maintenanceTypeColors[value] ?? AppColors.primary) : AppColors.border),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, MaintenanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف السجل'),
        content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteRecord(id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف السجل بنجاح'), behavior: SnackBarBehavior.floating),
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
