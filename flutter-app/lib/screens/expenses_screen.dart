import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../models/vehicle.dart';
import '../providers/expense_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state_widget.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Vehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await DatabaseService.getAllVehicles();
    setState(() => _vehicles = vehicles);
  }

  String _getVehiclePlate(int? vehicleId) {
    if (vehicleId == null) return 'غير محدد';
    for (final v in _vehicles) {
      if (v.id == vehicleId) return v.plateNumber;
    }
    return 'غير محدد';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTypeFilters(),
            Expanded(child: _buildExpenseList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-expense'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تتبع التكاليف',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) =>
                context.read<ExpenseProvider>().searchExpenses(v),
            decoration: InputDecoration(
              hintText: 'بحث في المصروفات...',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilters() {
    final provider = context.watch<ExpenseProvider>();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip('الكل', 'all', provider.typeFilter),
          const SizedBox(width: 8),
          ...AppConstants.expenseTypes.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _filterChip(e.value, e.key, provider.typeFilter),
            );
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, String selected) {
    final isSelected = selected == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primary,
      checkmarkDisplayMode: CheckmarkDisplayMode.none,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: (_) {
        context.read<ExpenseProvider>().setTypeFilter(value);
      },
    );
  }

  Widget _buildExpenseList() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.expenses.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'لا توجد مصروفات',
            subtitle: 'اضغط على + لإضافة مصروف جديد',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadExpenses(),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: provider.expenses.length,
            itemBuilder: (context, index) {
              final expense = provider.expenses[index];
              return _ExpenseCard(
                expense: expense,
                vehiclePlate: _getVehiclePlate(expense.vehicleId),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/add-expense',
                  arguments: expense,
                ),
                onDelete: () async {
                  final confirm = await AppHelpers.showConfirmDialog(
                    context,
                    title: 'حذف المصروف',
                    message: 'هل أنت متأكد من حذف هذا المصروف؟',
                    isDestructive: true,
                  );
                  if (confirm && expense.id != null) {
                    await provider.deleteExpense(expense.id!);
                    if (mounted) {
                      AppHelpers.showSnackBar(context, 'تم حذف المصروف');
                    }
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final String vehiclePlate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.vehiclePlate,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AppConstants.expenseTypeIcons[expense.type] ?? Icons.receipt_long;
    final color = AppConstants.expenseTypeColors[expense.type] ?? AppColors.textSecondary;
    final typeName = AppConstants.expenseTypes[expense.type] ?? 'أخرى';

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border, width: 0.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vehiclePlate,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (expense.description != null &&
                          expense.description!.isNotEmpty)
                        Text(
                          expense.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.formatDate(expense.expenseDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(expense.amount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
