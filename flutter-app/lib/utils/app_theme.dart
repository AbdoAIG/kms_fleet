import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0.5,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border, width: 0.5),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          hintStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textHint,
          ),
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.primaryContainer,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 1,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textOnPrimary,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimary,
          secondary: AppColors.accent,
          error: AppColors.error,
          surface: AppColors.surface,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF334155),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          hintStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: Colors.white.withOpacity(0.4),
          ),
          labelStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: Colors.white.withOpacity(0.4),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryLight,
          onPrimary: AppColors.textOnPrimary,
          secondary: AppColors.accentLight,
          error: AppColors.error,
          surface: Color(0xFF1E293B),
        ),
      );
}
