import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/checklist.dart';
import '../models/vehicle.dart';
import '../providers/checklist_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';

class AddChecklistScreen extends StatefulWidget {
  final Checklist? checklist;

  const AddChecklistScreen({super.key, this.checklist});

  @override
  State<AddChecklistScreen> createState() => _AddChecklistScreenState();
}

class _AddChecklistScreenState extends State<AddChecklistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _inspectorController = TextEditingController();
  final _notesController = TextEditingController();

  // One TextEditingController per checklist item (defect notes)
  final Map<int, TextEditingController> _defectNoteControllers = {};

  int? _selectedVehicleId;
  String _selectedType = 'pre_trip';
  List<ChecklistItem> _items = [];
  List<Vehicle> _vehicles = [];

  bool _isSaving = false;
  bool get _isEditing => widget.checklist != null;

  // ── Pre-defined inspection items by type ──────────────────────────────

  static const List<_InspectionDef> _preTripItems = [
    _InspectionDef('الإطارات', 'حالة الهواء والتآكل', Icons.tire_repair),
    _InspectionDef('الأضواء', 'أمامية، خلفية، فرامل، إشارات', Icons.lightbulb),
    _InspectionDef('الفرامل', 'بدواسات وفرامل يدوية', Icons.dangerous),
    _InspectionDef('الزيوت والسوائل', 'مستوى الزيوت والسوائل', Icons.oil_barrel),
    _InspectionDef('المرايا والزجاج', 'حالة المرايا والنوافذ', Icons.remove_red_eye),
    _InspectionDef('مقود وتوجيه', 'المقود ونظام التوجيه', Icons.settings),
    _InspectionDef('مقاعد وأحزمة أمان', 'حالة المقاعد والأحزمة', Icons.airline_seat_recline_extra),
    _InspectionDef('معدات الطوارئ', 'طفاية، مثلث', Icons.medical_services),
    _InspectionDef('حالة الهيكل الخارجي', 'فحص جسم السيارة', Icons.directions_car),
    _InspectionDef('الوثائق', 'رخصة، تأمين', Icons.description),
  ];

  static const List<_InspectionDef> _postTripExtraItems = [
    _InspectionDef('حالة المحرك', 'حرارة المحرك', Icons.thermostat),
    _InspectionDef('المسافة المقطوعة', 'تسجيل المسافة', Icons.straighten),
  ];

  static const List<_InspectionDef> _weeklyExtraItems = [
    _InspectionDef('البطارية', 'حالة البطارية والموصلات', Icons.battery_charging_full),
    _InspectionDef('التكييف', 'أداء التكييف', Icons.ac_unit),
    _InspectionDef('ناقل الحركة', 'حالة ناقل الحركة', Icons.settings_applications),
    _InspectionDef('نظام التعليق', 'المساعدات واليايات', Icons.car_repair),
  ];

  // ── Type metadata ─────────────────────────────────────────────────────

  static const Map<String, String> _typeLabels = {
    'pre_trip': 'ما قبل الرحلة',
    'post_trip': 'ما بعد الرحلة',
    'weekly': 'أسبوعي',
  };

  static const Map<String, IconData> _typeIcons = {
    'pre_trip': Icons.exit_to_app,
    'post_trip': Icons.login,
    'weekly': Icons.calendar_view_week,
  };

  static const Map<String, Color> _typeColors = {
    'pre_trip': Color(0xFF0277BD),
    'post_trip': Color(0xFF6A1B9A),
    'weekly': Color(0xFFE65100),
  };

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _buildItems();

    if (_isEditing) {
      _selectedVehicleId = widget.checklist!.vehicleId;
      _selectedType = widget.checklist!.type;
      _odometerController.text = widget.checklist!.odometerReading.toString();
      _inspectorController.text = widget.checklist!.inspectorName ?? '';
      _notesController.text = widget.checklist!.notes ?? '';
      _items = List.from(widget.checklist!.items);
      for (int i = 0; i < _items.length; i++) {
        _defectNoteControllers[i] = TextEditingController(
            text: _items[i].defectNotes ?? '');
      }
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _inspectorController.dispose();
    _notesController.dispose();
    for (final c in _defectNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Load vehicles ─────────────────────────────────────────────────────

  void _loadVehicles() {
    final provider = context.read<VehicleProvider>();
    setState(() {
      _vehicles = provider.allVehicles;
    });
  }

  // ── Build items based on type ─────────────────────────────────────────

  void _buildItems() {
    // Dispose old controllers
    for (final c in _defectNoteControllers.values) {
      c.dispose();
    }
    _defectNoteControllers.clear();

    final defs = <_InspectionDef>[
      ..._preTripItems,
    ];

    if (_selectedType == 'post_trip' || _selectedType == 'weekly') {
      defs.addAll(_postTripExtraItems);
    }

    if (_selectedType == 'weekly') {
      defs.addAll(_weeklyExtraItems);
    }

    setState(() {
      _items = defs
          .map((d) => ChecklistItem(
                title: d.title,
                description: d.description,
              ))
          .toList();

      for (int i = 0; i < _items.length; i++) {
        _defectNoteControllers[i] = TextEditingController();
      }
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────

  Future<void> _save() async {
    AppHelpers.unfocus(context);

    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      AppHelpers.showSnackBar(context, 'يرجى اختيار السيارة', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Update defect notes from controllers into items
      final updatedItems = <ChecklistItem>[];
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        final notes = _defectNoteControllers[i]?.text.trim();
        updatedItems.add(item.copyWith(
          defectNotes: (notes != null && notes.isNotEmpty) ? notes : null,
        ));
      }

      // Calculate score
      final total = updatedItems.length;
      final passed = updatedItems.where((i) => i.isChecked).length;
      final score = total > 0 ? (passed / total) * 100 : 0.0;

      // Determine status
      final hasFailed = updatedItems.any((i) => !i.isChecked && i.hasDefect);
      final allChecked = updatedItems.every((i) => i.isChecked);
      String status;
      if (allChecked && passed == total) {
        status = 'passed';
      } else if (hasFailed || score < 70) {
        status = 'failed';
      } else {
        status = 'pending';
      }

      final checklist = Checklist(
        id: _isEditing ? widget.checklist!.id : null,
        vehicleId: _selectedVehicleId!,
        type: _selectedType,
        inspectionDate: DateTime.now(),
        odometerReading: int.parse(_odometerController.text.trim()),
        items: updatedItems,
        inspectorName: _inspectorController.text.trim().isEmpty
            ? null
            : _inspectorController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: status,
        overallScore: score,
      );

      if (_isEditing) {
        final ok = await context.read<ChecklistProvider>().updateChecklist(checklist);
        if (ok) {
          AppHelpers.showSnackBar(context, 'تم تعديل قائمة الفحص بنجاح');
          Navigator.pop(context, true);
        } else {
          AppHelpers.showSnackBar(context, 'فشل تعديل قائمة الفحص - حاول مرة أخرى', isError: true);
        }
      } else {
        final id = await context.read<ChecklistProvider>().addChecklist(checklist);
        if (id > 0) {
          AppHelpers.showSnackBar(context, 'تم إضافة قائمة الفحص بنجاح');
          Navigator.pop(context, true);
        } else {
          AppHelpers.showSnackBar(context, 'فشل إضافة قائمة الفحص - حاول مرة أخرى', isError: true);
        }
      }
    } catch (e) {
      AppHelpers.showSnackBar(context, 'حدث خطأ أثناء الحفظ', isError: true);
    }

    setState(() => _isSaving = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل قائمة الفحص' : 'إضافة قائمة فحص'),
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
            // ── Vehicle Selection ──
            _buildSectionTitle('السيارة'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedVehicleId,
              decoration: const InputDecoration(
                labelText: 'اختر السيارة',
                prefixIcon: Icon(Icons.directions_car),
              ),
              items: _vehicles.map((v) {
                return DropdownMenuItem(
                  value: v.id,
                  child: Text(
                    '${v.make} ${v.model} - ${v.plateNumber}',
                    overflow: TextOverflow.ellipsis,
                  ),
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
            const SizedBox(height: 24),

            // ── Checklist Type ──
            _buildSectionTitle('نوع الفحص'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeCard('pre_trip'),
                const SizedBox(width: 10),
                _buildTypeCard('post_trip'),
                const SizedBox(width: 10),
                _buildTypeCard('weekly'),
              ],
            ),
            const SizedBox(height: 24),

            // ── Inspector & Odometer ──
            _buildSectionTitle('معلومات الفحص'),
            const SizedBox(height: 8),
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
                  child: TextFormField(
                    controller: _inspectorController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المفتش',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Checklist Items ──
            _buildSectionTitle(
                'بنود الفحص (${_items.length} بند)'),
            const SizedBox(height: 8),

            // Summary row
            if (_items.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assessment,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم فحص ${_items.where((i) => i.isChecked).length} من ${_items.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      _items.where((i) => i.hasDefect).length > 0
                          ? '${_items.where((i) => i.hasDefect).length} أعطال'
                          : 'لا أعطال',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _items.where((i) => i.hasDefect).length > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Items list
            ...List.generate(_items.length, (index) {
              return _buildChecklistItem(index);
            }),
            const SizedBox(height: 24),

            // ── Notes ──
            _buildSectionTitle('ملاحظات إضافية'),
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
            const SizedBox(height: 32),

            // ── Submit Button ──
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isEditing ? 'حفظ التعديلات' : 'حفظ قائمة الفحص',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Type selection card ───────────────────────────────────────────────

  Widget _buildTypeCard(String type) {
    final isSelected = _selectedType == type;
    final color = _typeColors[type] ?? AppColors.textSecondary;
    final icon = _typeIcons[type] ?? Icons.fact_check;
    final label = _typeLabels[type] ?? type;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (!isSelected) {
                setState(() => _selectedType = type);
                _buildItems();
              }
            },
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isSelected ? color : AppColors.textHint,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Checklist item row ────────────────────────────────────────────────

  Widget _buildChecklistItem(int index) {
    final item = _items[index];

    // Find matching icon from definitions
    final allDefs = [
      ..._preTripItems,
      ..._postTripExtraItems,
      ..._weeklyExtraItems,
    ];
    final def = allDefs.firstWhere(
      (d) => d.title == item.title,
      orElse: () => const _InspectionDef('', '', Icons.checklist),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.hasDefect
              ? AppColors.error.withOpacity(0.4)
              : item.isChecked
                  ? AppColors.success.withOpacity(0.4)
                  : AppColors.border,
          width: item.hasDefect || item.isChecked ? 1 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main row ──
            Row(
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (item.isChecked
                            ? AppColors.success
                            : item.hasDefect
                                ? AppColors.error
                                : AppColors.textHint)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    def.icon,
                    size: 18,
                    color: item.isChecked
                        ? AppColors.success
                        : item.hasDefect
                            ? AppColors.error
                            : AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 10),
                // Title & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          decoration: item.hasDefect
                              ? TextDecoration.none
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Passed checkbox
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _items[index] = item.copyWith(
                        isChecked: !item.isChecked,
                        hasDefect: false,
                      );
                      _defectNoteControllers[index]?.clear();
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.isChecked
                          ? AppColors.success
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: item.isChecked
                            ? AppColors.success
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: item.isChecked
                        ? const Icon(Icons.check,
                            size: 20, color: Colors.white)
                        : Icon(Icons.check_box_outline_blank,
                            size: 20, color: AppColors.textHint),
                  ),
                ),
                const SizedBox(width: 6),
                // Failed (defect) button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _items[index] = item.copyWith(
                        isChecked: false,
                        hasDefect: !item.hasDefect,
                        defectNotes: !item.hasDefect ? '' : null,
                      );
                      if (!item.hasDefect) {
                        _defectNoteControllers[index]?.clear();
                      }
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.hasDefect
                          ? AppColors.error
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: item.hasDefect
                            ? AppColors.error
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: item.hasDefect
                        ? const Icon(Icons.close,
                            size: 20, color: Colors.white)
                        : const Icon(Icons.dangerous_outlined,
                            size: 20, color: AppColors.textHint),
                  ),
                ),
              ],
            ),

            // ── Defect notes (shown when hasDefect) ──
            if (item.hasDefect) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _defectNoteControllers[index],
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'وصف العيب...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                        filled: true,
                        fillColor: AppColors.errorLight,
                        prefixIcon: const Icon(Icons.edit_note,
                            size: 16, color: AppColors.error),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _items[index] = item.copyWith(
                            defectNotes:
                                value.trim().isEmpty ? null : value.trim(),
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Photo placeholder button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        size: 18, color: AppColors.error),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────

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

// ── Helper class for inspection item definitions ──────────────────────────

class _InspectionDef {
  final String title;
  final String description;
  final IconData icon;

  const _InspectionDef(this.title, this.description, this.icon);
}
