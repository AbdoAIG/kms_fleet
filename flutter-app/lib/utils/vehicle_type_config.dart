import 'package:flutter/material.dart';
import 'app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// VehicleTypeConfig — Per-type visual identity, inspection checkpoints,
// capacity labels, and diagram drawing configs for each vehicle category.
// ═══════════════════════════════════════════════════════════════════════════════

class VehicleTypeConfig {
  final String typeKey;
  final String label;
  final String shortLabel;
  final IconData icon;
  final IconData detailIcon;
  final Color color;
  final Color lightColor;
  final String capacityLabel;
  final String Function(Map<String, dynamic>) capacityValue;
  final List<InspectionPoint> inspectionPoints;
  final String description;

  const VehicleTypeConfig({
    required this.typeKey,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.detailIcon,
    required this.color,
    required this.lightColor,
    required this.capacityLabel,
    required this.capacityValue,
    required this.inspectionPoints,
    required this.description,
  });
}

class InspectionPoint {
  final String id;
  final String label;
  final String? maintenanceType; // maps to maintenance type key
  final IconData icon;
  final Color color;

  const InspectionPoint({
    required this.id,
    required this.label,
    this.maintenanceType,
    required this.icon,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIGS
// ═══════════════════════════════════════════════════════════════════════════════

const halfTruckConfig = VehicleTypeConfig(
  typeKey: 'half_truck',
  label: 'عربيه نص نقل (دبابه)',
  shortLabel: 'نص نقل',
  icon: Icons.local_shipping,
  detailIcon: Icons.local_shipping,
  color: Color(0xFF0F766E),
  lightColor: Color(0xE0F2FE),
  capacityLabel: 'سعة التحميل',
  capacityValue: _truckCapacity,
  description: 'شاحنة نقل خفيفة لنقل البضائع والمواد',
  inspectionPoints: [
    InspectionPoint(id: 'engine', label: 'المحرك', maintenanceType: 'mechanical', icon: Icons.settings, color: AppColors.mechanicalColor),
    InspectionPoint(id: 'brakes', label: 'الفرامل', maintenanceType: 'brakes', icon: Icons.dangerous, color: AppColors.brakesColor),
    InspectionPoint(id: 'tires_f', label: 'إطارات أمامية', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'tires_r', label: 'إطارات خلفية', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'oil', label: 'الزيت', maintenanceType: 'oil_change', icon: Icons.oil_barrel, color: AppColors.oilColor),
    InspectionPoint(id: 'battery', label: 'البطارية', maintenanceType: 'battery', icon: Icons.battery_charging_full, color: AppColors.batteryColor),
    InspectionPoint(id: 'electrical', label: 'الكهرباء', maintenanceType: 'electrical', icon: Icons.electrical_services, color: AppColors.electricalColor),
    InspectionPoint(id: 'cargo', label: 'صندوق التحميل', maintenanceType: 'body', icon: Icons.inventory_2, color: AppColors.bodyColor),
    InspectionPoint(id: 'suspension', label: 'المساعدين', maintenanceType: 'mechanical', icon: Icons.car_repair, color: AppColors.mechanicalColor),
    InspectionPoint(id: 'ac', label: 'التكييف', maintenanceType: 'ac', icon: Icons.ac_unit, color: AppColors.acColor),
  ],
);

const jumboTruckConfig = VehicleTypeConfig(
  typeKey: 'jumbo_truck',
  label: 'عربيه نقل جامبو',
  shortLabel: 'جامبو',
  icon: Icons.airport_shuttle,
  detailIcon: Icons.airport_shuttle,
  color: Color(0xFFEA580C),
  lightColor: Color(0xFFFFF7ED),
  capacityLabel: 'سعة التحميل',
  capacityValue: _truckCapacity,
  description: 'شاحنة نقل جامبو لنقل البضائع الثقيلة',
  inspectionPoints: [
    InspectionPoint(id: 'engine', label: 'المحرك', maintenanceType: 'mechanical', icon: Icons.settings, color: AppColors.mechanicalColor),
    InspectionPoint(id: 'transmission', label: 'ناقل الحركة', maintenanceType: 'transmission', icon: Icons.settings, color: AppColors.transmissionColor),
    InspectionPoint(id: 'brakes', label: 'الفرامل', maintenanceType: 'brakes', icon: Icons.dangerous, color: AppColors.brakesColor),
    InspectionPoint(id: 'tires_f', label: 'إطارات أمامية', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'tires_r', label: 'إطارات خلفية', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'tires_s', label: 'إطارات مساعدة', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'oil', label: 'الزيت', maintenanceType: 'oil_change', icon: Icons.oil_barrel, color: AppColors.oilColor),
    InspectionPoint(id: 'filter', label: 'الفلاتر', maintenanceType: 'filter', icon: Icons.filter_alt, color: AppColors.filterColor),
    InspectionPoint(id: 'battery', label: 'البطارية', maintenanceType: 'battery', icon: Icons.battery_charging_full, color: AppColors.batteryColor),
    InspectionPoint(id: 'electrical', label: 'الكهرباء', maintenanceType: 'electrical', icon: Icons.electrical_services, color: AppColors.electricalColor),
    InspectionPoint(id: 'cargo', label: 'الصندوق', maintenanceType: 'body', icon: Icons.inventory_2, color: AppColors.bodyColor),
    InspectionPoint(id: 'ac', label: 'التكييف', maintenanceType: 'ac', icon: Icons.ac_unit, color: AppColors.acColor),
  ],
);

const doubleCabinConfig = VehicleTypeConfig(
  typeKey: 'double_cabin',
  label: 'عربيه دبل كابينه',
  shortLabel: 'دبل كابينه',
  icon: Icons.local_shipping,
  detailIcon: Icons.local_shipping,
  color: Color(0xFF16A34A),
  lightColor: Color(0xFFF0FDF4),
  capacityLabel: 'عدد الركاب',
  capacityValue: _passengerCapacity,
  description: 'عربية دبل كابينة للنقل والمهام المتعددة',
  inspectionPoints: [
    InspectionPoint(id: 'engine', label: 'المحرك', maintenanceType: 'mechanical', icon: Icons.settings, color: AppColors.mechanicalColor),
    InspectionPoint(id: 'brakes', label: 'الفرامل', maintenanceType: 'brakes', icon: Icons.dangerous, color: AppColors.brakesColor),
    InspectionPoint(id: 'tires', label: 'الإطارات', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'oil', label: 'الزيت', maintenanceType: 'oil_change', icon: Icons.oil_barrel, color: AppColors.oilColor),
    InspectionPoint(id: 'battery', label: 'البطارية', maintenanceType: 'battery', icon: Icons.battery_charging_full, color: AppColors.batteryColor),
    InspectionPoint(id: 'electrical', label: 'الكهرباء', maintenanceType: 'electrical', icon: Icons.electrical_services, color: AppColors.electricalColor),
    InspectionPoint(id: 'ac', label: 'التكييف', maintenanceType: 'ac', icon: Icons.ac_unit, color: AppColors.acColor),
    InspectionPoint(id: 'body', label: 'الهيكل', maintenanceType: 'body', icon: Icons.directions_car, color: AppColors.bodyColor),
    InspectionPoint(id: 'filter', label: 'الفلاتر', maintenanceType: 'filter', icon: Icons.filter_alt, color: AppColors.filterColor),
  ],
);

const busConfig = VehicleTypeConfig(
  typeKey: 'bus',
  label: 'أتوبيسات',
  shortLabel: 'أتوبيس',
  icon: Icons.bus_alert,
  detailIcon: Icons.bus_alert,
  color: Color(0xFF7C3AED),
  lightColor: Color(0xFFF5F3FF),
  capacityLabel: 'عدد الركاب',
  capacityValue: _passengerCapacity,
  description: 'أتوبيس نقل الركاب والعمال',
  inspectionPoints: [
    InspectionPoint(id: 'engine', label: 'المحرك', maintenanceType: 'mechanical', icon: Icons.settings, color: AppColors.mechanicalColor),
    InspectionPoint(id: 'transmission', label: 'ناقل الحركة', maintenanceType: 'transmission', icon: Icons.settings, color: AppColors.transmissionColor),
    InspectionPoint(id: 'brakes', label: 'الفرامل', maintenanceType: 'brakes', icon: Icons.dangerous, color: AppColors.brakesColor),
    InspectionPoint(id: 'tires_f', label: 'إطارات أمامية', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'tires_r', label: 'إطارات خلفية', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'oil', label: 'الزيت', maintenanceType: 'oil_change', icon: Icons.oil_barrel, color: AppColors.oilColor),
    InspectionPoint(id: 'battery', label: 'البطارية', maintenanceType: 'battery', icon: Icons.battery_charging_full, color: AppColors.batteryColor),
    InspectionPoint(id: 'electrical', label: 'الكهرباء', maintenanceType: 'electrical', icon: Icons.electrical_services, color: AppColors.electricalColor),
    InspectionPoint(id: 'ac', label: 'التكييف', maintenanceType: 'ac', icon: Icons.ac_unit, color: AppColors.acColor),
    InspectionPoint(id: 'seats', label: 'المقاعد', maintenanceType: 'body', icon: Icons.airline_seat_recline_normal, color: AppColors.bodyColor),
    InspectionPoint(id: 'doors', label: 'الأبواب', maintenanceType: 'mechanical', icon: Icons.meeting_room, color: AppColors.mechanicalColor),
    InspectionPoint(id: 'filter', label: 'الفلاتر', maintenanceType: 'filter', icon: Icons.filter_alt, color: AppColors.filterColor),
  ],
);

const microbusConfig = VehicleTypeConfig(
  typeKey: 'microbus',
  label: 'ميكروباص',
  shortLabel: 'ميكروباص',
  icon: Icons.directions_bus,
  detailIcon: Icons.directions_bus,
  color: Color(0xFF2563EB),
  lightColor: Color(0xFFEFF6FF),
  capacityLabel: 'عدد الركاب',
  capacityValue: _passengerCapacity,
  description: 'ميكروباص لنقل الركاب والموظفين',
  inspectionPoints: [
    InspectionPoint(id: 'engine', label: 'المحرك', maintenanceType: 'mechanical', icon: Icons.settings, color: AppColors.mechanicalColor),
    InspectionPoint(id: 'brakes', label: 'الفرامل', maintenanceType: 'brakes', icon: Icons.dangerous, color: AppColors.brakesColor),
    InspectionPoint(id: 'tires', label: 'الإطارات', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'oil', label: 'الزيت', maintenanceType: 'oil_change', icon: Icons.oil_barrel, color: AppColors.oilColor),
    InspectionPoint(id: 'battery', label: 'البطارية', maintenanceType: 'battery', icon: Icons.battery_charging_full, color: AppColors.batteryColor),
    InspectionPoint(id: 'electrical', label: 'الكهرباء', maintenanceType: 'electrical', icon: Icons.electrical_services, color: AppColors.electricalColor),
    InspectionPoint(id: 'ac', label: 'التكييف', maintenanceType: 'ac', icon: Icons.ac_unit, color: AppColors.acColor),
    InspectionPoint(id: 'seats', label: 'المقاعد', maintenanceType: 'body', icon: Icons.airline_seat_recline_normal, color: AppColors.bodyColor),
    InspectionPoint(id: 'body', label: 'الهيكل', maintenanceType: 'body', icon: Icons.directions_car, color: AppColors.bodyColor),
  ],
);

const forkliftConfig = VehicleTypeConfig(
  typeKey: 'forklift',
  label: 'كلارك (رافعة شوكية)',
  shortLabel: 'كلارك',
  icon: Icons.construction,
  detailIcon: Icons.construction,
  color: Color(0xFFDC2626),
  lightColor: Color(0xFFFEF2F2),
  capacityLabel: 'سعة الرفع',
  capacityValue: _forkliftCapacity,
  description: 'رافعة شوكية لرفع ونقل البضائع',
  inspectionPoints: [
    InspectionPoint(id: 'engine', label: 'المحرك', maintenanceType: 'mechanical', icon: Icons.settings, color: AppColors.mechanicalColor),
    InspectionPoint(id: 'hydraulics', label: 'الهايدروليك', maintenanceType: 'mechanical', icon: Icons.water_drop, color: AppColors.mechanicalColor),
    InspectionPoint(id: 'forks', label: 'الشوكات', maintenanceType: 'body', icon: Icons.agriculture, color: AppColors.bodyColor),
    InspectionPoint(id: 'tires_f', label: 'إطارات أمامية', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'tires_r', label: 'إطارات خلفية', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
    InspectionPoint(id: 'battery', label: 'البطارية', maintenanceType: 'battery', icon: Icons.battery_charging_full, color: AppColors.batteryColor),
    InspectionPoint(id: 'electrical', label: 'الكهرباء', maintenanceType: 'electrical', icon: Icons.electrical_services, color: AppColors.electricalColor),
    InspectionPoint(id: 'oil', label: 'الزيت', maintenanceType: 'oil_change', icon: Icons.oil_barrel, color: AppColors.oilColor),
    InspectionPoint(id: 'safety', label: 'أنظمة الأمان', maintenanceType: 'inspection', icon: Icons.warning, color: AppColors.inspectionColor),
    InspectionPoint(id: 'mast', label: 'العمود', maintenanceType: 'mechanical', icon: Icons.view_column, color: AppColors.mechanicalColor),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

String _truckCapacity(Map<String, dynamic> data) {
  final tons = data['cargo_capacity_tons'];
  if (tons != null && tons > 0) return '${tons} طن';
  return 'غير محدد';
}

String _passengerCapacity(Map<String, dynamic> data) {
  final seats = data['passenger_capacity'];
  if (seats != null && seats > 0) return '$seats راكب';
  return 'غير محدد';
}

String _forkliftCapacity(Map<String, dynamic> data) {
  final tons = data['cargo_capacity_tons'];
  if (tons != null && tons > 0) return '${tons} طن';
  return 'غير محدد';
}

// ═══════════════════════════════════════════════════════════════════════════════
// REGISTRY
// ═══════════════════════════════════════════════════════════════════════════════

const Map<String, VehicleTypeConfig> vehicleTypeConfigs = {
  'half_truck': halfTruckConfig,
  'jumbo_truck': jumboTruckConfig,
  'double_cabin': doubleCabinConfig,
  'bus': busConfig,
  'microbus': microbusConfig,
  'forklift': forkliftConfig,
};

/// Get config for a vehicle type, or fallback default.
VehicleTypeConfig getVehicleTypeConfig(String? type) {
  if (type != null && vehicleTypeConfigs.containsKey(type)) {
    return vehicleTypeConfigs[type]!;
  }
  // Fallback generic config
  return const VehicleTypeConfig(
    typeKey: 'generic',
    label: 'سيارة',
    shortLabel: 'سيارة',
    icon: Icons.directions_car,
    detailIcon: Icons.directions_car,
    color: AppColors.primary,
    lightColor: AppColors.primaryContainer,
    capacityLabel: 'السعة',
    capacityValue: _truckCapacity,
    description: 'سيارة عامة',
    inspectionPoints: [
      InspectionPoint(id: 'engine', label: 'المحرك', maintenanceType: 'mechanical', icon: Icons.settings, color: AppColors.mechanicalColor),
      InspectionPoint(id: 'brakes', label: 'الفرامل', maintenanceType: 'brakes', icon: Icons.dangerous, color: AppColors.brakesColor),
      InspectionPoint(id: 'tires', label: 'الإطارات', maintenanceType: 'tires', icon: Icons.tire_repair, color: AppColors.tireColor),
      InspectionPoint(id: 'oil', label: 'الزيت', maintenanceType: 'oil_change', icon: Icons.oil_barrel, color: AppColors.oilColor),
      InspectionPoint(id: 'battery', label: 'البطارية', maintenanceType: 'battery', icon: Icons.battery_charging_full, color: AppColors.batteryColor),
      InspectionPoint(id: 'electrical', label: 'الكهرباء', maintenanceType: 'electrical', icon: Icons.electrical_services, color: AppColors.electricalColor),
      InspectionPoint(id: 'ac', label: 'التكييف', maintenanceType: 'ac', icon: Icons.ac_unit, color: AppColors.acColor),
      InspectionPoint(id: 'body', label: 'الهيكل', maintenanceType: 'body', icon: Icons.directions_car, color: AppColors.bodyColor),
    ],
  );
}
