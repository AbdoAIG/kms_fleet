import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _offlineMode = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// True when the user is signed in (Supabase) OR in offline mode.
  bool get isLoggedIn => _user != null || _offlineMode;

  /// Whether the app is running in offline mode.
  bool get isOfflineMode => _offlineMode;

  AuthProvider() {
    _setupAuth();
  }

  void _setupAuth() {
    try {
      // Listen for auth state changes
      supabase.auth.onAuthStateChange.listen((event) {
        _user = supabase.auth.currentUser;
        _offlineMode = false;
        if (_user != null) {
          // Switch DatabaseService to Supabase online mode
          DatabaseService.goOnline();
        }
        notifyListeners();
      });

      // Check for existing session
      _user = supabase.auth.currentUser;
      if (_user != null) {
        _offlineMode = false;
      }
    } catch (e) {
      debugPrint('Auth: Supabase not available, enabling offline mode: $e');
      _offlineMode = true;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (!supabaseReady) {
        // Offline mode: accept any login
        await Future.delayed(const Duration(milliseconds: 500));
        _offlineMode = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
      _offlineMode = false;
      // Switch DatabaseService to online mode
      await DatabaseService.goOnline();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _error = _translateError(e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ غير متوقع';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName, {String role = 'driver'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (!supabaseReady) {
        await Future.delayed(const Duration(milliseconds: 500));
        _offlineMode = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'role': role,
        },
      );
      _user = response.user;
      _offlineMode = false;
      await DatabaseService.goOnline();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _error = _translateError(e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ غير متوقع';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (_) {}
    _offlineMode = false;
    _user = null;
    // Switch DatabaseService back to offline mode
    DatabaseService.goOffline();
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (!supabaseReady) {
        _isLoading = false;
        _error = 'الإعادة متاحة فقط مع اتصال الإنترنت';
        notifyListeners();
        return;
      }
      await supabase.auth.resetPasswordForEmail(email);
      _isLoading = false;
      notifyListeners();
    } on AuthException catch (e) {
      _isLoading = false;
      _error = _translateError(e.message);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ غير متوقع';
      notifyListeners();
    }
  }

  String _translateError(String? message) {
    if (message == null) return 'حدث خطأ';
    if (message.contains('Invalid login') || message.contains('invalid_credentials'))
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    if (message.contains('User not found') || message.contains('user_not_found'))
      return 'البريد الإلكتروني غير مسجل';
    if (message.contains('Email not confirmed'))
      return 'يرجى تأكيد البريد الإلكتروني أولاً';
    if (message.contains('already registered') || message.contains('already_in_use'))
      return 'البريد الإلكتروني مستخدم بالفعل';
    if (message.contains('Password should be at least') || message.contains('weak_password'))
      return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
    if (message.contains('rate limit'))
      return 'محاولات كثيرة، حاول لاحقاً';
    return message;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
