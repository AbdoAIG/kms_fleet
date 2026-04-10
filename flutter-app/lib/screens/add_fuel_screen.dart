import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fuel_record.dart';
import '../models/vehicle.dart';
import '../providers/fuel_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/attachment_picker_widget.dart';

class AddFuelScreen extends StatefulWidget {
  final FuelRecord? record;
  final Vehicle? vehicle;

  const AddFuelScreen({super.key, this.record, this.vehicle});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _odometerController = TextEditingController();
  final _litersController = TextEditingController();
  final _costPerLiterController = TextEditingController();
  final _stationNameController = TextEditingController();
  final _stationLocationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedFuelType = 'petrol';
  bool _fullTank = true;
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
      _odometerController.text =
          widget.record!.odometerReading.toString();
      _litersController.text = widget.record!.liters.toString();
      _costPerLiterController.text =
          widget.record!.costPerLiter.toString();
      _stationNameController.text =
          widget.record!.stationName ?? '';
      _stationLocationController.text =
          widget.record!.stationLocation ?? '';
      _notesController.text = widget.record!.notes ?? '';
      _selectedDate = widget.record!.fillDate;
      _selectedFuelType = widget.record!.fuelType;
      _fullTank = widget.record!.fullTank;
      _selectedVehicleId = widget.record!.vehicleId;
    } else if (widget.vehicle != null) {
      _selectedVehicleId = widget.vehicle!.id;
      _selectedVehicle = widget.vehicle;
      _searchController.text = '${widget.vehicle!.plateNumber} - ${widget.vehicle!.make} ${widget.vehicle!.model}';
      _odometerController.text =
          widget.vehicle!.currentOdometer.toString();
      _selectedFuelType = widget.vehicle!.fuelType;
    }

    _litersController.addListener(_updateTotalCost);
    _costPerLiterController.addListener(_updateTotalCost);
  }

  Future<void> _loadVehicles() async {
    final provider = context.read<VehicleProvider>();
    setState(() {
      _vehicles = provider.allVehicles;
      _filteredVehicles = _vehicles;
    });
    // After loading vehicles, set selected vehicle info for editing
    if (_selectedVehicleId != null && _selectedVehicle == null) {
      final vehicle = _vehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;
      if (vehicle != null) {
        setState(() {
          _selectedVehicle = vehicle;
          _searchController.text = '${vehicle.plateNumber} - ${vehicle.make} ${vehicle.model}';
        });
      }
    }
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
    _odometerController.dispose();
    _litersController.dispose();
    _costPerLiterController.dispose();
    _stationNameController.dispose();
    _stationLocationController.dispose();
    _notesController.dispose();
    _litersController.removeListener(_updateTotalCost);
    _costPerLiterController.removeListener(_updateTotalCost);
    super.dispose();
  }

  void _updateTotalCost() {
    // Total cost is derived; re-trigger a setState so the read-only
    // display updates when either field changes.
    setState(() {});
  }

  double get _totalCost {
    final liters = double.tryParse(_litersController.text) ?? 0.0;
    final costPerLiter =
        double.tryParse(_costPerLiterController.text) ?? 0.0;
    return liters * costPerLiter;
  }

  Future<void> _save() async {
    AppHelpers.unfocus(context);

    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      AppHelpers.showSnackBar(
          context, 'يرجى اختيار السيارة',
          isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final record = FuelRecord(
        id: _isEditing ? widget.record!.id : null,
        vehicleId: _selectedVehicleId!,
        fillDate: _selectedDate,
        odometerReading:
            int.parse(_odometerController.text.trim()),
        liters: double.parse(_litersController.text.trim()),
        costPerLiter:
            double.parse(_costPerLiterController.text.trim()),
        fuelType: _selectedFuelType,
        fullTank: _fullTank,
        stationName:
            _stationNameController.text.trim().isEmpty
                ? null
                : _stationNameController.text.trim(),
        stationLocation:
            _stationLocationController.text.trim().isEmpty
                ? null
                : _stationLocationController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_isEditing) {
        final ok = await context
            .read<FuelProvider>()
            .updateFuelRecord(record);
        if (ok) {
          AppHelpers.showSnackBar(context, 'تم تعديل سجل الوقود بنجاح');
          Navigator.pop(context, true);
        } else {
          AppHelpers.showSnackBar(context, 'فشل تعديل سجل الوقود - حاول مرة أخرى', isError: true);
        }
      } else {
        final id = await context
            .read<FuelProvider>()
            .addFuelRecord(record);
        if (id > 0) {
          AppHelpers.showSnackBar(context, 'تم إضافة سجل الوقود بنجاح');
          Navigator.pop(context, true);
        } else {
          AppHelpers.showSnackBar(context, 'فشل إضافة سجل الوقود - حاول مرة أخرى', isError: true);
        }
      }
    } catch (e) {
      AppHelpers.showSnackBar(
          context, 'حدث خطأ أثناء الحفظ',
          isError: true);
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'تعديل سجل الوقود'
            : 'إضافة سجل وقود'),
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

            // ── Fill Info ──
            _buildSectionTitle('تفاصيل التعبئة'),
            const SizedBox(height: 8),

            // Date Picker
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ التعبئة',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Odometer
            TextFormField(
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
            const SizedBox(height: 12),

            // Liters & Cost Per Liter
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _litersController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'الكمية (لتر)',
                      prefixIcon: Icon(Icons.water_drop),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          double.tryParse(value.trim()) ==
                              null) {
                        return 'قيمة غير صالحة';
                      }
                      if (double.parse(value.trim()) <= 0) {
                        return 'يجب أن تكون أكبر من 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _costPerLiterController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'سعر اللتر (ج.م)',
                      prefixIcon:
                          Icon(Icons.monetization_on),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          double.tryParse(value.trim()) ==
                              null) {
                        return 'قيمة غير صالحة';
                      }
                      if (double.parse(value.trim()) <= 0) {
                        return 'يجب أن تكون أكبر من 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total Cost (auto-calculated, read-only)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'التكلفة الإجمالية',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_totalCost.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'تلقائي',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Fuel Type
            DropdownButtonFormField<String>(
              value: _selectedFuelType,
              decoration: const InputDecoration(
                labelText: 'نوع الوقود',
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              items: AppConstants.fuelTypes.entries
                  .map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        _getFuelTypeIcon(entry.key),
                        size: 18,
                        color:
                            _getFuelTypeColor(entry.key),
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(
                  () => _selectedFuelType =
                      value ?? 'petrol'),
            ),
            const SizedBox(height: 12),

            // Full Tank Checkbox
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: _fullTank,
                onChanged: (value) =>
                    setState(() => _fullTank = value ?? true),
                title: const Text(
                  'تعبئة خزان كامل',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'يتم احتساب استهلاك الوقود عند التعبئة الكاملة',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            const SizedBox(height: 20),

            // ── Station Info (optional) ──
            _buildSectionTitle('معلومات المحطة (اختياري)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stationNameController,
              decoration: const InputDecoration(
                labelText: 'اسم المحطة',
                prefixIcon: Icon(Icons.ev_station),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stationLocationController,
              decoration: const InputDecoration(
                labelText: 'موقع المحطة',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 20),

            // ── Notes ──
            _buildSectionTitle('ملاحظات (اختياري)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            // Attachments (only when editing an existing record)
            if (_isEditing && widget.record!.id != null) ...[
              const SizedBox(height: 20),
              _buildSectionTitle('مرفقات الوقود'),
              const SizedBox(height: 8),
              AttachmentPickerWidget(
                entityType: 'fuel',
                entityId: widget.record!.id!,
                onAttachmentsChanged: (paths) {
                  debugPrint('Fuel attachments updated: ${paths.length}');
                },
                maxAttachments: 3,
              ),
            ],
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
                      _isEditing
                          ? 'حفظ التعديلات'
                          : 'إضافة سجل الوقود',
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

  // ──────────────────────────── Helpers ────────────────────────────

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

  Color _getFuelTypeColor(String fuelType) {
    switch (fuelType) {
      case 'petrol':
        return AppColors.accent;
      case 'diesel':
        return AppColors.info;
      case 'electric':
        return AppColors.success;
      case 'hybrid':
        return AppColors.primary;
      case 'gas':
        return AppColors.oilColor;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getFuelTypeIcon(String fuelType) {
    switch (fuelType) {
      case 'petrol':
        return Icons.local_gas_station;
      case 'diesel':
        return Icons.oil_barrel;
      case 'electric':
        return Icons.bolt;
      case 'hybrid':
        return Icons.electric_car;
      case 'gas':
        return Icons.propane_tank;
      default:
        return Icons.local_gas_station;
    }
  }
}
