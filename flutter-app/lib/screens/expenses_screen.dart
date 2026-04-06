import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<ExpenseProvider>().loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => provider.loadExpenses(),
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──
            SliverToBoxAdapter(child: _buildHeader(provider)),
            // ── Stats Cards ──
            SliverToBoxAdapter(child: _buildStatsCards(provider)),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // ── Filter Chips ──
            SliverToBoxAdapter(child: _buildFilterChips(provider)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // ── Expense List ──
            if (provider.isLoading)
              const SliverFillRemaining(child: LoadingWidget(message: 'جاري تحميل المصروفات...'))
            else if (provider.expenses.isEmpty)
              SliverFillRemaining(child: EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                title: 'لا توجد مصروفات',
                subtitle: 'اضغط على + لإضافة مصروف جديد',
              ))
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildExpenseCard(provider.expenses[index]),
                    childCount: provider.expenses.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add-expense');
          if (mounted) provider.loadExpenses();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة مصروف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }

  Widget _buildHeader(ExpenseProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.accent, AppColors.accentLight], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('المصروفات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(AppFormatters.formatCurrency(provider.totalExpenses), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('إجمالي المصروفات', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ExpenseProvider provider) {
    final stats = [
      ('وقود', provider.fuelCost, 'fuel'),
      ('صيانة', provider.maintenanceCost, 'maintenance'),
      ('رسوم طريق', provider.tollCost, 'toll'),
      ('مخالفات', provider.violationCost, 'violation'),
      ('تأمين', provider.insuranceCost, 'insurance'),
      ('متنوعة', provider.miscCost, 'miscellaneous'),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (label, amount, type) = stats[index];
          final color = AppConstants.expenseTypeColors[type] ?? AppColors.textHint;
          final icon = AppConstants.expenseTypeIcons[type] ?? Icons.receipt_long;
          return Container(
            width: 130,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 4)], border: Border.all(color: AppColors.border, width: 0.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
                const Spacer(),
                FittedBox(child: Text(AppFormatters.formatCurrencyCompact(amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color))),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(ExpenseProvider provider) {
    final filters = [
      ('الكل', 'all'),
      ('وقود', 'fuel'),
      ('صيانة', 'maintenance'),
      ('رسوم طريق', 'toll'),
      ('مخالفات', 'violation'),
      ('تأمين', 'insurance'),
      ('متنوعة', 'miscellaneous'),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, type) = filters[index];
          final isSelected = _selectedFilter == type;
          final color = type == 'all' ? AppColors.primary : (AppConstants.expenseTypeColors[type] ?? AppColors.primary);
          return GestureDetector(
            onTap: () { setState(() => _selectedFilter = type); provider.setFilter(type); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? color : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? color : AppColors.border, width: 1)),
              child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : AppColors.textSecondary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final color = AppConstants.expenseTypeColors[expense.type] ?? AppColors.textHint;
    final icon = AppConstants.expenseTypeIcons[expense.type] ?? Icons.receipt_long;
    final typeLabel = AppConstants.expenseTypes[expense.type] ?? expense.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 4)], border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(
        children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color))),
                  const SizedBox(width: 8),
                  Text(expense.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text(AppFormatters.formatDate(expense.date), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  if (expense.vehicle != null) ...[
                    Text('  |  ', style: TextStyle(fontSize: 11, color: AppColors.textHint.withOpacity(0.5))),
                    Text(expense.vehicle!.plateNumber, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                  if (expense.serviceProvider != null && expense.serviceProvider!.isNotEmpty) ...[
                    Text('  |  ', style: TextStyle(fontSize: 11, color: AppColors.textHint.withOpacity(0.5))),
                    Text(expense.serviceProvider!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppFormatters.formatCurrency(expense.amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _deleteExpense(expense),
                child: Icon(Icons.delete_outline, size: 18, color: AppColors.textHint.withOpacity(0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await AppHelpers.showConfirmDialog(context,
      title: 'حذف المصروف',
      message: 'هل أنت متأكد من حذف هذا المصروف؟',
      isDestructive: true,
    );
    if (!confirm) return;
    await context.read<ExpenseProvider>().deleteExpense(expense.id!);
  }
}
