import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/driver.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';
import '../providers/driver_provider.dart';
import '../services/database_service.dart';

class AddDriverScreen extends StatefulWidget {
  final Driver? driver;

  const AddDriverScreen({super.key, this.driver});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _licenseExpiryDate;
  String _selectedStatus = 'active';
  int? _selectedVehicleId;
  List<Vehicle> _vehicles = [];
  bool _isSaving = false;
  bool _vehiclesLoaded = false;

  bool get _isEditing => widget.driver != null;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    if (_isEditing) {
      final d = widget.driver!;
      _nameController.text = d.name;
      _phoneController.text = d.phone;
      _licenseNumberController.text = d.licenseNumber;
      _licenseExpiryDate = d.licenseExpiryDate;
      _selectedStatus = d.status;
      _selectedVehicleId = d.vehicleId;
      _notesController.text = d.notes ?? '';
    }
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicles = await DatabaseService.getAllVehicles();
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _vehiclesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
      if (mounted) {
        setState(() => _vehiclesLoaded = true);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final initialDate = _licenseExpiryDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'اختر تاريخ انتهاء الرخصة',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _licenseExpiryDate = picked);
    }
  }

  Future<void> _save() async {
    AppHelpers.unfocus(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final driver = Driver(
        id: _isEditing ? widget.driver!.id : null,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        licenseExpiryDate: _licenseExpiryDate,
        status: _selectedStatus,
        vehicleId: _selectedVehicleId,
        assignedDate: (_selectedVehicleId != null && !_isEditing)
            ? DateTime.now()
            : widget.driver?.assignedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_isEditing) {
        await context.read<DriverProvider>().updateDriver(driver);
        AppHelpers.showSnackBar(context, 'تم تعديل بيانات السائق بنجاح');
      } else {
        await context.read<DriverProvider>().addDriver(driver);
        AppHelpers.showSnackBar(context, 'تم إضافة السائق بنجاح');
      }
      Navigator.pop(context, true);
    } catch (e) {
      AppHelpers.showSnackBar(context, 'حدث خطأ أثناء الحفظ', isError: true);
    }

    setState(() => _isSaving = false);
  }

  String _getVehicleLabel(Vehicle v) {
    return '${v.plateNumber} — ${v.make} ${v.model}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل بيانات السائق' : 'إضافة سائق'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Basic Info Section ──
            _buildSectionTitle('معلومات السائق الأساسية'),
            const SizedBox(height: 12),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل *',
                prefixIcon: Icon(Icons.person),
                hintText: 'أدخل اسم السائق',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال اسم السائق';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
                hintText: '01XXXXXXXXX',
              ),
            ),
            const SizedBox(height: 12),

            // License Number
            TextFormField(
              controller: _licenseNumberController,
              decoration: const InputDecoration(
                labelText: 'رقم الرخصة',
                prefixIcon: Icon(Icons.credit_card),
                hintText: 'أدخل رقم الرخصة',
              ),
            ),
            const SizedBox(height: 12),

            // License Expiry Date
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ انتهاء الرخصة',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _licenseExpiryDate != null
                      ? AppFormatters.formatDate(_licenseExpiryDate!)
                      : 'اختر التاريخ',
                  style: TextStyle(
                    fontSize: 16,
                    color: _licenseExpiryDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Status
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'الحالة',
                prefixIcon: Icon(Icons.info_outline),
              ),
              items: AppConstants.driverStatuses.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedStatus = value ?? 'active');
              },
            ),
            const SizedBox(height: 20),

            // ── Assignment Section ──
            _buildSectionTitle('تخصيص المركبة'),
            const SizedBox(height: 12),

            DropdownButtonFormField<int?>(
              value: _selectedVehicleId,
              decoration: const InputDecoration(
                labelText: 'المركبة المسندة',
                prefixIcon: Icon(Icons.directions_car),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('بدون مركبة'),
                ),
                ..._vehicles.map((v) {
                  return DropdownMenuItem<int?>(
                    value: v.id,
                    child: Text(
                      _getVehicleLabel(v),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedVehicleId = value);
              },
            ),
            const SizedBox(height: 20),

            // ── Notes Section ──
            _buildSectionTitle('ملاحظات'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // ── Save Button ──
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditing ? 'حفظ التعديلات' : 'إضافة السائق',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
