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

  String _selectedColor = 'white';
  String _selectedFuelType = 'petrol';
  String _selectedStatus = 'active';
  String _selectedMake = '';
  List<String> _filteredModels = [];

  bool _isSaving = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _plateController.text = widget.vehicle!.plateNumber;
      _makeController.text = widget.vehicle!.make;
      _modelController.text = widget.vehicle!.model;
      _yearController.text = widget.vehicle!.year.toString();
      _odometerController.text = widget.vehicle!.currentOdometer.toString();
      _notesController.text = widget.vehicle!.notes ?? '';
      _selectedColor = widget.vehicle!.color;
      _selectedFuelType = widget.vehicle!.fuelType;
      _selectedStatus = widget.vehicle!.status;
      _selectedMake = widget.vehicle!.make;
      _updateModels();
    }
  }

  void _updateModels() {
    setState(() {
      _filteredModels =
          AppConstants.vehicleModels[_selectedMake] ?? [];
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
            // Section: Basic Info
            _buildSectionTitle('معلومات المركبة الأساسية'),
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
            // Make Dropdown
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
            // Model Dropdown
            DropdownButtonFormField<String>(
              value: _modelController.text.isEmpty
                  ? null
                  : _modelController.text,
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
                      if (value == null ||
                          value.trim().isEmpty ||
                          int.tryParse(value.trim()) == null) {
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
                      if (value == null ||
                          value.trim().isEmpty ||
                          int.tryParse(value.trim()) == null) {
                        return 'قيمة غير صالحة';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section: Additional Info
            _buildSectionTitle('معلومات إضافية'),
            const SizedBox(height: 12),
            // Color Selection
            DropdownButtonFormField<String>(
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
            const SizedBox(height: 12),
            // Fuel Type
            DropdownButtonFormField<String>(
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
            const SizedBox(height: 12),
            // Status
            DropdownButtonFormField<String>(
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
            const SizedBox(height: 12),
            // Notes
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
