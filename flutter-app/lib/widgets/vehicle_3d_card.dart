import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

// ═══════════════════════════════════════════════════════════════
//  VEHICLE IMAGE MAP
// ═══════════════════════════════════════════════════════════════

const _vehicleImages = {
  'half_truck': 'assets/images/vehicles/half_truck.png',
  'jumbo_truck': 'assets/images/vehicles/jumbo_truck.png',
  'double_cabin': 'assets/images/vehicles/double_cabin.png',
  'bus': 'assets/images/vehicles/bus.png',
  'microbus': 'assets/images/vehicles/microbus.png',
  'forklift': 'assets/images/vehicles/forklift.png',
};

// ═══════════════════════════════════════════════════════════════
//  VEHICLE CARD
// ═══════════════════════════════════════════════════════════════

class Vehicle3DCard extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMaintenance;

  const Vehicle3DCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onMaintenance,
  });

  @override
  State<Vehicle3DCard> createState() => _Vehicle3DCardState();
}

class _Vehicle3DCardState extends State<Vehicle3DCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _shadowAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _shadowAnim = Tween<double>(begin: 12.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  Color get _typeColor {
    if (widget.vehicle.vehicleType != null && widget.vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypeColors[widget.vehicle.vehicleType] ?? AppColors.primary;
    }
    return AppColors.primary;
  }

  String get _typeLabel {
    if (widget.vehicle.vehicleType != null && widget.vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypes[widget.vehicle.vehicleType] ?? '';
    }
    return '';
  }

  IconData get _typeIcon {
    if (widget.vehicle.vehicleType != null && widget.vehicle.vehicleType!.isNotEmpty) {
      return AppConstants.vehicleTypeIcons[widget.vehicle.vehicleType] ?? Icons.directions_car;
    }
    return Icons.directions_car;
  }

  Color get _statusColor =>
      AppConstants.vehicleStatusColors[widget.vehicle.status] ?? AppColors.textSecondary;

  String get _statusLabel =>
      AppConstants.vehicleStatuses[widget.vehicle.status] ?? '';

  String? get _vehicleImage => _vehicleImages[widget.vehicle.vehicleType];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _typeColor.withOpacity(0.15),
                  blurRadius: _shadowAnim.value,
                  offset: Offset(0, _shadowAnim.value * 0.4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: _shadowAnim.value,
                  offset: Offset(0, _shadowAnim.value * 0.2),
                ),
              ],
            ),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              elevation: _isPressed ? 2 : 6,
              child: InkWell(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // ── Vehicle Image Area ──
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _typeColor.withOpacity(0.12),
                            _typeColor.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Stack(
                        children: [
                          // Vehicle image
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: _vehicleImage != null
                                  ? Image.asset(
                                      _vehicleImage!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                                    )
                                  : _buildFallbackIcon(),
                            ),
                          ),
                          // Status badge (top-right)
                          Positioned(
                            top: 10,
                            right: 12,
                            child: _StatusBadge(
                              color: _statusColor,
                              label: _statusLabel,
                            ),
                          ),
                          // Type badge (top-left)
                          Positioned(
                            top: 10,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _typeColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _typeColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_typeIcon, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    _typeLabel,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Vehicle Info Section ──
                    _buildInfoSection(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        _typeIcon,
        size: 64,
        color: _typeColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final vehicle = widget.vehicle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle name + plate
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _typeColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vehicle.plateNumber,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _typeColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Popup menu
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, color: AppColors.textHint.withOpacity(0.6), size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      widget.onEdit?.call();
                      break;
                    case 'maintenance':
                      widget.onMaintenance?.call();
                      break;
                    case 'delete':
                      widget.onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  _PopupItem(icon: Icons.edit_outlined, label: 'تعديل', value: 'edit'),
                  _PopupItem(icon: Icons.build_outlined, label: 'صيانة', value: 'maintenance'),
                  _PopupItem(icon: Icons.delete_outline, label: 'حذف', value: 'delete', isDestructive: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick info row
          Row(
            children: [
              _QuickInfo(
                icon: Icons.speed,
                value: '${AppFormatters.formatNumber(vehicle.currentOdometer)} كم',
              ),
              const SizedBox(width: 12),
              _QuickInfo(
                icon: Icons.local_gas_station,
                value: AppConstants.fuelTypes[vehicle.fuelType] ?? '',
              ),
              const SizedBox(width: 12),
              if (vehicle.hasDriver)
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 13, color: AppColors.textHint.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vehicle.driverName ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withOpacity(0.8),
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final String value;

  const _QuickInfo({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint.withOpacity(0.7)),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary.withOpacity(0.8),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

class _PopupItem extends PopupMenuItem<String> {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _PopupItem({
    required this.icon,
    required this.label,
    required String value,
    this.isDestructive = false,
  }) : super(value: value);

  @override
  PopupMenuItemState<String, _PopupItem> createState() =>
      _PopupItemState();
}

class _PopupItemState extends PopupMenuItemState<String, _PopupItem> {
  @override
  Widget buildChild() {
    return Row(
      children: [
        Icon(
          widget.icon,
          size: 18,
          color: widget.isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            color: widget.isDestructive ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
