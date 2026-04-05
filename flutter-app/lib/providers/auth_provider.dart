import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
    _user = _auth.currentUser;
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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

  Future<bool> signUp(String email, String password, String displayName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
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

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _translateError(e.message);
      notifyListeners();
    }
  }

  String _translateError(String? message) {
    if (message == null) return 'حدث خطأ';
    if (message.contains('user-not-found')) return 'البريد الإلكتروني غير مسجل';
    if (message.contains('wrong-password')) return 'كلمة المرور غير صحيحة';
    if (message.contains('email-already-in-use')) return 'البريد الإلكتروني مستخدم بالفعل';
    if (message.contains('weak-password')) return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
    if (message.contains('invalid-email')) return 'البريد الإلكتروني غير صالح';
    if (message.contains('too-many-requests')) return 'محاولات كثيرة، حاول لاحقاً';
    return message;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
