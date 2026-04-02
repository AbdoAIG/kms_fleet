import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'KMS Fleet';
  static const String appNameAr = 'نظام إدارة الأسطول';

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
    'لكزس',
    'جاكوار',
    'بنتلي',
    'بورشه',
    'لكزس',
  ];

  static const Map<String, List<String>> vehicleModels = {
    'تويوتا': ['كامري', 'كورولا', 'لاند كروزر', 'هايلكس', 'يارس', 'راف فور', 'أفالون', 'فورتشنر'],
    'هيونداي': ['إلنترا', 'توسان', 'سوناتا', 'أكسنت', 'سانتا في', 'كريتا', 'فيرنا'],
    'نيسان': ['صني', 'جوك', 'بترول', 'قشقاي', 'ألتيما', 'سنترا', 'إكس تريل'],
    'كيا': ['سيراتو', 'سبورتاج', 'أوبتيما', 'ريو', 'سورينتو', 'بيكانتو', 'كارنفال'],
    'مرسيدس': ['C-Class', 'E-Class', 'S-Class', 'GLC', 'GLE', 'A-Class', 'GLS'],
    'بي إم دبليو': ['الفئة 3', 'الفئة 5', 'الفئة 7', 'X3', 'X5', 'X7', 'الفئة 1'],
    'أودي': ['A3', 'A4', 'A6', 'Q5', 'Q7', 'A5', 'e-tron'],
    'فورد': ['فيوجن', 'إكسبلورر', 'إيكو سبورت', 'رينجر', 'موستانغ', 'إيدج'],
    'شيفروليه': ['لانوس', 'أوبترا', 'كروز', 'كابتيفا', 'إكوينوكس', 'ماليبو'],
    'هوندا': ['سيفيك', 'أكورد', 'CR-V', 'سيتي', 'جاز', 'HR-V', 'بيلاو'],
    'فولكس واجن': ['جولف', 'باسات', 'تيجوان', 'جيتا', 'بولو', 'أطلس'],
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
