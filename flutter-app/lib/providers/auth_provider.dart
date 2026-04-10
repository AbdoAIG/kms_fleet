import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../services/database_service.dart';
import '../services/security_service.dart';
import '../services/connectivity_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _offlineMode = false;

  // ── Security state ────────────────────────────────────────────────────────
  int _remainingAttempts = 5;
  Duration _lockoutRemaining = Duration.zero;
  bool _isLockedOut = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// True when the user is signed in (Supabase) OR in offline mode.
  bool get isLoggedIn => _user != null || _offlineMode;

  /// Whether the app is running in offline mode.
  bool get isOfflineMode => _offlineMode;

  /// Remaining login attempts before lockout.
  int get remainingAttempts => _remainingAttempts;

  /// Whether the account is currently locked out.
  bool get isLockedOut => _isLockedOut;

  /// Remaining lockout duration.
  Duration get lockoutRemaining => _lockoutRemaining;

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

  /// Check current security state (lockout, attempts).
  Future<void> checkSecurityState() async {
    final lockout = await SecurityService.getRemainingLockout();
    final remaining = await SecurityService.getRemainingAttempts();

    _lockoutRemaining = lockout;
    _isLockedOut = lockout > Duration.zero;
    _remainingAttempts = remaining;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    // ── Check lockout first ───────────────────────────────────────────────
    _isLoading = true;
    _error = null;
    notifyListeners();

    final lockout = await SecurityService.getRemainingLockout();
    if (lockout > Duration.zero) {
      _isLockedOut = true;
      _lockoutRemaining = lockout;
      _isLoading = false;
      final mins = lockout.inMinutes;
      final secs = lockout.inSeconds.remainder(60);
      _error = 'الحساب مقفل. حاول بعد $mins دقيقة و${secs} ثانية';
      notifyListeners();
      return false;
    }

    _isLockedOut = false;
    _lockoutRemaining = Duration.zero;

    try {
      if (!supabaseReady) {
        // ── OFFLINE LOGIN: Validate stored credentials ────────────────────
        final hasSession = await SecurityService.hasOnlineSession();

        if (!hasSession) {
          _isLoading = false;
          _error = 'يجب تسجيل الدخول أولاً عبر الإنترنت';
          notifyListeners();
          // Record failed attempt even for offline rejection
          await _handleFailedAttempt();
          return false;
        }

        final isValid = await SecurityService.validateOfflineCredentials(email, password);

        if (!isValid) {
          _isLoading = false;
          _error = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
          notifyListeners();
          await _handleFailedAttempt();
          return false;
        }

        // Offline login successful
        _offlineMode = true;
        _isLoading = false;
        await SecurityService.resetFailedAttempts();
        _remainingAttempts = SecurityService.maxAttempts;
        ConnectivityService.onLogin();
        notifyListeners();
        return true;
      }

      // ── ONLINE LOGIN: Authenticate with Supabase ───────────────────────
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
      _offlineMode = false;

      // Store credentials securely for offline use
      await SecurityService.storeOfflineCredentials(email, password);

      // Switch DatabaseService to online mode
      await DatabaseService.goOnline();

      // Reset security counters
      await SecurityService.resetFailedAttempts();
      _remainingAttempts = SecurityService.maxAttempts;
      _isLockedOut = false;
      _lockoutRemaining = Duration.zero;

      _isLoading = false;
      ConnectivityService.onLogin();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _error = _translateError(e.message);
      notifyListeners();
      await _handleFailedAttempt();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ غير متوقع';
      notifyListeners();
      await _handleFailedAttempt();
      return false;
    }
  }

  /// Handle a failed login attempt — update counters and check lockout.
  Future<void> _handleFailedAttempt() async {
    final lockDuration = await SecurityService.recordFailedAttempt();
    _remainingAttempts = await SecurityService.getRemainingAttempts();

    if (lockDuration != null) {
      _isLockedOut = true;
      _lockoutRemaining = lockDuration;
      final mins = lockDuration.inMinutes;
      _error = 'تم قفل الحساب لمدة $mins دقيقة بسبب المحاولات الخاطئة';
    }

    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (_) {}
    _offlineMode = false;
    _user = null;
    // Switch DatabaseService back to offline mode
    DatabaseService.goOffline();
    // Clear stored offline credentials for security
    await SecurityService.clearOfflineCredentials();
    // Reset security state
    await SecurityService.resetFailedAttempts();
    _remainingAttempts = SecurityService.maxAttempts;
    _isLockedOut = false;
    _lockoutRemaining = Duration.zero;
    ConnectivityService.onLogout();
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
