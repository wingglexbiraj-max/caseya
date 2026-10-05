import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class SidebarItem {
  final int index;
  final String title;
  final IconData icon;
  final String? badge;

  const SidebarItem({
    required this.index,
    required this.title,
    required this.icon,
    this.badge,
  });
}

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<SidebarItem> primaryItems = [
    SidebarItem(index: 0, title: 'Dashboard', icon: Icons.grid_view_rounded),
    SidebarItem(index: 1, title: 'Lab Fat & SNF', icon: Icons.science_rounded),
    SidebarItem(index: 2, title: 'Product Calculator', icon: Icons.calculate_rounded),
    SidebarItem(index: 3, title: 'Milk Standardization', icon: Icons.water_drop_rounded),
    SidebarItem(index: 4, title: 'Boiler Fuel', icon: Icons.local_fire_department_rounded),
    SidebarItem(index: 5, title: 'DG HSD Fuel', icon: Icons.electric_bolt_rounded),
  ];

  static const List<SidebarItem> operationsItems = [
    SidebarItem(index: 6, title: 'Production Register', icon: Icons.precision_manufacturing_rounded),
    SidebarItem(index: 7, title: 'Daily Batch Making', icon: Icons.blender_rounded),
    SidebarItem(index: 8, title: 'Dispatch Records', icon: Icons.local_shipping_rounded),
    SidebarItem(index: 9, title: 'Stock & Inventory', icon: Icons.warehouse_rounded),
    SidebarItem(index: 10, title: 'Reports & Export', icon: Icons.insights_rounded),
  ];

  static const List<SidebarItem> adminItems = [
    SidebarItem(index: 11, title: 'Products Master', icon: Icons.tune_rounded),
    SidebarItem(index: 12, title: 'Settings & Config', icon: Icons.settings_suggest_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          // Brand Header with Deep Welcome Card Navy Blue Background
          Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.brandHeaderBackground,
              gradient: AppColors.brandHeaderGradient,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 1.2,
                ),
                right: BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 1.2,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/caseya-logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'lib/assets/caseya-logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: AppTextSizes.heading,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Menu Navigation List with divider line below each item
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...primaryItems.map((item) => _buildNavItemWithDivider(item)),
                ...operationsItems.map((item) => _buildNavItemWithDivider(item)),
                ...adminItems.map((item) => _buildNavItemWithDivider(item)),
              ],
            ),
          ),

          // User Profile Tile with Name, Role, & Avatar
          const _UserSidebarProfileTile(),
        ],
      ),
    );
  }

  Widget _buildNavItemWithDivider(SidebarItem item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNavItem(item),
        const Divider(
          height: 1,
          thickness: 0.8,
          color: AppColors.cardBorder,
        ),
      ],
    );
  }

  Widget _buildNavItem(SidebarItem item) {
    final isSelected = selectedIndex == item.index;

    return Material(
      color: isSelected
          ? AppColors.primaryContainer.withValues(alpha: 0.65)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(item.index),
        splashColor: AppColors.primary.withValues(alpha: 0.22),
        highlightColor: AppColors.primary.withValues(alpha: 0.12),
        hoverColor: AppColors.primary.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(
                    right: BorderSide(
                      color: AppColors.goldAccent,
                      width: 4,
                    ),
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTextSizes.body,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserSidebarProfileTile extends ConsumerWidget {
  const _UserSidebarProfileTile();

  void _showAuthDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final isLoggedIn = user.active && user.name != 'Logged Out';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isLoggedIn ? Icons.account_circle_rounded : Icons.login_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoggedIn ? 'Operator Session' : 'Operator Sign In',
                    style: const TextStyle(fontSize: AppTextSizes.subheading, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoggedIn
                        ? 'Active operator plant account session'
                        : 'Sign in to access dairy plant controls',
                    style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoggedIn) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTextSizes.body),
                          ),
                          Text(
                            '${user.role}  •  ${user.employeeCode}',
                            style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Currently operating in guest mode. Sign in to record plant operations and save batch records.',
                        style: TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (isLoggedIn)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Log Out'),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Logged out successfully'),
                    backgroundColor: AppColors.textPrimary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('Sign In as Biraj Goswami'),
              onPressed: () {
                ref.read(authProvider.notifier).loginDefault();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Signed in as Biraj Goswami (Admin)'),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isLoggedIn = user.active && user.name != 'Logged Out';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAuthDialog(context, ref, user),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: AppColors.brandHeaderBackground,
            gradient: AppColors.brandHeaderGradient,
            border: Border(
              top: BorderSide(
                color: Color(0xFF1E3A8A),
                width: 1.2,
              ),
              right: BorderSide(
                color: Color(0xFF1E3A8A),
                width: 1.2,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar DP (No green dot)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isLoggedIn && user.name.isNotEmpty ? user.name[0] : (isLoggedIn ? 'U' : '?'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: AppTextSizes.body,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoggedIn ? user.name : 'Sign In',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTextSizes.body,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      isLoggedIn ? '${user.role} • ${user.employeeCode}' : 'Tap to Log In',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTextSizes.caption,
                        color: isLoggedIn ? Colors.white.withValues(alpha: 0.75) : AppColors.goldAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                color: isLoggedIn ? Colors.white.withValues(alpha: 0.8) : AppColors.goldAccent,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
