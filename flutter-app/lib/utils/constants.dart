import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'KMS Fleet';
  static const String appNameAr = 'إدارة سيارات KMS';

  // Maintenance Types
  static const Map<String, String> maintenanceTypes = {
    'tires': 'إطارات',
    'electrical': 'كهرباء',
    'mechanical': 'ميكانيكا',
    'brakes': 'فرامل',
    'oil_change': 'تغيير زيت',
    'filter': 'فلتر',
    'battery': 'بطارية',
    'ac': 'تكييف',
    'transmission': 'ناقل حركة',
    'body': 'هيكل',
    'inspection': 'فحص',
    'other': 'أخرى',
  };

  static const Map<String, IconData> maintenanceTypeIcons = {
    'tires': Icons.tire_repair,
    'electrical': Icons.electrical_services,
    'mechanical': Icons.build,
    'brakes': Icons.dangerous,
    'oil_change': Icons.oil_barrel,
    'filter': Icons.filter_alt,
    'battery': Icons.battery_charging_full,
    'ac': Icons.ac_unit,
    'transmission': Icons.settings,
    'body': Icons.directions_car,
    'inspection': Icons.fact_check,
    'other': Icons.more_horiz,
  };

  static const Map<String, Color> maintenanceTypeColors = {
    'tires': AppColors.tireColor,
    'electrical': AppColors.electricalColor,
    'mechanical': AppColors.mechanicalColor,
    'brakes': AppColors.brakesColor,
    'oil_change': AppColors.oilColor,
    'filter': AppColors.filterColor,
    'battery': AppColors.batteryColor,
    'ac': AppColors.acColor,
    'transmission': AppColors.transmissionColor,
    'body': AppColors.bodyColor,
    'inspection': AppColors.inspectionColor,
    'other': AppColors.otherColor,
  };

  // Statuses
  static const Map<String, String> maintenanceStatuses = {
    'pending': 'معلقة',
    'in_progress': 'قيد التنفيذ',
    'completed': 'مكتملة',
    'cancelled': 'ملغية',
  };

  static const Map<String, Color> maintenanceStatusColors = {
    'pending': AppColors.warning,
    'in_progress': AppColors.info,
    'completed': AppColors.success,
    'cancelled': AppColors.error,
  };

  static const Map<String, IconData> maintenanceStatusIcons = {
    'pending': Icons.schedule,
    'in_progress': Icons.autorenew,
    'completed': Icons.check_circle,
    'cancelled': Icons.cancel,
  };

  // Priorities
  static const Map<String, String> priorities = {
    'low': 'منخفضة',
    'medium': 'متوسطة',
    'high': 'عالية',
    'urgent': 'عاجلة',
  };

  static const Map<String, Color> priorityColors = {
    'low': AppColors.info,
    'medium': AppColors.warning,
    'high': AppColors.accent,
    'urgent': AppColors.error,
  };

  // Vehicle Statuses
  static const Map<String, String> vehicleStatuses = {
    'active': 'نشط',
    'maintenance': 'صيانة',
    'inactive': 'غير نشط',
    'retired': 'متقاعد',
  };

  static const Map<String, Color> vehicleStatusColors = {
    'active': AppColors.success,
    'maintenance': AppColors.warning,
    'inactive': AppColors.textSecondary,
    'retired': AppColors.error,
  };

  // Fuel Types
  static const Map<String, String> fuelTypes = {
    'petrol': 'بنزين',
    'diesel': 'ديزل',
    'electric': 'كهرباء',
    'hybrid': 'هجين',
    'gas': 'غاز',
  };

  // Vehicle Colors
  static const Map<String, String> vehicleColors = {
    'white': 'أبيض',
    'black': 'أسود',
    'silver': 'فضي',
    'gray': 'رمادي',
    'red': 'أحمر',
    'blue': 'أزرق',
    'green': 'أخضر',
    'brown': 'بني',
    'gold': 'ذهبي',
    'beige': 'بيج',
  };

  // Vehicle Makes & Models
  static const List<String> vehicleMakes = [
    'تويوتا',
    'هيونداي',
    'نيسان',
    'كيا',
    'مرسيدس',
    'بي إم دبليو',
    'أودي',
    'فورد',
    'شيفروليه',
    'هوندا',
    'فولكس واجن',
    'لكزس',
    'جيب',
    'لاند روفر',
    'بيجو',
    'رينو',
    'سوزوكي',
    'ميتسوبيشي',
    'مازدا',
    'سوبارو',
    'فولفو',
    'جاكوار',
    'بنتلي',
    'بورشه',
  ];

  static const Map<String, List<String>> vehicleModels = {
    'تويوتا': ['كامري', 'كورولا', 'لاند كروزر', 'هايلكس', 'يارس', 'راف فور', 'أفالون', 'فورتشنر'],
    'هيونداي': ['إلنترا', 'توسان', 'سوناتا', 'أكسنت', 'سانتا في', 'كريتا', 'فيرنا'],
    'نيسان': ['صني', 'جوك', 'بترول', 'قشقاي', 'ألتيما', 'سنترا', 'إكس تريل'],
    'كيا': ['سيراتو', 'سبورتاج', 'أوبتيما', 'ريو', 'سورينتو', 'بيكانتو', 'كارنفال'],
    'مرسيدس': ['C-Class', 'E-Class', 'S-Class', 'GLC', 'GLE', 'A-Class', 'GLS'],
    'بي إم دبليو': ['الفئة 3', 'الفئة 5', 'الفئة 7', 'X3', 'X5', 'X7', 'الفئة 1'],
    'أودي': ['A3', 'A4', 'A6', 'Q5', 'Q7', 'A5', 'e-tron'],
    'فورد': ['فيوجن', 'إكسبلورر', 'إيكو سبورت', 'رينجر', 'موستانغ', 'إيدج', 'فورد ترانزيت', 'فورد رينجر'],
    'شيفروليه': ['لانوس', 'أوبترا', 'كروز', 'كابتيفا', 'إكوينوكس', 'ماليبو'],
    'هوندا': ['سيفيك', 'أكورد', 'CR-V', 'سيتي', 'جاز', 'HR-V', 'بيلاو'],
    'فولكس واجن': ['جولف', 'باسات', 'تيجوان', 'جيتا', 'بولو', 'أطلس'],
    'لكزس': ['ES', 'IS', 'LS', 'NX', 'RX', 'GX', 'UX'],
    'جيب': ['رانجلر', 'تشيركي', 'جراند شيروكي', 'كومباس', 'رينيغيد'],
    'لاند روفر': ['رينج روفر', 'ديسكفري', 'ديفندر', 'إيفوك', 'سبورت'],
    'بيجو': ['301', '308', '508', '2008', '3008', '5008'],
    'رينو': ['لوجان', 'سانديرو', 'داستر', 'كادجار', 'كابتشر', 'ميجان'],
    'سوزوكي': ['سويفت', 'فيتارا', 'جيمني', 'إرتيجا', 'بالينو'],
    'ميتسوبيشي': ['لانسر', 'باجيرو', 'أوتلاندر', 'ASX', 'L200'],
    'مازدا': ['مازدا 3', 'مازدا 6', 'CX-3', 'CX-5', 'CX-9', 'MX-5'],
    'سوبارو': ['إمبريزا', 'أوتباك', 'فورستر', 'XV', 'WRX'],
    'فولفو': ['S60', 'S90', 'XC40', 'XC60', 'XC90', 'V60'],
    'جاكوار': ['XE', 'XF', 'XJ', 'F-Pace', 'E-Pace'],
    'بنتلي': ['كونتيننتال GT', 'فلاينج سبور', 'بنتايجا'],
    'بورشه': ['كايين', 'ماكان', 'باناميرا', 'تايكان', '911'],
  };

  // Vehicle Types
  static const Map<String, String> vehicleTypes = {
    'half_truck': 'عربيه نص نقل (دبابه)',
    'jumbo_truck': 'عربيه نقل جامبو',
    'double_cabin': 'عربيه دبل كابينه',
    'bus': 'أتوبيسات',
    'microbus': 'ميكروباص',
    'forklift': 'كلارك',
  };

  static const Map<String, IconData> vehicleTypeIcons = {
    'half_truck': Icons.local_shipping,
    'jumbo_truck': Icons.airport_shuttle,
    'double_cabin': Icons.local_shipping,
    'bus': Icons.bus_alert,
    'microbus': Icons.directions_bus,
    'forklift': Icons.construction,
  };

  static const Map<String, Color> vehicleTypeColors = {
    'half_truck': Color(0xFF0F766E),
    'jumbo_truck': Color(0xFFEA580C),
    'double_cabin': Color(0xFF16A34A),
    'bus': Color(0xFF7C3AED),
    'microbus': Color(0xFF2563EB),
    'forklift': Color(0xFFDC2626),
  };

  // Vehicle Purpose
  static const Map<String, String> vehiclePurposes = {
    'cargo': 'نقل بضائع',
    'staff': 'نقل موظفين',
    'administrative': 'إدارية',
  };

  // Driver Status
  static const Map<String, String> driverStatuses = {
    'active': 'نشط',
    'suspended': 'موقوف',
  };

  static const Map<String, Color> driverStatusColors = {
    'active': AppColors.success,
    'suspended': AppColors.error,
  };

  // Expense Types
  static const Map<String, String> expenseTypes = {
    'fuel': 'وقود',
    'maintenance': 'صيانة',
    'toll': 'رسوم طريق',
    'violation': 'مخالفة مرورية',
    'insurance': 'تأمين',
    'miscellaneous': 'مصروفات متنوعة',
  };

  static const Map<String, IconData> expenseTypeIcons = {
    'fuel': Icons.local_gas_station,
    'maintenance': Icons.build,
    'toll': Icons.toll,
    'violation': Icons.gavel,
    'insurance': Icons.security,
    'miscellaneous': Icons.receipt_long,
  };

  static const Map<String, Color> expenseTypeColors = {
    'fuel': AppColors.primary,
    'maintenance': AppColors.warning,
    'toll': Color(0xFF6366F1),
    'violation': AppColors.error,
    'insurance': Color(0xFF0EA5E9),
    'miscellaneous': AppColors.accent,
  };

  // Violation Types
  static const Map<String, String> violationTypes = {
    'speeding': 'سرعة زائدة',
    'red_light': 'تجاوز إشارة حمراء',
    'parking': 'مخالفة وقوف',
    'no_license': 'بدون رخصة',
    'overweight': 'حمل زائد',
    'other': 'أخرى',
  };

  // Violation Status
  static const Map<String, String> violationStatuses = {
    'pending': 'معلقة',
    'paid': 'مدفوعة',
    'disputed': 'متنازع عليها',
  };

  static const Map<String, Color> violationStatusColors = {
    'pending': AppColors.warning,
    'paid': AppColors.success,
    'disputed': AppColors.info,
  };

  // Database
  static const String dbName = 'kms_fleet.db';
  static const int dbVersion = 2;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
}
