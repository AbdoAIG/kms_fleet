import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/security_service.dart';
import '../utils/app_colors.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    // Check security state on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkSecurityState();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (mounted && authProvider.isLockedOut) {
      _startLockoutCountdown();
    }
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _lockoutTimer?.cancel();
        return;
      }
      final auth = context.read<AuthProvider>();
      if (auth.lockoutRemaining.inSeconds <= 0) {
        _lockoutTimer?.cancel();
        auth.checkSecurityState();
      } else {
        auth.checkSecurityState();
      }
    });
  }

  Future<void> _showResetPasswordDialog() async {
    final emailController = TextEditingController();
    final authProvider = context.read<AuthProvider>();

    return showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'إعادة تعيين كلمة المرور',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'البريد الإلكتروني',
                  hintStyle: const TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال البريد الإلكتروني';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.trim().isEmpty) return;
                await authProvider.resetPassword(emailController.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        authProvider.error ?? 'تم إرسال رابط إعادة التعيين',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: authProvider.error == null
                          ? AppColors.success
                          : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  authProvider.clearError();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إرسال',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // ── Gradient Header ──
                    _buildHeader(),

                    // ── Form Content ──
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        transform: Matrix4.translationValues(0, -28, 0),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              const Text(
                                'مرحباً بك',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'سجّل دخولك لإدارة أسطولك',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // ── Lockout Warning ──
                              Consumer<AuthProvider>(
                                builder: (ctx, auth, _) {
                                  return _buildLockoutBanner(auth);
                                },
                              ),

                              // Error Banner
                              Consumer<AuthProvider>(
                                builder: (ctx, auth, _) {
                                  if (auth.error == null) return const SizedBox.shrink();
                                  // Don't show error if locked out (lockout banner is shown instead)
                                  if (auth.isLockedOut) return const SizedBox.shrink();
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.error.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            auth.error!,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 13,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: auth.clearError,
                                          child: const Icon(
                                            Icons.close,
                                            color: AppColors.error,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              // Email Field
                              _buildTextField(
                                controller: _emailController,
                                label: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال البريد الإلكتروني';
                                  }
                                  if (!value.contains('@')) {
                                    return 'البريد الإلكتروني غير صالح';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              _buildTextField(
                                controller: _passwordController,
                                label: 'كلمة المرور',
                                icon: Icons.lock_outlined,
                                obscureText: _obscurePassword,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textHint,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال كلمة المرور';
                                  }
                                  if (value.length < 6) {
                                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _showResetPasswordDialog,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  child: const Text(
                                    'نسيت كلمة المرور؟',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Login Button
                              Consumer<AuthProvider>(
                                builder: (ctx, auth, _) {
                                  final isLocked = auth.isLockedOut;
                                  return SizedBox(
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: (auth.isLoading || isLocked)
                                          ? null
                                          : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isLocked
                                            ? AppColors.textHint
                                            : AppColors.primary,
                                        disabledBackgroundColor:
                                            AppColors.textHint.withOpacity(0.6),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'تسجيل الدخول',
                                                  style: TextStyle(
                                                    fontFamily: 'Cairo',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                if (auth.remainingAttempts < 5 &&
                                                    !isLocked) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      '${auth.remainingAttempts}',
                                                      style: const TextStyle(
                                                        fontFamily: 'Cairo',
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),

                              // ── Remaining Attempts Warning ──
                              Consumer<AuthProvider>(
                                builder: (ctx, auth, _) {
                                  if (auth.isLockedOut) return const SizedBox.shrink();
                                  if (auth.remainingAttempts >= 4) return const SizedBox.shrink();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (auth.remainingAttempts <= 2
                                              ? AppColors.error
                                              : AppColors.warning)
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: (auth.remainingAttempts <= 2
                                                ? AppColors.error
                                                : AppColors.warning)
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          auth.remainingAttempts <= 2
                                              ? Icons.warning_amber
                                              : Icons.info_outline,
                                          size: 16,
                                          color: auth.remainingAttempts <= 2
                                              ? AppColors.error
                                              : AppColors.warning,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'محاولات متبقية: ${auth.remainingAttempts} من ${SecurityService.maxAttempts}',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: auth.remainingAttempts <= 2
                                                ? AppColors.error
                                                : AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),

                              // Contact Admin hint
                              const Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'للحصول على حساب، تواصل مع مدير النظام',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the lockout banner with countdown timer.
  Widget _buildLockoutBanner(AuthProvider auth) {
    if (!auth.isLockedOut) return const SizedBox.shrink();

    final remaining = auth.lockoutRemaining;
    final mins = remaining.inMinutes;
    final secs = remaining.inSeconds.remainder(60);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withOpacity(0.1),
            AppColors.error.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Lock icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_clock,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),

          // Title
          const Text(
            'تم قفل الحساب مؤقتاً',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 6),

          // Countdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$mins:${secs.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.error,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Description
          const Text(
            'بسبب nhiều المحاولات الخاطئة. حاول مرة أخرى بعد انتهاء العداد.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo (large, no frame)
          Image.asset(
            'assets/images/kms_logo.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.local_shipping, size: 80, color: Colors.white),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'KMS Fleet',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'إدارة سيارات KMS',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextDirection? textDirection,
    TextAlign? textAlign,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textDirection: textDirection,
      textAlign: textAlign ?? TextAlign.right,
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        errorStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: AppColors.error,
        ),
      ),
      validator: validator,
    );
  }
}
