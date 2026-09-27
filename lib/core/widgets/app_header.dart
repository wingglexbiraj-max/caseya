import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../utils/responsive_layout.dart';
import '../utils/formatters.dart';
import '../../providers/auth_provider.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final String activeTitle;

  const AppHeader({
    super.key,
    this.onMenuPressed,
    required this.activeTitle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isMobile = ResponsiveLayout.isMobile(context);
    final todayStr = Formatters.formatDate(DateTime.now());

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.primary),
              onPressed: onMenuPressed,
              tooltip: 'Open Menu',
            ),
            const SizedBox(width: 4),
          ],

          // Title / Breadcrumb
          Expanded(
            child: Text(
              activeTitle,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Operational Status Indicators (only on wide screens)
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              if (screenWidth < 980) return const SizedBox.shrink();

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Plant Active • $todayStr',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              );
            },
          ),

          // Fast Role Switcher (Admin / Supervisor / Operator)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: user.role,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                items: const [
                  DropdownMenuItem(
                    value: AppConstants.roleAdmin,
                    child: Text('Admin', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.roleSupervisor,
                    child: Text('Supervisor', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.roleOperator,
                    child: Text('Operator', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
                onChanged: (newRole) {
                  if (newRole != null) {
                    ref.read(authProvider.notifier).switchRole(newRole);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User Profile Tag
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user.employeeCode,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
