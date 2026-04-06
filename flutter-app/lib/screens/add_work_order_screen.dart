import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/work_order.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../providers/vehicle_provider.dart';
import '../providers/work_order_provider.dart';
import '../widgets/attachment_picker_widget.dart';

class AddWorkOrderScreen extends StatefulWidget {
  final WorkOrder? workOrder;

  const AddWorkOrderScreen({super.key, this.workOrder});

  @override
  State<AddWorkOrderScreen> createState() => _AddWorkOrderScreenState();
}

class _AddWorkOrderScreenState extends State<AddWorkOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _technicianNameController = TextEditingController();
  final _technicianPhoneController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  final _actualCostController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'maintenance';
  String _selectedPriority = 'medium';
  int? _selectedVehicleId;
  List<Vehicle> _vehicles = [];

  bool _isSaving = false;
  bool get _isEditing => widget.workOrder != null;

  // ── Work order type/status/priority maps ──
  static const Map<String, String> _workOrderTypes = {
    'maintenance': 'صيانة',
    'repair': 'إصلاح',
    'inspection': 'فحص',
  };

  static const Map<String, IconData> _workOrderTypeIcons = {
    'maintenance': Icons.build,
    'repair': Icons.construction,
    'inspection': Icons.fact_check,
  };

  static const Map<String, Color> _workOrderTypeColors = {
    'maintenance': AppColors.primary,
    'repair': AppColors.accent,
    'inspection': AppColors.info,
  };

  @override
  void initState() {
    super.initState();
    _loadVehicles();

    if (_isEditing) {
      final wo = widget.workOrder!;
      _selectedVehicleId = wo.vehicleId;
      _selectedType = wo.type;
      _selectedPriority = wo.priority;
      _descriptionController.text = wo.description ?? '';
      _technicianNameController.text = wo.technicianName ?? '';
      _technicianPhoneController.text = wo.technicianPhone ?? '';
      _estimatedCostController.text =
          wo.estimatedCost?.toStringAsFixed(2) ?? '';
      _actualCostController.text = wo.actualCost?.toStringAsFixed(2) ?? '';
      _notesController.text = wo.notes ?? '';
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
    _technicianNameController.dispose();
    _technicianPhoneController.dispose();
    _estimatedCostController.dispose();
    _actualCostController.dispose();
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
      final order = WorkOrder(
        id: _isEditing ? widget.workOrder!.id : null,
        vehicleId: _selectedVehicleId!,
        type: _selectedType,
        status: _isEditing ? widget.workOrder!.status : 'open',
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        technicianName: _technicianNameController.text.trim().isEmpty
            ? null
            : _technicianNameController.text.trim(),
        technicianPhone: _technicianPhoneController.text.trim().isEmpty
            ? null
            : _technicianPhoneController.text.trim(),
        estimatedCost: _estimatedCostController.text.trim().isEmpty
            ? null
            : double.tryParse(_estimatedCostController.text.trim()),
        actualCost: _actualCostController.text.trim().isEmpty
            ? null
            : double.tryParse(_actualCostController.text.trim()),
        priority: _selectedPriority,
        startDate: _isEditing ? widget.workOrder!.startDate : null,
        completedDate: _isEditing ? widget.workOrder!.completedDate : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt:
            _isEditing ? widget.workOrder!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await context.read<WorkOrderProvider>().updateOrder(order);
        AppHelpers.showSnackBar(context, 'تم تعديل أمر العمل بنجاح');
      } else {
        await context.read<WorkOrderProvider>().addOrder(order);
        AppHelpers.showSnackBar(context, 'تم إضافة أمر العمل بنجاح');
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
        title: Text(_isEditing ? 'تعديل أمر العمل' : 'أمر عمل جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildStatusBadge(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section: Vehicle ──
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
                  child: Text(
                    '${v.make} ${v.model} - ${v.plateNumber}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedVehicleId = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'يرجى اختيار المركبة';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Section: Work Order Info ──
            _buildSectionTitle('تفاصيل أمر العمل'),
            const SizedBox(height: 8),

            // Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'النوع',
                prefixIcon: Icon(Icons.category),
              ),
              items: _workOrderTypes.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        _workOrderTypeIcons[entry.key] ?? Icons.build,
                        size: 18,
                        color: _workOrderTypeColors[entry.key] ??
                            AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedType = value ?? 'maintenance'),
            ),
            const SizedBox(height: 12),

            // Priority
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'الأولوية',
                prefixIcon: Icon(Icons.flag),
              ),
              items: AppConstants.priorities.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        AppHelpers.getPriorityIcon(entry.key),
                        size: 18,
                        color: AppConstants.priorityColors[entry.key] ??
                            AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedPriority = value ?? 'medium'),
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
                hintText: 'وصف تفصيلي للعمل المطلوب...',
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Technician ──
            _buildSectionTitle('بيانات الفني'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _technicianNameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفني',
                prefixIcon: Icon(Icons.person),
                hintText: 'أدخل اسم الفني',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _technicianPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم هاتف الفني',
                prefixIcon: Icon(Icons.phone),
                hintText: '01XXXXXXXXX',
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Costs ──
            _buildSectionTitle('التكاليف'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _estimatedCostController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'التكلفة التقديرية',
                      prefixIcon: Icon(Icons.calculate),
                      hintText: 'ج.م',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_isEditing)
                  Expanded(
                    child: TextFormField(
                      controller: _actualCostController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'التكلفة الفعلية',
                        prefixIcon: Icon(Icons.attach_money),
                        hintText: 'ج.م',
                      ),
                    ),
                  ),
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              if (widget.workOrder!.estimatedCost != null &&
                  widget.workOrder!.actualCost != null)
                _buildCostVarianceHint(),
            ],
            const SizedBox(height: 20),

            // ── Section: Notes ──
            _buildSectionTitle('ملاحظات'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات إضافية',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            // Attachments (only when editing an existing record)
            if (_isEditing && widget.workOrder!.id != null) ...[
              const SizedBox(height: 20),
              _buildSectionTitle('مرفقات أمر العمل'),
              const SizedBox(height: 8),
              AttachmentPickerWidget(
                entityType: 'work_order',
                entityId: widget.workOrder!.id!,
                onAttachmentsChanged: (paths) {
                  debugPrint('Work order attachments updated: ${paths.length}');
                },
                maxAttachments: 5,
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
                      _isEditing ? 'حفظ التعديلات' : 'إنشاء أمر العمل',
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

  /// Status badge shown in AppBar when editing
  Widget _buildStatusBadge() {
    final wo = widget.workOrder!;
    final statusColor = _getWorkOrderStatusColor(wo.status);
    final statusLabel = wo.statusLabel;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getWorkOrderStatusIcon(wo.status),
              size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Cost variance hint when editing
  Widget _buildCostVarianceHint() {
    final variance = widget.workOrder!.costVariance;
    if (widget.workOrder!.estimatedCost == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.workOrder!.isOverBudget
            ? AppColors.errorLight
            : AppColors.successLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            widget.workOrder!.isOverBudget
                ? Icons.trending_up
                : Icons.trending_down,
            size: 18,
            color: widget.workOrder!.isOverBudget
                ? AppColors.error
                : AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.workOrder!.isOverBudget
                  ? 'تجاوز الميزانية بـ ${variance.abs().toStringAsFixed(2)} ج.م'
                  : 'توفير ${variance.abs().toStringAsFixed(2)} ج.م',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.workOrder!.isOverBudget
                    ? AppColors.error
                    : AppColors.success,
              ),
            ),
          ),
        ],
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

  // ── Helpers ──
  static Color _getWorkOrderStatusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData _getWorkOrderStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.folder_open;
      case 'in_progress':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }
}
