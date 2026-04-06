import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/driver.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../providers/driver_provider.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadDrivers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await context.read<DriverProvider>().loadDrivers();
  }

  bool _isLicenseNearExpiry(Driver driver) {
    if (driver.licenseExpiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      driver.licenseExpiryDate!.year,
      driver.licenseExpiryDate!.month,
      driver.licenseExpiryDate!.day,
    );
    final diff = expiry.difference(today).inDays;
    return diff >= 0 && diff <= 30;
  }

  bool _isLicenseExpired(Driver driver) {
    if (driver.licenseExpiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      driver.licenseExpiryDate!.year,
      driver.licenseExpiryDate!.month,
      driver.licenseExpiryDate!.day,
    );
    return expiry.isBefore(today);
  }

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF2563EB),
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السائقين'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Consumer<DriverProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const SizedBox.shrink();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${provider.drivers.length} سائق',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                Navigator.pushNamed(context, '/add-driver'),
            tooltip: 'إضافة سائق',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary Stats Row ──
          Consumer<DriverProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _buildStatChip(
                      label: 'نشط',
                      count: provider.activeCount,
                      color: AppColors.success,
                      icon: Icons.check_circle,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      label: 'موقوف',
                      count: provider.suspendedCount,
                      color: AppColors.error,
                      icon: Icons.cancel,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      label: 'رخص قاربت/منتهية',
                      count: provider.nearExpiryCount + provider.expiredCount,
                      color: AppColors.warning,
                      icon: Icons.warning_amber,
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                  context.read<DriverProvider>().searchDrivers(value);
                },
                decoration: InputDecoration(
                  hintText: 'البحث بالاسم أو رقم الهاتف...',
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textHint, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.textHint, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            context
                                .read<DriverProvider>()
                                .searchDrivers('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Drivers List ──
          Expanded(
            child: Consumer<DriverProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.drivers.isEmpty) {
                  return const LoadingWidget(
                      message: 'جاري تحميل السائقين...');
                }

                if (provider.drivers.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.person_add_disabled_outlined,
                    title: 'لا يوجد سائقين',
                    subtitle: 'أضف سائق جديد لبدء إدارة السائقين',
                    actionText: 'إضافة سائق',
                    onAction: () =>
                        Navigator.pushNamed(context, '/add-driver'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: provider.drivers.length,
                    itemBuilder: (context, index) {
                      final driver = provider.drivers[index];
                      return _buildDriverCard(driver);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(Driver driver) {
    final avatarColor = _getAvatarColor(driver.name);
    final firstLetter = driver.name.isNotEmpty ? driver.name[0] : '?';
    final statusColor =
        AppConstants.driverStatusColors[driver.status] ?? AppColors.textSecondary;
    final statusText =
        AppConstants.driverStatuses[driver.status] ?? '';
    final isExpired = _isLicenseExpired(driver);
    final isNearExpiry = _isLicenseNearExpiry(driver);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(
            context,
            '/driver-details',
            arguments: driver,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: avatarColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Driver Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              driver.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            driver.phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.credit_card,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'رخصة: ${driver.licenseNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (driver.licenseExpiryDate != null) ...[
                            const SizedBox(width: 8),
                            if (isExpired)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error,
                                        size: 12, color: AppColors.error),
                                    const SizedBox(width: 2),
                                    Text(
                                      'منتهية',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isNearExpiry)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber,
                                        size: 12, color: AppColors.warning),
                                    const SizedBox(width: 2),
                                    Text(
                                      'قاربت',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                AppFormatters.formatDate(
                                    driver.licenseExpiryDate!),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(Icons.chevron_left,
                    size: 20, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
