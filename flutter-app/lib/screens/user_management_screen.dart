import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/user_provider.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Page Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إدارة المستخدمين',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Consumer<UserProvider>(
                          builder: (context, provider, _) {
                            return Text(
                              '${provider.totalUsers} مستخدم • ${provider.activeUsers} نشط',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                                fontFamily: 'Cairo',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Stats chips
                  Consumer<UserProvider>(
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
                          '${provider.users.length} معروض',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
                    context.read<UserProvider>().searchUsers(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'البحث بالاسم أو البريد الإلكتروني...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textHint, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.textHint, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              context.read<UserProvider>().searchUsers('');
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

            // ── Role Filter Tabs ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('الكل', 'all'),
                    _buildFilterChip('مدير النظام', 'admin'),
                    _buildFilterChip('مشرف', 'supervisor'),
                    _buildFilterChip('سائق', 'driver'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Users List ──
            Expanded(
              child: Consumer<UserProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const LoadingWidget(
                        message: 'جاري تحميل المستخدمين...');
                  }

                  if (provider.users.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.people_outline,
                      title: 'لا يوجد مستخدمون',
                      subtitle: 'أضف مستخدم جديد لإدارة الصلاحيات',
                      actionText: 'إضافة مستخدم',
                      onAction: () => _showUserDialog(context),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: provider.users.length,
                    itemBuilder: (context, index) {
                      final user = provider.users[index];
                      return _buildUserCard(context, user);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  // ── Filter Chip ──
  Widget _buildFilterChip(String label, String value) {
    final provider = context.watch<UserProvider>();
    final isSelected = provider.roleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
        onSelected: (_) {
          provider.setRoleFilter(value);
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      ),
    );
  }

  // ── User Card ──
  Widget _buildUserCard(BuildContext context, AppUser user) {
    final roleColor = _getRoleColor(user.role);
    final roleBgColor = _getRoleBgColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showUserDialog(context, user: user),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: roleBgColor,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName.substring(0, 1)
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + status indicator
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Active/Inactive indicator
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: user.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Email
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Role chip + last login
                      Row(
                        children: [
                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleBgColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              UserProvider.getRoleLabel(user.role),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Last login
                          if (user.lastLogin != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: AppColors.textHint,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  AppFormatters.getRelativeDate(user.lastLogin!),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textHint,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),

                          const Spacer(),

                          // Status text
                          Text(
                            user.isActive ? 'نشط' : 'معطّل',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: user.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Actions
                Column(
                  children: [
                    // Edit button
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.textSecondary),
                        onPressed: () =>
                            _showUserDialog(context, user: user),
                      ),
                    ),
                    // Toggle active
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          user.isActive
                              ? Icons.toggle_on
                              : Icons.toggle_off,
                          size: 22,
                          color: user.isActive
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                        onPressed: () =>
                            _toggleUserStatus(context, user),
                      ),
                    ),
                    // Delete button
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                        onPressed: () => _confirmDelete(context, user),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Role Colors ──
  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF7C3AED); // purple
      case 'supervisor':
        return AppColors.info;
      case 'driver':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getRoleBgColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFEDE9FE);
      case 'supervisor':
        return AppColors.infoLight;
      case 'driver':
        return AppColors.primaryContainer;
      default:
        return AppColors.surfaceVariant;
    }
  }

  // ── Add/Edit User Dialog ──
  void _showUserDialog(BuildContext context, {AppUser? user}) {
    final isEditing = user != null;
    final nameController =
        TextEditingController(text: user?.displayName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    String selectedRole = user?.role ?? 'driver';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEditing ? 'تعديل المستخدم' : 'إضافة مستخدم جديد',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Display Name
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: const Icon(Icons.person_outline,
                              color: AppColors.primary, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: AppColors.primary, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 14),

                      // Phone
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف',
                          prefixIcon: const Icon(Icons.phone_outlined,
                              color: AppColors.primary, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 18),

                      // Role Selection
                      const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'الدور الوظيفي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Role selection chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['admin', 'supervisor', 'driver']
                            .map((role) {
                          final isSelected = selectedRole == role;
                          return ChoiceChip(
                            label: Text(
                              UserProvider.getRoleLabel(role),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setDialogState(() => selectedRole = role);
                            },
                            backgroundColor: AppColors.surfaceVariant,
                            selectedColor: _getRoleColor(role),
                            showCheckmark: false,
                            avatar: isSelected
                                ? null
                                : Icon(
                                    _getRoleIcon(role),
                                    size: 16,
                                    color: _getRoleColor(role),
                                  ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // Permissions summary
                      if (selectedRole.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 16,
                                    color: _getRoleColor(selectedRole),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'صلاحيات ${UserProvider.getRoleLabel(selectedRole)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _getRoleColor(selectedRole),
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ..._getPermissionsList(selectedRole).map((p) =>
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            size: 14,
                                            color: AppColors.success),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            p,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color:
                                                  AppColors.textSecondary,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              ..._getDeniedPermissionsList(selectedRole).map(
                                  (p) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.cancel,
                                                size: 14,
                                                color: AppColors.error),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                p,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.error,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final phone = phoneController.text.trim();

                    if (name.isEmpty || email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى إدخال الاسم والبريد الإلكتروني'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    if (isEditing) {
                      final updated = user!.copyWith(
                        displayName: name,
                        email: email,
                        phone: phone,
                        role: selectedRole,
                      );
                      context.read<UserProvider>().updateUser(updated);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث المستخدم بنجاح'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      final newUser = AppUser(
                        displayName: name,
                        email: email,
                        phone: phone,
                        role: selectedRole,
                      );
                      context.read<UserProvider>().addUser(newUser);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم إضافة المستخدم بنجاح'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'حفظ التعديلات' : 'إضافة',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Role Icon ──
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'supervisor':
        return Icons.supervisor_account;
      case 'driver':
        return Icons.drive_eta;
      default:
        return Icons.person;
    }
  }

  // ── Permissions description list ──
  List<String> _getPermissionsList(String role) {
    switch (role) {
      case 'admin':
        return [
          'جميع الصلاحيات',
          'إدارة المستخدمين والأدوار',
          'إضافة / تعديل / حذف المركبات',
          'عرض التقارير والإحصائيات',
          'إدارة الصيانة والوقود والفحوصات',
        ];
      case 'supervisor':
        return [
          'عرض جميع البيانات',
          'إضافة / تعديل سجلات الصيانة',
          'إضافة / تعديل سجلات الوقود',
          'إضافة / تعديل قوائم الفحص',
          'عرض التقارير والإحصائيات',
        ];
      case 'driver':
        return [
          'عرض مركبته المخصصة فقط',
          'إضافة سجلات وقود لمركبته',
          'إضافة قوائم فحص لمركبته',
        ];
      default:
        return [];
    }
  }

  List<String> _getDeniedPermissionsList(String role) {
    switch (role) {
      case 'admin':
        return [];
      case 'supervisor':
        return [
          'حذف المركبات',
          'إدارة المستخدمين',
        ];
      case 'driver':
        return [
          'عرض التقارير',
          'إدارة المركبات أو المستخدمين',
        ];
      default:
        return [];
    }
  }

  // ── Toggle user active status ──
  void _toggleUserStatus(BuildContext context, AppUser user) {
    final newStatus = !user.isActive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          newStatus ? 'تفعيل المستخدم' : 'تعطيل المستخدم',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        content: Text(
          newStatus
              ? 'هل تريد تفعيل حساب ${user.displayName}؟'
              : 'هل تريد تعطيل حساب ${user.displayName}؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserProvider>().toggleUserActive(user.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(newStatus
                      ? 'تم تفعيل ${user.displayName}'
                      : 'تم تعطيل ${user.displayName}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: newStatus ? AppColors.success : AppColors.error,
            ),
            child: Text(
              newStatus ? 'تفعيل' : 'تعطيل',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirm Delete ──
  void _confirmDelete(BuildContext context, AppUser user) {
    // Prevent deleting the last admin
    final provider = context.read<UserProvider>();
    if (user.isAdmin && provider.adminCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن حذف آخر مدير نظام'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'حذف المستخدم',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل أنت متأكد من حذف ${user.displayName}؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteUser(user.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف ${user.displayName}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'حذف',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}
