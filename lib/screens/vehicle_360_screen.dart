import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../models/vehicle.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/vehicle_3d_config.dart';

class Vehicle360Screen extends StatefulWidget {
  final Vehicle vehicle;
  const Vehicle360Screen({super.key, required this.vehicle});

  @override
  State<Vehicle360Screen> createState() => _Vehicle360ScreenState();
}

class _Vehicle360ScreenState extends State<Vehicle360Screen>
    with SingleTickerProviderStateMixin {
  bool _autoRotate = true;
  bool _showInfoPanel = true;
  bool _modelLoaded = false;
  double _panelHeight = 320;

  late final VehicleVisual visual;
  late final String modelUrl;

  @override
  void initState() {
    super.initState();
    visual = Vehicle3DConfig.getVisual(widget.vehicle.model);
    modelUrl = Vehicle3DConfig.getModelUrl(widget.vehicle.model);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    // نعتبر النموذج محمّل بعد 3 ثوانٍ كحد أقصى
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_modelLoaded) setState(() => _modelLoaded = true);
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // === الخلفية المتدرجة ===
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  visual.gradientStart.withOpacity(0.3),
                  Colors.black,
                  Colors.black,
                ],
              ),
            ),
          ),

          // === نموذج 3D ===
          Positioned.fill(
            child: ModelViewer(
              src: modelUrl,
              backgroundColor: Colors.transparent,
              autoRotate: _autoRotate,
              autoRotateDelay: 1000,
              cameraControls: true,
              cameraOrbit: '0deg 75deg 3m',
              cameraTarget: '0m 0m 0m',
              fieldOfView: '45deg',
              ar: false,
              shadowIntensity: 1.0,
              alt: '${visual.label} - ${widget.vehicle.make}',
              loading: Loading.eager,
              interactionPrompt: InteractionPrompt.auto,
              interactionPromptThreshold: 0,
            ),
          ),

          // === مؤشر التحميل ===
          if (!_modelLoaded)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(visual.color),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'جاري تحميل النموذج ثلاثي الأبعاد...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // === شريط علوي ===
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // === شريحة معلومات المركبة (يمين) ===
          Positioned(
            top: 70,
            right: 12,
            child: _buildVehicleBadge(),
          ),

          // === نقاط التحكم العائمة ===
          Positioned(
            left: 12,
            top: 100,
            child: _buildFloatingControls(),
          ),

          // === مؤشر التدوير ===
          if (!_autoRotate)
            Positioned(
              bottom: _panelHeight + 16,
              left: 0,
              right: 0,
              child: _buildRotationHint(),
            ),

          // === لوحة المعلومات السفلية ===
          _buildBottomInfoPanel(),
        ],
      ),
    );
  }

  // === الشريط العلوي ===
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 8,
        8,
        8,
      ),
      child: Row(
        children: [
          // زر الرجوع
          _CircleButton(
            onTap: () => Navigator.pop(context),
            icon: Icons.arrow_back_rounded,
          ),
          const Spacer(),
          // العنوان
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(visual.icon, color: visual.color, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'عرض ثلاثي الأبعاد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // زر إخفاء/إظهار المعلومات
          _CircleButton(
            onTap: () => setState(() => _showInfoPanel = !_showInfoPanel),
            icon: _showInfoPanel
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
        ],
      ),
    );
  }

  // === شارة المركبة ===
  Widget _buildVehicleBadge() {
    final vehicle = widget.vehicle;
    final statusColor =
        AppConstants.vehicleStatusColors[vehicle.status] ??
        AppColors.textSecondary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _showInfoPanel ? 1 : 0,
      child: IgnorePointer(
        ignoring: !_showInfoPanel,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: visual.color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                vehicle.displayName,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: visual.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: visual.color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pin_drop_rounded, color: visual.color, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        vehicle.plateNumber,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: visual.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      AppConstants.vehicleStatuses[vehicle.status] ?? '',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === أزرار التحكم العائمة ===
  Widget _buildFloatingControls() {
    return Column(
      children: [
        _FloatingButton(
          icon: _autoRotate ? Icons.sync_rounded : Icons.sync_disabled_rounded,
          label: _autoRotate ? 'دوران تلقائي' : 'توقف',
          isActive: _autoRotate,
          activeColor: visual.color,
          onTap: () => setState(() => _autoRotate = !_autoRotate),
        ),
        const SizedBox(height: 10),
        _FloatingButton(
          icon: Icons.zoom_in_rounded,
          label: 'قرّب',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('استخدم إصبعين للتكبير والتصغير'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.black87,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _FloatingButton(
          icon: Icons.center_focus_strong_rounded,
          label: 'إعادة ضبط',
          onTap: () {},
        ),
      ],
    );
  }

  // === مؤشر التدوير ===
  Widget _buildRotationHint() {
    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'اسحب للتدوير • إصبعين للتكبير',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === لوحة المعلومات السفلية ===
  Widget _buildBottomInfoPanel() {
    final vehicle = widget.vehicle;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _showInfoPanel ? 1 : 0,
        child: IgnorePointer(
          ignoring: !_showInfoPanel,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: visual.color.withOpacity(0.2), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // مقبض السحب
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: visual.color.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // شبكة المواصفات
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _SpecChip(
                            icon: Icons.speed_rounded,
                            label: 'عداد',
                            value:
                                '${AppFormatters.formatNumber(vehicle.currentOdometer)} كم',
                            color: visual.color,
                          ),
                          const SizedBox(width: 8),
                          _SpecChip(
                            icon: Icons.local_gas_station_rounded,
                            label: 'الوقود',
                            value: AppConstants.fuelTypes[vehicle.fuelType] ??
                                '',
                            color: visual.color,
                          ),
                          const SizedBox(width: 8),
                          _SpecChip(
                            icon: Icons.calendar_today_rounded,
                            label: 'السنة',
                            value: '${vehicle.year}',
                            color: visual.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _SpecChip(
                            icon: Icons.category_rounded,
                            label: 'الفئة',
                            value: AppConstants.vehicleCategories[
                                    vehicle.vehicleCategory] ??
                                '',
                            color: visual.color,
                          ),
                          const SizedBox(width: 8),
                          _SpecChip(
                            icon: Icons.palette_rounded,
                            label: 'اللون',
                            value: AppConstants.vehicleColors[vehicle.color] ??
                                '',
                            color: visual.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (vehicle.driverName != null &&
                          vehicle.driverName!.isNotEmpty)
                        Row(
                          children: [
                            _SpecChip(
                              icon: Icons.person_rounded,
                              label: 'السائق',
                              value: vehicle.driverName!,
                              color: visual.color,
                            ),
                            const SizedBox(width: 8),
                            if (vehicle.department != null)
                              _SpecChip(
                                icon: Icons.business_rounded,
                                label: 'القسم',
                                value: vehicle.department!,
                                color: visual.color,
                              ),
                          ],
                        ),
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// === زر دائري علوي ===
class _CircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _CircleButton({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// === زر عائم جانبي ===
class _FloatingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _FloatingButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: isActive
                      ? activeColor.withOpacity(0.5)
                      : Colors.white.withOpacity(0.15),
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? activeColor : Colors.white70,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor.withOpacity(0.8) : Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// === شريحة مواصفات ===
class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SpecChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, size: 13, color: color.withOpacity(0.6)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color.withOpacity(0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
