import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary - Teal Enterprise ──
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0A5C56);
  static const Color primaryContainer = Color(0xFFCCFBF1);

  // ── Accent - Orange ──
  static const Color accent = Color(0xFFEA580C);
  static const Color accentLight = Color(0xFFFF7A33);
  static const Color accentDark = Color(0xFFC2410C);

  // ── Surface & Background ──
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color cardShadow = Color(0x1A000000); // 10% black shadow

  // ── Text ──
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders ──
  static const Color border = Color(0xFFE2E8F0);

  // ── Status Colors ──
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ── Shadows ──
  static const Color shadowColor = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // ── Maintenance Type Colors ──
  static const Color tireColor = Color(0xFF1565C0);
  static const Color electricalColor = Color(0xFFFF8F00);
  static const Color mechanicalColor = Color(0xFF2E7D32);
  static const Color brakesColor = Color(0xFFD32F2F);
  static const Color oilColor = Color(0xFF6A1B9A);
  static const Color filterColor = Color(0xFF00838F);
  static const Color batteryColor = Color(0xFFEF6C00);
  static const Color acColor = Color(0xFF0277BD);
  static const Color transmissionColor = Color(0xFFAD1457);
  static const Color bodyColor = Color(0xFF455A64);
  static const Color inspectionColor = Color(0xFF558B2F);
  static const Color otherColor = Color(0xFF78909C);

  // ── Dark Theme Overrides ──
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF475569);
}
