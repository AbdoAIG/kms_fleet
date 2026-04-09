import 'package:flutter/material.dart';

/// إعدادات النماذج ثلاثية الأبعاد لكل نوع مركبة

class VehicleVisual {
  final String label;
  final IconData icon;
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;

  const VehicleVisual({
    required this.label,
    required this.icon,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

class Vehicle3DConfig {
  Vehicle3DConfig._();

  /// نموذج تجريبي - استبدله بنموذج مركبة حقيقي (.glb)
  static const String demoModel =
      'https://modelviewer.dev/shared-assets/models/Astronaut.glb';

  static const Map<String, String> _modelUrls = {
    'جامبو': demoModel,
    'دبابة': demoModel,
    'كلارك': demoModel,
    'أوتوبيس': demoModel,
  };

  static const Map<String, VehicleVisual> _visuals = {
    'جامبو': VehicleVisual(
      label: 'نقل جامبو',
      icon: Icons.local_shipping_rounded,
      color: Color(0xFF1565C0),
      gradientStart: Color(0xFF0D47A1),
      gradientEnd: Color(0xFF1976D2),
    ),
    'دبابة': VehicleVisual(
      label: 'عربية دبابة',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF00695C),
      gradientStart: Color(0xFF004D40),
      gradientEnd: Color(0xFF00897B),
    ),
    'كلارك': VehicleVisual(
      label: 'كلارك رافعة',
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xFFE65100),
      gradientStart: Color(0xFFBF360C),
      gradientEnd: Color(0xFFFF6D00),
    ),
    'أوتوبيس': VehicleVisual(
      label: 'أوتوبيس ركاب',
      icon: Icons.directions_bus_rounded,
      color: Color(0xFF6A1B9A),
      gradientStart: Color(0xFF4A148C),
      gradientEnd: Color(0xFF8E24AA),
    ),
  };

  static String getModelUrl(String? model) {
    return _modelUrls[model] ?? demoModel;
  }

  static VehicleVisual getVisual(String? model) {
    return _visuals[model] ?? _visuals['جامبو']!;
  }
}
