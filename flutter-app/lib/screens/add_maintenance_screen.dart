import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../providers/maintenance_provider.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/attachment_picker_widget.dart';

class AddMaintenanceScreen extends StatefulWidget {
  final MaintenanceRecord? record;
  final Vehicle? vehicle;

  const AddMaintenanceScreen({super.key, this.record, this.vehicle});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _odometerController = TextEditingController();
  final _costController = TextEditingController();
  final _laborCostController = TextEditingController();
  final _serviceProviderController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _partsUsedController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime? _nextMaintenanceDate;
  String _selectedType = 'oil_change';
  String _selectedPriority = 'medium';
  String _selectedStatus = 'pending';
  int? _selectedVehicleId;
  List<Vehicle> _vehicles = [];

  bool _isSaving = false;
  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    _loadVehicles();

    if (_isEditing) {
      _descriptionController.text = widget.record!.description;
      _odometerController.text = widget.record!.odometerReading.toString();
      _costController.text = widget.record!.cost.toString();
      _laborCostController.text =
          (widget.record!.laborCost ?? 0).toString();
      _serviceProviderController.text =
          widget.record!.serviceProvider ?? '';
      _invoiceController.text = widget.record!.invoiceNumber ?? '';
      _partsUsedController.text = widget.record!.partsUsed ?? '';
      _notesController.text = widget.record!.notes ?? '';
      _selectedDate = widget.record!.maintenanceDate;
      _nextMaintenanceDate = widget.record!.nextMaintenanceDate;
      _selectedType = widget.record!.type;
      _selectedPriority = widget.record!.priority;
      _selectedStatus = widget.record!.status;
      _selectedVehicleId = widget.record!.vehicleId;
    } else if (widget.vehicle != null) {
      _selectedVehicleId = widget.vehicle!.id;
      _odometerController.text =
          widget.vehicle!.currentOdometer.toString();
    }
  }

  Future<void> _loadVehicles() async {
    final provider = context.read<VehicleProvider>();
    setState(() {
      _vehicles = provider.allVehicles;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _odometerController.dispose();
    _costController.dispose();
    _laborCostController.dispose();
    _serviceProviderController.dispose();
    _invoiceController.dispose();
    _partsUsedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    AppHelpers.unfocus(context);

    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      AppHelpers.showSnackBar(context, 'يرجى اختيار المركبة', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final record = MaintenanceRecord(
        id: _isEditing ? widget.record!.id : null,
        vehicleId: _selectedVehicleId!,
        maintenanceDate: _selectedDate,
        description: _descriptionController.text.trim(),
        type: _selectedType,
        odometerReading: int.parse(_odometerController.text.trim()),
        cost: double.parse(_costController.text.trim()),
        laborCost: _laborCostController.text.trim().isEmpty
            ? null
            : double.parse(_laborCostController.text.trim()),
        serviceProvider: _serviceProviderController.text.trim().isEmpty
            ? null
            : _serviceProviderController.text.trim(),
        invoiceNumber: _invoiceController.text.trim().isEmpty
            ? null
            : _invoiceController.text.trim(),
        priority: _selectedPriority,
        status: _selectedStatus,
        partsUsed: _partsUsedController.text.trim().isEmpty
            ? null
            : _partsUsedController.text.trim(),
        nextMaintenanceDate: _nextMaintenanceDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_isEditing) {
        await context.read<MaintenanceProvider>().updateRecord(record);
        AppHelpers.showSnackBar(context, 'تم تعديل سجل الصيانة بنجاح');
      } else {
        await context.read<MaintenanceProvider>().addRecord(record);
        AppHelpers.showSnackBar(context, 'تم إضافة سجل الصيانة بنجاح');
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
        title: Text(_isEditing ? 'تعديل سجل الصيانة' : 'إضافة سجل صيانة'),
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
            // Vehicle Selection
            _buildSectionTitle('المركبة'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedVehicleId,
              decoration: const InputDecoration(
                labelText: 'اختر المركبة',
                prefixIcon: Icon(Icons.directions_car),
              ),
              items: _vehicles.map((v) {
                return DropdownMenuItem(
                  value: v.id,
                  child: Text('${v.make} ${v.model} - ${v.plateNumber}',
                      overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicleId = value;
                  final vehicle = _vehicles.firstWhere(
                    (v) => v.id == value,
                    orElse: () => Vehicle(
                      plateNumber: '',
                      make: '',
                      model: '',
                      year: 2024,
                      color: 'white',
                      fuelType: 'petrol',
                      currentOdometer: 0,
                      status: 'active',
                    ),
                  );
                  _odometerController.text =
                      vehicle.currentOdometer.toString();
                });
              },
            ),
            const SizedBox(height: 20),

            // Maintenance Info
            _buildSectionTitle('تفاصيل الصيانة'),
            const SizedBox(height: 8),

            // Date Picker
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ الصيانة',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'نوع الصيانة',
                prefixIcon: Icon(Icons.category),
              ),
              items: AppConstants.maintenanceTypes.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        AppConstants.maintenanceTypeIcons[entry.key] ??
                            Icons.build,
                        size: 18,
                        color: AppConstants.maintenanceTypeColors[entry.key] ??
                            AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedType = value ?? 'other'),
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'وصف الصيانة',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال وصف الصيانة';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
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
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'الأولوية',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: AppConstants.priorities.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) => setState(
                        () => _selectedPriority = value ?? 'medium'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'الحالة',
                prefixIcon: Icon(Icons.info_outline),
              ),
              items: AppConstants.maintenanceStatuses.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedStatus = value ?? 'pending'),
            ),
            const SizedBox(height: 20),

            // Cost Info
            _buildSectionTitle('التكاليف'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _costController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'تكلفة القطع',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          double.tryParse(value.trim()) == null) {
                        return 'قيمة غير صالحة';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _laborCostController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'تكلفة العمالة',
                      prefixIcon: Icon(Icons.engineering),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Service Provider Info
            _buildSectionTitle('معلومات مقدم الخدمة'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _serviceProviderController,
              decoration: const InputDecoration(
                labelText: 'مقدم الخدمة',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _invoiceController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'رقم الفاتورة',
                prefixIcon: Icon(Icons.receipt),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _partsUsedController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'القطع المستخدمة',
                prefixIcon: Icon(Icons.inventory_2),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Next Maintenance
            _buildSectionTitle('الصيانة القادمة (اختياري)'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickNextDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ الصيانة القادمة',
                  prefixIcon: Icon(Icons.event),
                ),
                child: Text(
                  _nextMaintenanceDate != null
                      ? '${_nextMaintenanceDate!.day}/${_nextMaintenanceDate!.month}/${_nextMaintenanceDate!.year}'
                      : 'غير محدد',
                  style: TextStyle(
                    fontSize: 16,
                    color: _nextMaintenanceDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            // Attachments (only when editing an existing record)
            if (_isEditing && widget.record!.id != null) ...[
              const SizedBox(height: 20),
              _buildSectionTitle('مرفقات الصيانة'),
              const SizedBox(height: 8),
              AttachmentPickerWidget(
                entityType: 'maintenance',
                entityId: widget.record!.id!,
                onAttachmentsChanged: (paths) {
                  debugPrint('Maintenance attachments updated: ${paths.length}');
                },
                maxAttachments: 5,
              ),
            ],
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
                      _isEditing ? 'حفظ التعديلات' : 'إضافة سجل الصيانة',
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickNextDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextMaintenanceDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _nextMaintenanceDate = picked);
    }
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
