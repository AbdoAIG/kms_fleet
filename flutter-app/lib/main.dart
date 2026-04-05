import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/maintenance_provider.dart';
import 'providers/checklist_provider.dart';
import 'providers/fuel_provider.dart';
import 'services/database_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_colors.dart';
import 'models/maintenance_record.dart';
import 'models/checklist.dart';
import 'models/fuel_record.dart';
import 'models/vehicle.dart';
import 'widgets/developer_credit.dart';
import 'screens/main_screen.dart';
import 'screens/add_vehicle_screen.dart';
import 'screens/add_maintenance_screen.dart';
import 'screens/add_checklist_screen.dart';
import 'screens/add_fuel_screen.dart';
import 'screens/vehicle_details_screen.dart';

late FlutterLocalNotificationsPlugin _localNotifications;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp();

  _localNotifications = FlutterLocalNotificationsPlugin();
  await _localNotifications.initialize(
    const AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _localNotifications.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        const AndroidNotificationDetails(
          'kms_fleet',
          'KMS Fleet',
          channelDescription: 'KMS Fleet Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => ChecklistProvider()),
        ChangeNotifierProvider(create: (_) => FuelProvider()),
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
  bool _ready = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await DatabaseService.initialize();
      if (mounted) setState(() => _ready = true);
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
      home: _ready
          ? const MainScreen()
          : _SplashScreen(error: _error, onRetry: _retry),
      onGenerateRoute: (settings) {
        try {
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
          if (settings.name == '/add-checklist') {
            return MaterialPageRoute(
              builder: (_) => AddChecklistScreen(
                checklist: settings.arguments is Checklist ? settings.arguments as Checklist : null,
              ),
            );
          }
          if (settings.name == '/add-fuel') {
            final args = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => AddFuelScreen(
                record: args is FuelRecord ? args : null,
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
        } catch (e) {
          return MaterialPageRoute(builder: (_) => const MainScreen());
        }
      },
    );
  }

  void _retry() {
    setState(() { _error = ''; _ready = false; });
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
          children: [
            const Spacer(),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car, color: Colors.white, size: 64),
                SizedBox(height: 16),
                Text('KMS Fleet', style: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 24),
              ],
            ),
            CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withOpacity(0.7)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: DeveloperCredit(compact: false),
            ),
          ],
        ),
      ),
    );
  }
}
