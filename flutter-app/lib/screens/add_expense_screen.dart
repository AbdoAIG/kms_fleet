import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/vehicle.dart';
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
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _providerController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _odometerController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'maintenance';
  int? _selectedVehicleId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  List<Vehicle> _vehicles = [];

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    if (_isEdit) {
      final e = widget.expense!;
      _selectedType = e.type;
      _selectedVehicleId = e.vehicleId;
      _selectedDate = e.date;
      _descController.text = e.description;
      _amountController.text = e.amount.toStringAsFixed(2);
      _providerController.text = e.serviceProvider ?? '';
      _invoiceController.text = e.invoiceNumber ?? '';
      _odometerController.text = e.odometerReading?.toString() ?? '';
      _notesController.text = e.notes ?? '';
    }
  }

  Future<void> _loadVehicles() async {
    final vehicles = await DatabaseService.getAllVehicles();
    if (mounted) setState(() => _vehicles = vehicles);
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _providerController.dispose();
    _invoiceController.dispose();
    _odometerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      AppHelpers.showSnackBar(context, 'اختر السيارة', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final expense = Expense(
        id: _isEdit ? widget.expense!.id : null,
        vehicleId: _selectedVehicleId!,
        type: _selectedType,
        amount: double.tryParse(_amountController.text) ?? 0,
        date: _selectedDate,
        description: _descController.text.trim(),
        serviceProvider: _providerController.text.trim().isEmpty ? null : _providerController.text.trim(),
        invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
        odometerReading: int.tryParse(_odometerController.text),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (_isEdit) {
        await DatabaseService.updateExpense(expense);
        if (mounted) AppHelpers.showSnackBar(context, 'تم تعديل المصروف بنجاح');
      } else {
        await DatabaseService.insertExpense(expense);
        if (mounted) AppHelpers.showSnackBar(context, 'تم إضافة المصروف بنجاح');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'حدث خطأ أثناء الحفظ', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل مصروف' : 'إضافة مصروف', style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Expense Type ──
            _buildSectionTitle('نوع المصروف'),
            _buildTypeDropdown(),
            const SizedBox(height: 16),

            // ── Vehicle ──
            _buildSectionTitle('السيارة'),
            _buildVehicleDropdown(),
            const SizedBox(height: 16),

            // ── Amount & Date ──
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildSectionTitle('المبلغ (ج.م)'),
                  _buildTextField(_amountController, '0.00', Icons.attach_money, keyboardType: TextInputType.number),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildSectionTitle('التاريخ'),
                  _buildDateField(),
                ])),
              ],
            ),
            const SizedBox(height: 16),

            // ── Description ──
            _buildSectionTitle('الوصف'),
            _buildTextField(_descController, 'وصف المصروف...', Icons.description),
            const SizedBox(height: 16),

            // ── Service Provider & Invoice ──
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildSectionTitle('مقدم الخدمة'),
                  _buildTextField(_providerController, 'اسم مقدم الخدمة', Icons.store),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildSectionTitle('رقم الفاتورة'),
                  _buildTextField(_invoiceController, 'رقم الفاتورة', Icons.receipt),
                ])),
              ],
            ),
            const SizedBox(height: 16),

            // ── Odometer ──
            _buildSectionTitle('قراءة العداد (كم)'),
            _buildTextField(_odometerController, 'اختياري', Icons.speed, keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            // ── Notes ──
            _buildSectionTitle('ملاحظات'),
            _buildTextField(_notesController, 'ملاحظات إضافية...', Icons.notes, maxLines: 3),
            const SizedBox(height: 24),

            // ── Save Button ──
            _buildSaveButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)));
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: DropdownButtonFormField<String>(
        value: _selectedType,
        decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none),
        items: AppConstants.expenseTypes.entries.map((e) {
          final icon = AppConstants.expenseTypeIcons[e.key] ?? Icons.receipt_long;
          final color = AppConstants.expenseTypeColors[e.key] ?? AppColors.textHint;
          return DropdownMenuItem(value: e.key, child: Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 8), Text(e.value, style: TextStyle(fontWeight: FontWeight.w600))]));
        }).toList(),
        onChanged: (v) { if (v != null) setState(() => _selectedType = v); },
      ),
    );
  }

  Widget _buildVehicleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: DropdownButtonFormField<int>(
        value: _selectedVehicleId,
        hint: const Text('اختر السيارة', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
        decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none),
        items: _vehicles.map((v) {
          return DropdownMenuItem(value: v.id, child: Text('${v.plateNumber} - ${v.make} ${v.model}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));
        }).toList(),
        onChanged: (v) { setState(() => _selectedVehicleId = v); },
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Icon(Icons.calendar_today, size: 18, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(AppFormatters.formatDate(_selectedDate), style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: _isSaving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(_isEdit ? 'حفظ التعديلات' : 'إضافة المصروف', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}
