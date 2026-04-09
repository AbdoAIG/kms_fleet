import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/fuel_provider.dart';

import '../providers/work_order_provider.dart';
import '../providers/trip_tracking_provider.dart';
import '../widgets/developer_credit.dart';
import '../services/supabase_service.dart';
import 'dashboard_screen.dart';
import 'vehicles_screen.dart';
import 'maintenance_screen.dart';
import 'fuel_screen.dart';
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
  bool _sidebarExpanded = true;
  DateTime? _lastPressedAt;
  bool _isWide = false;

  late final List<Widget> _screens = [
    DashboardScreen(onNavigateToTab: _switchToTab),
    VehiclesScreen(),
    MaintenanceScreen(),
    FuelScreen(),
    ReportsScreen(),
  ];

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'الرئيسية'),
    _NavItem(Icons.directions_car_outlined, Icons.directions_car, 'السيارات'),
    _NavItem(Icons.build_outlined, Icons.build, 'الصيانة'),
    _NavItem(Icons.local_gas_station_outlined, Icons.local_gas_station, 'الوقود'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'التقارير'),
  ];

  void _switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Auto-load all data when MainScreen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSync();
    });
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      // Refresh all data from Supabase
      final vehicleProvider = context.read<VehicleProvider>();
      final maintenanceProvider = context.read<MaintenanceProvider>();
      final fuelProvider = context.read<FuelProvider>();
      final workOrderProvider = context.read<WorkOrderProvider>();
      final tripProvider = context.read<TripTrackingProvider>();

      await Future.wait([
        vehicleProvider.loadVehicles(),
        maintenanceProvider.loadRecords(),
        fuelProvider.loadFuelRecords(),
        workOrderProvider.loadOrders(),
        tripProvider.loadTrips(),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('تم تحديث البيانات بنجاح', style: TextStyle(fontFamily: 'Cairo'))),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('فشل التحديث - تحقق من الاتصال', style: TextStyle(fontFamily: 'Cairo'))),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isWide = MediaQuery.of(context).size.width > 768;
    _isWide = isWide;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrTimerExpired =
            _lastPressedAt == null || now.difference(_lastPressedAt!) > Duration(seconds: 2);
        if (backButtonHasNotBeenPressedOrTimerExpired) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('اضغط مرة أخرى للخروج', style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else {
            exit(0);
          }
        }
      },
      child: Scaffold(
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
                if (isWide) _buildSidebar(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
    ),
    );
  }

  // ── Top Header ──────────────────────────────────────────────────────────

  Widget _buildTopHeader() {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.user?.userMetadata?['display_name'] ??
        auth.user?.email?.split('@').first ?? 'المدير';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF064E3B),
            Color(0xFF065F46),
            Color(0xFF047857),
            Color(0xFF059669),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: [
          // Deep shadow for depth
          BoxShadow(
            color: const Color(0xFF064E3B).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          // Subtle glow
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative mesh pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(
                painter: _MeshPatternPainter(),
              ),
            ),
          ),
          // Subtle gold accent line at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD4A853),
                    Color(0xFFF0D78C),
                    Color(0xFFD4A853),
                    Color(0xFFF0D78C),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
              child: Row(
                children: [
                  // Premium Logo with golden border
                  _buildPremiumLogo(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          AppConstants.appNameAr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Premium subtitle with gold accent
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFD4A853).withOpacity(0.15),
                                const Color(0xFFF0D78C).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFD4A853).withOpacity(0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 10,
                                color: const Color(0xFFD4A853).withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppConstants.appName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: const Color(0xFFD4A853).withOpacity(0.9),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_isWide) _buildSyncIndicator() else _buildCompactSyncIndicator(),
                  const SizedBox(width: 6),
                  _buildNotificationBell(),
                  const SizedBox(width: 6),
                  _buildProfileAvatar(displayName),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLogo() {
    return SizedBox(
      width: 56,
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/kms_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_shipping, size: 32, color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  void _showProfileMenu() {
    final auth = context.read<AuthProvider>();
    final displayName = auth.user?.userMetadata?['display_name'] ??
        auth.user?.email?.split('@').first ?? 'المدير';
    final email = auth.user?.email ?? '';
    final userProvider = context.read<UserProvider>();
    final roleLabel = UserProvider.getRoleLabel(userProvider.currentRole ?? 'admin');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0] : 'م',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            if (email.isNotEmpty)
              Text(email, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(roleLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (userProvider.canManageUsers)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
                title: const Text('إدارة المستخدمين', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(10)),
                  child: Text('${userProvider.totalUsers}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/user-management');
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              title: const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: context.select<NotificationProvider, int>((p) => p.unreadCount) > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                      child: Text('${context.select<NotificationProvider, int>((p) => p.unreadCount)} جديد', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    )
                  : null,
              onTap: () { Navigator.pop(context); _showNotificationsPanel(); },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () async { Navigator.pop(context); await auth.signOut(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncIndicator() {
    if (!supabaseReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFCA5A5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.2), width: 0.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 14, color: Color(0xFFFCA5A5)),
            SizedBox(width: 5),
            Text('غير متصل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFCA5A5))),
          ],
        ),
      );
    }
    return InkWell(
      onTap: _isSyncing ? null : _performSync,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4A853).withOpacity(0.25), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSyncing)
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFFF0D78C)))
            else
              const Icon(Icons.cloud_done, size: 14, color: Color(0xFFD4A853)),
            const SizedBox(width: 5),
            Text(
              _isSyncing ? 'جاري...' : 'متصل',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD4A853).withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSyncIndicator() {
    return InkWell(
      onTap: _isSyncing ? null : _performSync,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD4A853).withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Center(
          child: _isSyncing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF0D78C)))
              : Icon(
                  supabaseReady ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  size: 20,
                  color: supabaseReady ? const Color(0xFFD4A853) : const Color(0xFFFCA5A5),
                ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    final unreadCount = context.select<NotificationProvider, int>((p) => p.unreadCount);
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: _showNotificationsPanel,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: hasUnread
              ? LinearGradient(
                  colors: [
                    const Color(0xFFD4A853).withOpacity(0.2),
                    const Color(0xFFF0D78C).withOpacity(0.15),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasUnread
                ? const Color(0xFFD4A853).withOpacity(0.4)
                : Colors.white.withOpacity(0.12),
            width: hasUnread ? 1 : 0.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                hasUnread ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                size: 22,
                color: hasUnread
                    ? const Color(0xFFF0D78C)
                    : Colors.white.withOpacity(0.85),
              ),
            ),
            if (hasUnread)
              Positioned(
                left: -3,
                top: -3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF064E3B), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String displayName) {
    final initial = displayName.isNotEmpty ? displayName[0] : 'م';
    return GestureDetector(
      onTap: _showProfileMenu,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFD4A853), Color(0xFFF0D78C), Color(0xFFD4A853)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A853).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
                shadows: [
                  Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationsPanel(
        onMarkAllRead: () {
          context.read<NotificationProvider>().markAllAsRead();
          Navigator.pop(context);
        },
        onClear: () {
          context.read<NotificationProvider>().clearAll();
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Sidebar ────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: _sidebarExpanded ? 220 : 68,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: Offset(-2, 0))],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: InkWell(
                onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(_sidebarExpanded ? Icons.chevron_right : Icons.chevron_left, size: 20, color: AppColors.textHint),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            return _buildSidebarItem(i, item, _currentIndex == i);
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _buildSidebarSyncButton(),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 12, endIndent: 12),
          const DeveloperCredit(compact: true),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, _NavItem item, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: _sidebarExpanded ? 14 : 0, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: _sidebarExpanded ? MainAxisAlignment.end : MainAxisAlignment.center,
            children: [
              if (_sidebarExpanded) ...[
                Text(item.label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : AppColors.textSecondary)),
                const SizedBox(width: 12),
              ],
              Icon(isSelected ? item.activeIcon : item.icon, size: 22, color: isSelected ? Colors.white : AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSyncButton() {
    return InkWell(
      onTap: _isSyncing ? null : _performSync,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _sidebarExpanded ? 14 : 0, vertical: 10),
        decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: _sidebarExpanded ? MainAxisAlignment.end : MainAxisAlignment.center,
          children: [
            if (_sidebarExpanded) ...[
              Text('مزامنة الآن', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
              const SizedBox(width: 8),
            ],
            if (_isSyncing)
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success))
            else
              Icon(Icons.sync, size: 18, color: AppColors.success),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation (Mobile) ─────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMobileSyncBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (i) {
                  return _buildMobileNavItem(i, _navItems[i], _currentIndex == i);
                }),
              ),
            ),
            const DeveloperCredit(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSyncBar() {
    if (!supabaseReady) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        color: AppColors.warningLight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            Text('وضع بدون اتصال', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSyncing ? null : _performSync,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSyncing)
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    else
                      Icon(Icons.sync, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('مزامنة', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavItem(int index, _NavItem item, bool isSelected) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isSelected ? item.activeIcon : item.icon, size: 20, color: isSelected ? Colors.white : AppColors.textHint),
                  const SizedBox(height: 2),
                  Text(item.label, style: TextStyle(fontSize: 9, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : AppColors.textHint)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ── Notifications Panel ──────────────────────────────────────────────────

class _NotificationsPanel extends StatelessWidget {
  final VoidCallback onMarkAllRead;
  final VoidCallback onClear;

  const _NotificationsPanel({required this.onMarkAllRead, required this.onClear});

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>().notifications;
    final unreadCount = context.select<NotificationProvider, int>((p) => p.unreadCount);

    return DraggableScrollableSheet(
      initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.only(top: 12), child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    const Text('الإشعارات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const Spacer(),
                    if (unreadCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                        child: Text('$unreadCount جديد', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onMarkAllRead, borderRadius: BorderRadius.circular(8),
                        child: Padding(padding: const EdgeInsets.all(6), child: Text('قراءة الكل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, decoration: TextDecoration.underline))),
                      ),
                    ],
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onClear, borderRadius: BorderRadius.circular(8),
                      child: Padding(padding: const EdgeInsets.all(6), child: Text('مسح الكل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error, decoration: TextDecoration.underline))),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.textHint.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            const Text('لا توجد إشعارات', style: TextStyle(fontSize: 15, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('ستظهر هنا التنبيهات والتحديثات الجديدة', style: TextStyle(fontSize: 12, color: AppColors.textHint.withOpacity(0.7))),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) => _NotificationTile(notification: notifications[index], timeLabel: _formatTime(notifications[index].time)),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String timeLabel;

  const _NotificationTile({required this.notification, required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.transparent : notification.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: notification.isRead ? AppColors.border.withOpacity(0.5) : notification.color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: notification.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(notification.icon, color: notification.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(notification.title, style: TextStyle(fontSize: 14, fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700, color: AppColors.textPrimary))),
                    if (!notification.isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: notification.color, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notification.body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(timeLabel, style: TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Decorative Pattern Painter ──────────────────────────────────────────

class _MeshPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final spacing = 30.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
