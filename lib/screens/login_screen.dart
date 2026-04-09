import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;
  bool _showCreateMode = false; // false = login, true = create
  bool _checkingFirebase = true;
  String _diagnosticInfo = '';
  bool _authReady = false;

  @override
  void initState() {
    super.initState();
    _checkFirebase();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkFirebase() async {
    final authProvider = context.read<AuthProvider>();
    _authReady = authProvider.firebaseReady;

    if (_authReady) {
      try {
        final info = await AuthService.diagnose();
        if (mounted) {
          setState(() {
            _diagnosticInfo = info;
            _checkingFirebase = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _checkingFirebase = false);
      }
    } else {
      if (mounted) setState(() => _checkingFirebase = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_showCreateMode) {
      // إنشاء حساب جديد
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _showErrorSnackBar('أدخل اسم المدير');
        return;
      }

      final success = await authProvider.createAdmin(
        name: name,
        email: email,
        password: password,
      );
      if (mounted && !success) {
        final msg = authProvider.errorMessage;
        if (msg.contains('مستخدم بالفعل') || msg.contains('already in use')) {
          // الحساب موجود → حاول تسجيل الدخول مباشرة
          _showErrorSnackBar('الحساب موجود بالفعل! جاري تسجيل الدخول...');
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            final loginSuccess = await authProvider.signIn(email: email, password: password);
            if (mounted && !loginSuccess) {
              _showErrorSnackBar(authProvider.errorMessage);
            }
          }
        } else {
          _showErrorSnackBar(msg);
        }
      }
    } else {
      // تسجيل الدخول
      final success = await authProvider.signIn(
        email: email,
        password: password,
      );
      if (mounted && !success) {
        _showErrorSnackBar(authProvider.errorMessage);
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('أدخل البريد الإلكتروني أولاً');
      return;
    }
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(_emailController.text.trim());
    if (mounted) {
      if (success) {
        _showSuccessSnackBar('تم إرسال رابط إعادة تعيين كلمة المرور');
      } else {
        _showErrorSnackBar(authProvider.errorMessage);
      }
    }
  }

  void _enterOffline() {
    context.read<AuthProvider>().enterOfflineMode();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDiagnosticDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تشخيص Firebase'),
        content: SingleChildScrollView(
          child: SelectableText(
            _diagnosticInfo.isEmpty ? 'جاري التشخيص...' : _diagnosticInfo,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.6),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading || _checkingFirebase) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car, color: Colors.white, size: 64),
                  const SizedBox(height: 20),
                  const Text('KMS Fleet',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(color: Colors.white70),
                ],
              ),
            ),
          );
        }

        if (authProvider.offlineMode) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.white70, size: 64),
                    const SizedBox(height: 16),
                    const Text('الوضع الأوفلاين',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text('البيانات محفوظة محلياً فقط',
                        style: TextStyle(fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _enterOffline,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('متابعة إلى التطبيق'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_authReady)
                      TextButton(
                        onPressed: () {
                          authProvider.retry();
                          _checkFirebase();
                        },
                        child: const Text('إعادة محاولة الاتصال بـ Firebase',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        // === شاشة تسجيل الدخول ===
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // الشعار
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text('KMS Fleet',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text('نظام إدارة أسطول المركبات',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 24),

                    // بطاقة الدخول
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // عنوان متغير
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(_showCreateMode ? Icons.person_add : Icons.shield,
                                      size: 20, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _showCreateMode ? 'إنشاء حساب مدير جديد' : 'تسجيل دخول المدير',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        _showCreateMode ? 'أول مرة؟ أنشئ حسابك هنا' : 'أدخل بيانات الدخول',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // رسالة خطأ
                            if (authProvider.errorMessage.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.error_outline, color: AppColors.error, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(authProvider.errorMessage,
                                          style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // اسم المدير (فقط عند الإنشاء)
                            if (_showCreateMode) ...[
                              _buildTextField(
                                controller: _nameController,
                                label: 'اسم المدير',
                                icon: Icons.person_outline,
                                hint: 'أحمد محمد',
                              ),
                              const SizedBox(height: 12),
                            ],

                            // البريد الإلكتروني
                            _buildTextField(
                              controller: _emailController,
                              label: 'البريد الإلكتروني',
                              icon: Icons.email_outlined,
                              hint: 'admin@company.com',
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                                if (!v.contains('@') || !v.contains('.')) return 'بريد غير صالح';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // كلمة المرور
                            _buildTextField(
                              controller: _passwordController,
                              label: 'كلمة المرور',
                              icon: Icons.lock_outline,
                              hint: '••••••',
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20, color: AppColors.textHint),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'أدخل كلمة المرور';
                                if (v.length < 6) return '6 أحرف على الأقل';
                                return null;
                              },
                            ),

                            // نسيت كلمة المرور
                            if (!_showCreateMode)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _forgotPassword,
                                  child: const Text('نسيت كلمة المرور؟',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // زر رئيسي
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(_showCreateMode ? Icons.person_add : Icons.login, size: 18),
                                          const SizedBox(width: 8),
                                          Text(_showCreateMode ? 'إنشاء الحساب' : 'تسجيل الدخول',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // تبديل: إنشاء / دخول
                    TextButton(
                      onPressed: () => setState(() => _showCreateMode = !_showCreateMode),
                      child: Text(
                        _showCreateMode ? 'لديك حساب بالفعل؟ تسجيل الدخول' : 'ليس لديك حساب؟ إنشاء حساب جديد',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),

                    // أزرار أسفلية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _enterOffline,
                          icon: Icon(Icons.cloud_off, size: 15, color: AppColors.textHint),
                          label: Text('بدون إنترنت', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                        ),
                        if (_diagnosticInfo.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: _showDiagnosticDialog,
                            icon: Icon(Icons.bug_report_outlined, size: 15, color: AppColors.textHint),
                            label: Text('تشخيص', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),
                    Text('v3.3.0 | إدارة النقل', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    TextDirection? textDirection,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textDirection: textDirection ?? TextDirection.rtl,
      textAlign: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
      ),
    );
  }
}
