import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _authAvailable = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// On platforms where Firebase is not initialised (Windows / Linux)
  /// we consider the user as "logged in" so the app skips the login screen.
  bool get isLoggedIn {
    if (!_authAvailable) return true;
    return _user != null;
  }

  AuthProvider() {
    // Try to connect to FirebaseAuth.
    // If Firebase Core was not initialised (desktop platforms) this will
    // throw a [MissingPluginException] or similar – we catch it and mark
    // auth as unavailable.
    try {
      _auth = FirebaseAuth.instance;
      _auth!.authStateChanges().listen((user) {
        _user = user;
        notifyListeners();
      });
      _user = _auth!.currentUser;
      _authAvailable = true;
    } catch (e) {
      _authAvailable = false;
      debugPrint('[Auth] FirebaseAuth not available – skipping login ($e)');
    }
  }

  // ── Sign in ────────────────────────────────────────────────────────────

  Future<bool> signIn(String email, String password) async {
    if (!_authAvailable) {
      _error = 'Firebase غير متاح على هذه المنصة';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth!.signInWithEmailAndPassword(
          email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
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

  // ── Sign up ────────────────────────────────────────────────────────────

  Future<bool> signUp(
      String email, String password, String displayName) async {
    if (!_authAvailable) {
      _error = 'Firebase غير متاح على هذه المنصة';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(displayName);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
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

  // ── Sign out ───────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
  }

  // ── Reset password ─────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    if (!_authAvailable) {
      _error = 'Firebase غير متاح على هذه المنصة';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth!.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _translateError(e.message);
      notifyListeners();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _translateError(String? message) {
    if (message == null) return 'حدث خطأ';
    if (message.contains('user-not-found')) return 'البريد الإلكتروني غير مسجل';
    if (message.contains('wrong-password')) return 'كلمة المرور غير صحيحة';
    if (message.contains('email-already-in-use'))
      return 'البريد الإلكتروني مستخدم بالفعل';
    if (message.contains('weak-password'))
      return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
    if (message.contains('invalid-email')) return 'البريد الإلكتروني غير صالح';
    if (message.contains('too-many-requests'))
      return 'محاولات كثيرة، حاول لاحقاً';
    return message;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
