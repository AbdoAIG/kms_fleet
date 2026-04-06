import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../models/vehicle.dart';
import '../providers/expense_provider.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _odometerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serviceProviderController = TextEditingController();
  final _invoiceController = TextEditingController();

  String _selectedType = 'fuel';
  int? _selectedVehicleId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isEditing = false;

  List<Vehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.expense != null;
    if (_isEditing) {
      final e = widget.expense!;
      _selectedType = e.type;
      _selectedVehicleId = e.vehicleId;
      _selectedDate = e.expenseDate;
      _amountController.text = e.amount.toStringAsFixed(2);
      if (e.odometerReading != null) {
        _odometerController.text = e.odometerReading!.toInt().toString();
      }
      _descriptionController.text = e.description ?? '';
      _serviceProviderController.text = e.serviceProvider ?? '';
      _invoiceController.text = e.invoiceNumber ?? '';
    }
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await DatabaseService.getAllVehicles();
    setState(() {
      _vehicles = vehicles;
      if (!_isEditing && vehicles.isNotEmpty) {
        _selectedVehicleId = vehicles.first.id;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _odometerController.dispose();
    _descriptionController.dispose();
    _serviceProviderController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    AppHelpers.unfocus(context);

    setState(() => _isSaving = true);

    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final odometerText = _odometerController.text.trim();
      final double? odometer =
          odometerText.isNotEmpty ? double.tryParse(odometerText) : null;

      final expense = Expense(
        id: widget.expense?.id,
        vehicleId: _selectedVehicleId,
        type: _selectedType,
        amount: amount,
        odometerReading: odometer,
        expenseDate: _selectedDate,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        serviceProvider: _serviceProviderController.text.trim().isNotEmpty
            ? _serviceProviderController.text.trim()
            : null,
        invoiceNumber: _invoiceController.text.trim().isNotEmpty
            ? _invoiceController.text.trim()
            : null,
      );

      final provider = context.read<ExpenseProvider>();
      if (_isEditing) {
        await provider.updateExpense(expense);
      } else {
        await provider.addExpense(expense);
      }

      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          _isEditing ? 'تم تحديث المصروف' : 'تم إضافة المصروف',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'حدث خطأ: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المصروف' : 'إضافة مصروف'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expense Type Selection
              const Text(
                'نوع المصروف',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.expenseTypes.entries.map((e) {
                  final icon =
                      AppConstants.expenseTypeIcons[e.key] ?? Icons.receipt_long;
                  final color =
                      AppConstants.expenseTypeColors[e.key] ?? AppColors.textHint;
                  final isSelected = _selectedType == e.key;
                  return ChoiceChip(
                    avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
                    label: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: AppColors.surfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (_) => setState(() => _selectedType = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'المبلغ (ر.س)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'يرجى إدخال المبلغ';
                  if (double.tryParse(v) == null) return 'يرجى إدخال رقم صحيح';
                  if (double.parse(v) <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Vehicle Selection
              DropdownButtonFormField<int>(
                value: _selectedVehicleId,
                decoration: InputDecoration(
                  labelText: 'المركبة (اختياري)',
                  prefixIcon: const Icon(Icons.directions_car),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('بدون مركبة'),
                  ),
                  ..._vehicles.map((v) {
                    return DropdownMenuItem(
                      value: v.id,
                      child: Text(
                        '${v.plateNumber} - ${v.make} ${v.model}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _selectedVehicleId = v),
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'التاريخ',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppFormatters.formatDate(_selectedDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Odometer Field
              TextFormField(
                controller: _odometerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'قراءة العداد (اختياري)',
                  prefixIcon: const Icon(Icons.speed),
                  suffixText: 'كم',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.description),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Service Provider Field
              TextFormField(
                controller: _serviceProviderController,
                decoration: InputDecoration(
                  labelText: 'مقدم الخدمة (اختياري)',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Invoice Number Field
              TextFormField(
                controller: _invoiceController,
                decoration: InputDecoration(
                  labelText: 'رقم الفاتورة (اختياري)',
                  prefixIcon: const Icon(Icons.receipt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEditing ? Icons.check : Icons.add,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEditing ? 'تحديث المصروف' : 'إضافة المصروف',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
