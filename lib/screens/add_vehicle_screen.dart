import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../providers/vehicle_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _odometerController = TextEditingController();
  final _notesController = TextEditingController();

  // Technical Details
  final _vinController = TextEditingController();
  final _engineNumberController = TextEditingController();

  // Driver Info
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _driverLicenseController = TextEditingController();

  // Insurance & Registration
  final _insuranceNumberController = TextEditingController();

  // Work Info
  final _departmentController = TextEditingController();

  String _selectedColor = 'white';
  String _selectedFuelType = 'petrol';
  String _selectedStatus = 'active';
  String _selectedMake = '';
  String _selectedCategory = 'light';
  List<String> _filteredModels = [];

  String? _driverLicenseExpiry;
  String? _insuranceExpiry;
  String? _registrationExpiry;

  bool _isSaving = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.vehicle != null) {
      final v = widget.vehicle!;
      _plateController.text = v.plateNumber;
      _makeController.text = v.make;
      _modelController.text = v.model;
      _yearController.text = v.year.toString();
      _odometerController.text = v.currentOdometer.toString();
      _notesController.text = v.notes ?? '';
      _selectedColor = v.color;
      _selectedFuelType = v.fuelType;
      _selectedStatus = v.status;
      _selectedMake = v.make;
      _selectedCategory = v.vehicleCategory ?? 'light';
      _updateModels();

      // Technical Details
      _vinController.text = v.vin ?? '';
      _engineNumberController.text = v.engineNumber ?? '';

      // Driver Info
      _driverNameController.text = v.driverName ?? '';
      _driverPhoneController.text = v.driverPhone ?? '';
      _driverLicenseController.text = v.driverLicense ?? '';
      _driverLicenseExpiry = v.driverLicenseExpiry;

      // Insurance & Registration
      _insuranceNumberController.text = v.insuranceNumber ?? '';
      _insuranceExpiry = v.insuranceExpiry;
      _registrationExpiry = v.registrationExpiry;

      // Work Info
      _departmentController.text = v.department ?? '';
    }
  }

  void _updateModels() {
    setState(() {
      _filteredModels = AppConstants.vehicleModels[_selectedMake] ?? [];
    });
  }

  @override
  void dispose() {
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _odometerController.dispose();
    _notesController.dispose();
    _vinController.dispose();
    _engineNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _driverLicenseController.dispose();
    _insuranceNumberController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    AppHelpers.unfocus(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final vehicle = Vehicle(
        id: _isEditing ? widget.vehicle!.id : null,
        plateNumber: _plateController.text.trim(),
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        color: _selectedColor,
        fuelType: _selectedFuelType,
        currentOdometer: int.parse(_odometerController.text.trim()),
        status: _selectedStatus,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        vin: _vinController.text.trim().isEmpty
            ? null
            : _vinController.text.trim(),
        engineNumber: _engineNumberController.text.trim().isEmpty
            ? null
            : _engineNumberController.text.trim(),
        vehicleCategory: _selectedCategory,
        department: _departmentController.text.trim().isEmpty
            ? null
            : _departmentController.text.trim(),
        driverName: _driverNameController.text.trim().isEmpty
            ? null
            : _driverNameController.text.trim(),
        driverPhone: _driverPhoneController.text.trim().isEmpty
            ? null
            : _driverPhoneController.text.trim(),
        driverLicense: _driverLicenseController.text.trim().isEmpty
            ? null
            : _driverLicenseController.text.trim(),
        driverLicenseExpiry: _driverLicenseExpiry,
        insuranceNumber: _insuranceNumberController.text.trim().isEmpty
            ? null
            : _insuranceNumberController.text.trim(),
        insuranceExpiry: _insuranceExpiry,
        registrationExpiry: _registrationExpiry,
      );

      if (_isEditing) {
        await context.read<VehicleProvider>().updateVehicle(vehicle);
        AppHelpers.showSnackBar(context, 'تم تعديل المركبة بنجاح');
      } else {
        await context.read<VehicleProvider>().addVehicle(vehicle);
        AppHelpers.showSnackBar(context, 'تم إضافة المركبة بنجاح');
      }
      Navigator.pop(context, true);
    } catch (e) {
      AppHelpers.showSnackBar(context, 'حدث خطأ أثناء الحفظ', isError: true);
    }

    setState(() => _isSaving = false);
  }

  Future<void> _pickDate({required String field}) async {
    final initial = _getDateForField(field);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        final dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        switch (field) {
          case 'driverLicense':
            _driverLicenseExpiry = dateStr;
            break;
          case 'insurance':
            _insuranceExpiry = dateStr;
            break;
          case 'registration':
            _registrationExpiry = dateStr;
            break;
        }
      });
    }
  }

  DateTime? _getDateForField(String field) {
    final dateStr = switch (field) {
      'driverLicense' => _driverLicenseExpiry,
      'insurance' => _insuranceExpiry,
      'registration' => _registrationExpiry,
      _ => null,
    };
    if (dateStr == null) return null;
    try {
      final parts = dateStr.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return null;
    }
  }

  String _formatDateDisplay(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final parts = dateStr.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المركبة' : 'إضافة مركبة جديدة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== Section 1: بيانات المركبة الأساسية =====
            _buildSectionHeader(Icons.directions_car, 'بيانات المركبة الأساسية'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plateController,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'رقم اللوحة',
                prefixIcon: Icon(Icons.badge),
                hintText: 'أ ب ج 1234',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال رقم اللوحة';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMake.isEmpty ? null : _selectedMake,
              decoration: const InputDecoration(
                labelText: 'الماركة',
                prefixIcon: Icon(Icons.directions_car),
              ),
              items: AppConstants.vehicleMakes.map((make) {
                return DropdownMenuItem(
                  value: make,
                  child: Text(make),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMake = value ?? '';
                  _makeController.text = _selectedMake;
                  _modelController.clear();
                  _updateModels();
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار الماركة';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _modelController.text.isEmpty ? null : _modelController.text,
              decoration: const InputDecoration(
                labelText: 'الموديل',
                prefixIcon: Icon(Icons.time_to_leave),
              ),
              items: _filteredModels.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _modelController.text = value ?? '');
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار الموديل';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'سنة الصنع',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || int.tryParse(value.trim()) == null) {
                        return 'سنة غير صالحة';
                      }
                      final year = int.parse(value.trim());
                      if (year < 2000 || year > DateTime.now().year + 1) {
                        return 'سنة غير صالحة';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _odometerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عداد الكيلومتر',
                      prefixIcon: Icon(Icons.speed),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || int.tryParse(value.trim()) == null) {
                        return 'قيمة غير صالحة';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedColor,
                    decoration: const InputDecoration(
                      labelText: 'اللون',
                      prefixIcon: Icon(Icons.palette),
                    ),
                    items: AppConstants.vehicleColors.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedColor = value ?? 'white');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFuelType,
                    decoration: const InputDecoration(
                      labelText: 'نوع الوقود',
                      prefixIcon: Icon(Icons.local_gas_station),
                    ),
                    items: AppConstants.fuelTypes.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedFuelType = value ?? 'petrol');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'فئة المركبة',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: AppConstants.vehicleCategories.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value ?? 'light');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'الحالة',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    items: AppConstants.vehicleStatuses.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value ?? 'active');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ===== Section 2: بيانات فنية =====
            _buildSectionHeader(Icons.settings, 'بيانات فنية'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vinController,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'رقم الشاسيه (VIN)',
                prefixIcon: Icon(Icons.vpn_key),
                hintText: 'VIN Number',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _engineNumberController,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'رقم المحرك',
                prefixIcon: Icon(Icons.engineering),
                hintText: 'Engine Number',
              ),
            ),
            const SizedBox(height: 24),

            // ===== Section 3: بيانات السائق =====
            _buildSectionHeader(Icons.person, 'بيانات السائق'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _driverNameController,
              decoration: const InputDecoration(
                labelText: 'اسم السائق',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _driverPhoneController,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
                hintText: '01XXXXXXXXX',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _driverLicenseController,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'رقم الرخصة',
                prefixIcon: Icon(Icons.card_membership),
                hintText: 'License Number',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(field: 'driverLicense'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ انتهاء الرخصة',
                  prefixIcon: Icon(Icons.event),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(
                  _driverLicenseExpiry != null
                      ? _formatDateDisplay(_driverLicenseExpiry)
                      : 'غير محدد',
                  style: TextStyle(
                    fontSize: 16,
                    color: _driverLicenseExpiry != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ===== Section 4: بيانات التأمين والترخيص =====
            _buildSectionHeader(Icons.verified_user, 'بيانات التأمين والترخيص'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _insuranceNumberController,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'رقم التأمين',
                prefixIcon: Icon(Icons.security),
                hintText: 'Insurance Number',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(field: 'insurance'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ انتهاء التأمين',
                  prefixIcon: Icon(Icons.shield),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(
                  _insuranceExpiry != null
                      ? _formatDateDisplay(_insuranceExpiry)
                      : 'غير محدد',
                  style: TextStyle(
                    fontSize: 16,
                    color: _insuranceExpiry != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(field: 'registration'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ انتهاء الترخيص',
                  prefixIcon: Icon(Icons.assignment),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(
                  _registrationExpiry != null
                      ? _formatDateDisplay(_registrationExpiry)
                      : 'غير محدد',
                  style: TextStyle(
                    fontSize: 16,
                    color: _registrationExpiry != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ===== Section 5: معلومات العمل =====
            _buildSectionHeader(Icons.business, 'معلومات العمل'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _departmentController.text.isEmpty ? null : _departmentController.text,
              decoration: const InputDecoration(
                labelText: 'القسم / الإدارة',
                prefixIcon: Icon(Icons.corporate_fare),
              ),
              items: AppConstants.departments.map((dept) {
                return DropdownMenuItem(
                  value: dept,
                  child: Text(dept),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _departmentController.text = value ?? '');
              },
            ),
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

            // Save Button
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
                      _isEditing ? 'حفظ التعديلات' : 'إضافة المركبة',
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
