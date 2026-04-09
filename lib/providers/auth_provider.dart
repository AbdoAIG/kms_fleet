import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// مزوّد حالة المصادقة - يتحقق من تسجيل الدخول
class AuthProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String _errorMessage = '';
  String _adminName = '';
  bool _firebaseReady = false;
  bool _offlineMode = false;

  StreamSubscription? _authSubscription;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String get errorMessage => _errorMessage;
  String get adminName => _adminName;
  bool get firebaseReady => _firebaseReady;
  bool get offlineMode => _offlineMode;

  /// [firebaseReady] يمرر من main.dart بعد محاولة تهيئة Firebase
  AuthProvider({bool firebaseReady = false}) : _firebaseReady = firebaseReady {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (_firebaseReady) {
        // Firebase تم تهيئته بنجاح
        await AuthService.initialize();
        _firebaseReady = AuthService.isInitialized;

        if (_firebaseReady) {
          _authSubscription = AuthService.authStateChanges.listen(_onAuthStateChanged);
        } else {
          _offlineMode = true;
          _isAuthenticated = true;
          _adminName = 'المدير (أوفلاين)';
          _isLoading = false;
          notifyListeners();
        }
      } else {
        // Firebase غير متاح - وضع أوفلاين مباشر
        _offlineMode = true;
        _isAuthenticated = true;
        _adminName = 'المدير (أوفلاين)';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider init error: $e');
      _offlineMode = true;
      _isAuthenticated = true;
      _adminName = 'المدير (أوفلاين)';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onAuthStateChanged(dynamic user) {
    if (user != null) {
      _isAuthenticated = true;
      _errorMessage = '';
      _offlineMode = false;
      _loadAdminName();
    } else {
      _isAuthenticated = false;
      _adminName = '';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAdminName() async {
    try {
      _adminName = await AuthService.getAdminName();
    } catch (_) {
      _adminName = 'المدير';
    }
    notifyListeners();
  }

  /// إنشاء حساب المدير (مرة واحدة)
  Future<bool> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await AuthService.createAdmin(
        name: name,
        email: email,
        password: password,
      );
      _isAuthenticated = true;
      _adminName = name;
      _errorMessage = '';
      _offlineMode = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تسجيل الدخول
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await AuthService.signIn(email: email, password: password);
      _isAuthenticated = true;
      _errorMessage = '';
      _offlineMode = false;
      await _loadAdminName();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.signOut();
      _isAuthenticated = false;
      _adminName = '';
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email) async {
    try {
      await AuthService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  /// التحقق: هل يوجد حساب مدير؟
  Future<bool> checkAdminExists() async {
    if (!_firebaseReady) return false;
    try {
      return await AuthService.adminExists();
    } catch (_) {
      return false;
    }
  }

  /// الدخول في الوضع الأوفلاين (بدون Firebase)
  void enterOfflineMode() {
    _offlineMode = true;
    _isAuthenticated = true;
    _adminName = 'المدير (أوفلاين)';
    _isLoading = false;
    _errorMessage = '';
    notifyListeners();
  }

  /// إعادة المحاولة
  Future<void> retry() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
    _offlineMode = false;
    _isAuthenticated = false;
    await _init();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
