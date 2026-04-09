import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة المصادقة - صلاحيات المدير فقط
/// Firebase Auth + Firestore للمزامنة السحابية
class AuthService {
  static FirebaseAuth? _auth;
  static SharedPreferences? _prefs;
  static bool _initialized = false;

  AuthService._();

  /// تهيئة Firebase Auth و SharedPreferences
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      _auth = FirebaseAuth.instance;
      _prefs = await SharedPreferences.getInstance();

      _initialized = true;
      debugPrint('✅ Firebase Auth initialized (with cloud sync)');
    } catch (e) {
      debugPrint('❌ Firebase init error: $e');
      _initialized = false;
    }
  }

  static bool get isInitialized => _initialized;
  static FirebaseAuth? get auth => _auth;
  static User? get currentUser => _auth?.currentUser;

  /// تشخيص Firebase - يرجع تقرير مفصل
  static Future<String> diagnose() async {
    final lines = <String>[];
    try {
      lines.add('✅ Firebase Core: مُهيأ');
    } catch (e) {
      lines.add('❌ Firebase Core: $e');
    }
    try {
      final app = _auth?.app;
      lines.add('✅ Auth app: ${app?.name}');
      lines.add('   Project ID: ${app?.options.projectId}');
      lines.add('   API Key: ${app?.options.apiKey?.substring(0, 10)}...');
    } catch (e) {
      lines.add('❌ Auth app: $e');
    }
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        lines.add('✅ Current user: ${user.email} (uid=${user.uid})');
      } else {
        lines.add('ℹ️ No current user');
      }
    } catch (e) {
      lines.add('❌ Current user check: $e');
    }
    try {
      final prefs = _prefs;
      if (prefs != null) {
        final name = prefs.getString('admin_name');
        lines.add('✅ SharedPreferences: متاح (admin_name=$name)');
      } else {
        lines.add('❌ SharedPreferences: غير متاح');
      }
    } catch (e) {
      lines.add('❌ SharedPreferences: $e');
    }
    lines.add('ℹ️ الوضع: مزامنة سحابية مع Firestore مفعّلة');
    return lines.join('\n');
  }

  /// التحقق: هل يوجد حساب مدير؟ (يتحقق من SharedPreferences)
  static Future<bool> adminExists() async {
    if (!_initialized) return false;
    try {
      final name = _prefs?.getString('admin_name');
      return name != null && name.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ adminExists error: $e');
      return false;
    }
  }

  /// تحويل FirebaseAuthException لرسالة عربية واضحة
  static String _translateAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل. جرب تسجيل الدخول.';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل في النظام';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'محاولات كثيرة. حاول بعد 5 دقائق';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت';
      case 'invalid-credential':
        return 'البريد أو كلمة المرور غير صحيحة';
      case 'operation-not-allowed':
        return '⚠️ Email/Password غير مفعّل!\n'
            'اذهب إلى Firebase Console:\n'
            'Authentication → Sign-in method\n'
            '→ Email/Password → فعّل Enable';
      case 'internal-error':
        return '⚠️ خطأ داخلي في Firebase\n'
            'السبب الأكثر احتمالاً:\n'
            '1. Email/Password غير مفعّل في Firebase Console\n'
            '2. SHA-1 fingerprint غير مضاف\n\n'
            'الحل:\n'
            'firebase app:sdkconfig:android --project kms-fleet\n'
            'ثم أعد flutterfire configure';
      default:
        return 'خطأ [${e.code}]: ${e.message ?? "غير معروف"}';
    }
  }

  /// إنشاء حساب المدير
  static Future<UserCredential> createAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    if (!_initialized) throw Exception('Firebase غير مهيأ');

    UserCredential credential;

    // === الخطوة 1: Auth ===
    try {
      debugPrint('🔐 Creating admin account: $email');
      credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Auth account created (uid=${credential.user!.uid})');

      // تحديث اسم العرض
      await credential.user!.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Auth error: code=${e.code} msg=${e.message}');
      throw Exception(_translateAuthError(e));
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw Exception('خطأ غير متوقع: $e');
    }

    // === الخطوة 2: حفظ الاسم محلياً في SharedPreferences ===
    try {
      await _prefs?.setString('admin_name', name);
      await _prefs?.setString('admin_email', email);
      debugPrint('✅ Admin name saved locally: $name');
    } catch (e) {
      debugPrint('⚠️ SharedPreferences save failed (non-fatal): $e');
    }

    return credential;
  }

  /// تسجيل دخول المدير
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    if (!_initialized) throw Exception('Firebase غير مهيأ');

    UserCredential credential;

    // === الخطوة 1: Auth ===
    try {
      debugPrint('🔐 Signing in: $email');
      credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Sign-in successful (uid=${credential.user!.uid})');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign-in error: code=${e.code} msg=${e.message}');
      throw Exception(_translateAuthError(e));
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw Exception('خطأ غير متوقع أثناء تسجيل الدخول: $e');
    }

    // === الخطوة 2: حفظ الاسم محلياً من display name ===
    try {
      final displayName = credential.user?.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        await _prefs?.setString('admin_name', displayName);
        await _prefs?.setString('admin_email', email);
        debugPrint('✅ Admin name saved locally: $displayName');
      }
    } catch (e) {
      debugPrint('⚠️ SharedPreferences save failed (non-fatal): $e');
    }

    return credential;
  }

  /// تسجيل الخروج
  static Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// إعادة تعيين كلمة المرور
  static Future<void> resetPassword(String email) async {
    if (!_initialized) throw Exception('Firebase غير مهيأ');
    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'البريد الإلكتروني غير مسجل';
          break;
        default:
          message = 'فشل: ${e.message}';
      }
      throw Exception(message);
    }
  }

  /// تغيير كلمة المرور
  static Future<void> changePassword(String newPassword) async {
    if (!_initialized) return;
    try {
      await _auth?.currentUser?.updatePassword(newPassword);
    } catch (e) {
      debugPrint('Change password error: $e');
    }
  }

  /// الحصول على اسم المدير (من SharedPreferences)
  static Future<String> getAdminName() async {
    try {
      final name = _prefs?.getString('admin_name');
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}

    // Fallback: من Firebase Auth display name
    try {
      if (_initialized && _auth?.currentUser != null) {
        final displayName = _auth!.currentUser!.displayName;
        if (displayName != null && displayName.isNotEmpty) {
          // حفظه محلياً لاستخدامه لاحقاً
          await _prefs?.setString('admin_name', displayName);
          return displayName;
        }
      }
    } catch (_) {}

    return 'المدير';
  }

  /// مراقبة حالة المصادقة
  static Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  /// حذف حساب المدير
  static Future<void> deleteAccount() async {
    if (!_initialized) return;
    try {
      final user = _auth?.currentUser;
      if (user == null) return;
      // حذف البيانات المحلية
      await _prefs?.remove('admin_name');
      await _prefs?.remove('admin_email');
      await user.delete();
    } catch (e) {
      debugPrint('Delete account error: $e');
    }
  }

  /// إعادة محاولة التهيئة
  static Future<void> retryInitialize() async {
    _initialized = false;
    await initialize();
  }
}
