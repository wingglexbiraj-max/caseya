import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../utils/responsive_layout.dart';
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
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      height: 66,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        gradient: AppColors.headerGradient,
        border: const Border(
          bottom: BorderSide(
            color: AppColors.headerBorder,
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2448).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: onMenuPressed,
              tooltip: 'Open Menu',
            ),
            const SizedBox(width: 8),
          ],

          // Clean Page Title (Low-Opacity Blue Header with Deep Executive Navy Typography)
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activeTitle,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 21,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F2448),
                      letterSpacing: -0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // User Profile Tag with Emerald/Cyan Avatar and Crisp Dark Typography
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user.employeeCode,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
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
