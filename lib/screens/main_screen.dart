import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/maintenance_provider.dart';
import '../services/sync_service.dart';
import 'dashboard_screen.dart';
import 'vehicles_screen.dart';
import 'maintenance_screen.dart';
import 'reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  bool _isSyncing = false;

  // إزالة const لضمان بناء الشاشات بشكل صحيح
  List<Widget> get _screens => const [
    DashboardScreen(),
    VehiclesScreen(),
    MaintenanceScreen(),
    ReportsScreen(),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // تحميل جميع البيانات فور ظهور الشاشة الرئيسية
    _loadAllFleetData();
  }

  /// تحميل كل بيانات الأسطول دفعة واحدة
  Future<void> _loadAllFleetData() async {
    debugPrint('🚀 MainScreen: Loading all fleet data...');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final vehicleProvider = context.read<VehicleProvider>();
        final maintenanceProvider = context.read<MaintenanceProvider>();

        // تحميل بالتوازي
        await Future.wait([
          vehicleProvider.loadVehicles(),
          maintenanceProvider.loadRecords(),
        ]);

        debugPrint('✅ MainScreen: All data loaded - ${vehicleProvider.allVehicles.length} vehicles, ${maintenanceProvider.allRecords.length} records');
      } catch (e) {
        debugPrint('❌ MainScreen: Error loading data: $e');
      }
    });
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      final result = await SyncService.bidirectionalSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor:
                result.success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // إعادة تحميل البيانات بعد المزامنة
        await _loadAllFleetData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في المزامنة: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من النظام؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('خروج', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.directions_car, size: 22),
            const SizedBox(width: 8),
            const Text('KMS Fleet',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            if (SyncService.lastSyncTime != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done, size: 12, color: AppColors.success),
                    const SizedBox(width: 3),
                    Text('متصل',
                        style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // زر المزامنة
          if (authProvider.firebaseReady) ...[
            if (_isSyncing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              IconButton(
                icon: const Icon(Icons.cloud_sync_outlined),
                tooltip: 'مزامنة الآن',
                onPressed: _syncNow,
              ),
          ],
          // القائمة
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'theme') {
                context.read<ThemeProvider>().toggleTheme();
              } else if (value == 'sync') {
                _syncNow();
              } else if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              // اسم المدير
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(Icons.person, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(authProvider.adminName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(
                            authProvider.offlineMode ? 'وضع أوفلاين' : 'مدير النظام',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // تبديل الوضع
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      themeProvider.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(themeProvider.isDark ? 'الوضع الفاتح' : 'الوضع الداكن'),
                  ],
                ),
              ),
              // مزامنة
              if (authProvider.firebaseReady)
                PopupMenuItem(
                  value: 'sync',
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_sync, size: 20),
                      const SizedBox(width: 10),
                      const Text('مزامنة الآن'),
                      if (SyncService.lastSyncTime != null) ...[
                        const Spacer(),
                        Text(
                          AppFormatters.getRelativeDate(SyncService.lastSyncTime!),
                          style: TextStyle(fontSize: 10, color: AppColors.textHint),
                        ),
                      ],
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              // تسجيل الخروج
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.error),
                    const SizedBox(width: 10),
                    const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, 'لوحة التحكم'),
                _buildNavItem(1, Icons.local_shipping_outlined, 'المركبات'),
                _buildNavItem(2, Icons.build_outlined, 'الصيانة'),
                _buildNavItem(3, Icons.bar_chart_outlined, 'التقارير'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _currentIndex = index);
            // تحميل البيانات عند التبديل بين التبويبات
            if (index == 1) {
              context.read<VehicleProvider>().loadVehicles();
            } else if (index == 2) {
              context.read<MaintenanceProvider>().loadRecords();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedContainer(
              duration: AppConstants.shortAnimation,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
