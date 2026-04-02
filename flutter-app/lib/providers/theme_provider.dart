import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDark = false;
  bool _isLoading = true;

  bool get isDark => _isDark;
  bool get isLoading => _isLoading;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_themeKey) ?? false;
    } catch (_) {
      _isDark = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDark);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setTheme(bool dark) async {
    _isDark = dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, dark);
    } catch (_) {}
    notifyListeners();
  }
}
