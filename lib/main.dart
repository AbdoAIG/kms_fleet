import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/maintenance_provider.dart';
import 'services/database_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_colors.dart';
import 'models/maintenance_record.dart';
import 'models/vehicle.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/add_vehicle_screen.dart';
import 'screens/add_maintenance_screen.dart';
import 'screens/vehicle_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Hive for local storage (works on all platforms)
  await Hive.initFlutter();

  // Initialize Firebase (optional - only if configured)
  // App works 100% offline with Hive when Firebase is not configured
  bool firebaseInitialized = false;
  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // تفعيل التخزين المؤقت لـ Firestore (يعمل أوفلاين)
      await FirebaseFirestore.instance.settings(
        const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        ),
      );
      firebaseInitialized = true;
      debugPrint('✅ Firebase + Firestore initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Firebase init failed (offline mode): $e');
    }
  } else {
    debugPrint('ℹ️ Firebase not configured - running in offline mode (Hive only)');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(firebaseReady: firebaseInitialized)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
      ],
      child: const KmsFleetApp(),
    ),
  );
}

class KmsFleetApp extends StatefulWidget {
  const KmsFleetApp({super.key});

  @override
  State<KmsFleetApp> createState() => _KmsFleetAppState();
}

class _KmsFleetAppState extends State<KmsFleetApp> {
  bool _dbReady = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await DatabaseService.initialize();
      if (mounted) setState(() => _dbReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KMS Fleet',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: context.watch<ThemeProvider>().isDark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _buildHome(),
      onGenerateRoute: (settings) {
        if (settings.name == '/add-vehicle') {
          return MaterialPageRoute(
            builder: (_) => AddVehicleScreen(vehicle: settings.arguments as Vehicle?),
          );
        }
        if (settings.name == '/add-maintenance') {
          final args = settings.arguments;
          return MaterialPageRoute(
            builder: (_) => AddMaintenanceScreen(
              record: args is MaintenanceRecord ? args : null,
              vehicle: args is Vehicle ? args : null,
            ),
          );
        }
        if (settings.name == '/vehicle-details' && settings.arguments is Vehicle) {
          return MaterialPageRoute(
            builder: (_) => VehicleDetailsScreen(vehicle: settings.arguments as Vehicle),
          );
        }
        return MaterialPageRoute(builder: (_) => const MainScreen());
      },
    );
  }

  Widget _buildHome() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // جاري التحقق من Firebase Auth
        if (authProvider.isLoading) {
          return _SplashScreen(error: '', onRetry: _retry);
        }

        // قاعدة البيانات المحلية جاهزة والمستخدم مسجل الدخول
        if (_dbReady && authProvider.isAuthenticated) {
          return const MainScreen();
        }

        // لم يتم تسجيل الدخول → شاشة تسجيل الدخول
        if (authProvider.firebaseReady || authProvider.offlineMode) {
          return const LoginScreen();
        }

        // خطأ في قاعدة البيانات
        if (_error.isNotEmpty) {
          return _SplashScreen(error: _error, onRetry: _retry);
        }

        // جاري التحميل
        return _SplashScreen(error: '', onRetry: _retry);
      },
    );
  }

  void _retry() {
    setState(() {
      _error = '';
      _dbReady = false;
    });
    _init();
  }
}

class _SplashScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _SplashScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (error.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                const Text('حدث خطأ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            const Text('KMS Fleet', style: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
