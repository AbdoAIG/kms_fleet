import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Expense type constants for cost tracking module
class AppConstants {
  AppConstants._();

  // Expense Types
  static const Map<String, String> expenseTypes = {
    'fuel': 'وقود',
    'maintenance': 'صيانة',
    'toll': 'رسوم طريق',
    'fine': 'مخالفة مرورية',
    'insurance': 'تأمين مركبة',
    'miscellaneous': 'مصروفات أخرى',
  };

  static const Map<String, IconData> expenseTypeIcons = {
    'fuel': Icons.local_gas_station,
    'maintenance': Icons.build,
    'toll': Icons.toll,
    'fine': Icons.gavel,
    'insurance': Icons.security,
    'miscellaneous': Icons.receipt_long,
  };

  static const Map<String, Color> expenseTypeColors = {
    'fuel': AppColors.primary,
    'maintenance': AppColors.accent,
    'toll': AppColors.info,
    'fine': AppColors.error,
    'insurance': AppColors.success,
    'miscellaneous': AppColors.textSecondary,
  };
}
