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
  final _searchController = TextEditingController();
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
  List<Vehicle> _filteredVehicles = [];
  String _searchQuery = '';
  Vehicle? _selectedVehicle;
  bool _showVehicleDropdown = false;

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
      _selectedVehicle = widget.vehicle;
      _searchController.text = widget.vehicle!.plateNumber;
      _odometerController.text =
          widget.vehicle!.currentOdometer.toString();
    }
  }

  Future<void> _loadVehicles() async {
    final provider = context.read<VehicleProvider>();
    setState(() {
      _vehicles = provider.allVehicles;
      _filteredVehicles = _vehicles;
    });
  }

  void _filterVehicles(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredVehicles = _vehicles;
        _showVehicleDropdown = false;
      } else {
        final q = query.trim().toLowerCase();
        _filteredVehicles = _vehicles.where((v) {
          return v.plateNumber.toLowerCase().contains(q) ||
              v.make.toLowerCase().contains(q) ||
              v.model.toLowerCase().contains(q) ||
              (v.driverName != null && v.driverName!.toLowerCase().contains(q)) ||
              (v.displayName.toLowerCase().contains(q));
        }).toList();
        _showVehicleDropdown = _filteredVehicles.isNotEmpty;
      }
    });
  }

  void _selectVehicle(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _selectedVehicleId = vehicle.id;
      _searchController.text = '${vehicle.plateNumber} - ${vehicle.make} ${vehicle.model}';
      _showVehicleDropdown = false;
      _odometerController.text = vehicle.currentOdometer.toString();
    });
  }

  void _clearVehicleSelection() {
    setState(() {
      _selectedVehicle = null;
      _selectedVehicleId = null;
      _searchController.clear();
      _showVehicleDropdown = false;
      _filteredVehicles = _vehicles;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

    // Only vehicle and type are mandatory
    if (_selectedVehicleId == null) {
      AppHelpers.showSnackBar(context, 'يرجى اختيار السيارة', isError: true);
      return;
    }
    if (_selectedType.isEmpty) {
      AppHelpers.showSnackBar(context, 'يرجى اختيار نوع الصيانة', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final record = MaintenanceRecord(
        id: _isEditing ? widget.record!.id : null,
        vehicleId: _selectedVehicleId!,
        maintenanceDate: _selectedDate,
        description: _descriptionController.text.trim().isEmpty
            ? AppConstants.maintenanceTypes[_selectedType] ?? 'صيانة'
            : _descriptionController.text.trim(),
        type: _selectedType,
        odometerReading: _odometerController.text.trim().isEmpty
            ? 0
            : (int.tryParse(_odometerController.text.trim()) ?? 0),
        cost: _costController.text.trim().isEmpty
            ? 0.0
            : (double.tryParse(_costController.text.trim()) ?? 0.0),
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
        final ok = await context.read<MaintenanceProvider>().updateRecord(record);
        if (ok) {
          AppHelpers.showSnackBar(context, 'تم تعديل سجل الصيانة بنجاح');
          Navigator.pop(context, true);
        } else {
          AppHelpers.showSnackBar(context, 'فشل تعديل سجل الصيانة - حاول مرة أخرى', isError: true);
        }
      } else {
        final id = await context.read<MaintenanceProvider>().addRecord(record);
        if (id > 0) {
          AppHelpers.showSnackBar(context, 'تم إضافة سجل الصيانة بنجاح');
          Navigator.pop(context, true);
        } else {
          AppHelpers.showSnackBar(context, 'فشل إضافة سجل الصيانة - حاول مرة أخرى', isError: true);
        }
      }
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
            // ── Vehicle Search ──
            _buildSectionTitle('السيارة *', isRequired: true),
            const SizedBox(height: 8),
            _buildVehicleSearchField(),
            if (_showVehicleDropdown)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _filteredVehicles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final v = _filteredVehicles[index];
                    return InkWell(
                      onTap: () => _selectVehicle(v),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppConstants.vehicleTypeColors[v.vehicleType]?.withOpacity(0.1) ?? AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                AppConstants.vehicleTypeIcons[v.vehicleType] ?? Icons.directions_car,
                                size: 20,
                                color: AppConstants.vehicleTypeColors[v.vehicleType] ?? AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.plateNumber,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${v.make} ${v.model} - ${AppConstants.vehicleTypes[v.vehicleType] ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (v.hasDriver) ...[
                              Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  v.driverName ?? '',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            // ── Maintenance Info ──
            _buildSectionTitle('تفاصيل الصيانة'),
            const SizedBox(height: 8),

            // Type (mandatory)
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'نوع الصيانة *',
                prefixIcon: const Icon(Icons.category),
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

            // Date Picker (optional)
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

            // Description (optional)
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'وصف الصيانة',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
                hintText: 'اختياري',
                hintStyle: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
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
                      hintText: 'اختياري',
                    ),
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

            // ── Cost Info (optional) ──
            _buildSectionTitle('التكاليف (اختياري)'),
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

            // ── Service Provider (optional) ──
            _buildSectionTitle('معلومات مقدم الخدمة (اختياري)'),
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

            // ── Next Maintenance (optional) ──
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
            // Attachments
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

  Widget _buildVehicleSearchField() {
    return TextFormField(
      controller: _searchController,
      onChanged: _filterVehicles,
      readOnly: _selectedVehicleId != null && !_showVehicleDropdown,
      decoration: InputDecoration(
        labelText: 'ابحث برقم السيارة أو اسم السائق *',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _selectedVehicleId != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: _clearVehicleSelection,
              )
            : null,
        hintText: 'مثال: 12345 أو أحمد',
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
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

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }
}
