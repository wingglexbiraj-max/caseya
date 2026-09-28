import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
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
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 21),
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        gradient: AppColors.headerGradient,
        border: const Border(
          bottom: BorderSide(color: AppColors.headerBorder, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.primaryDark),
              onPressed: onMenuPressed,
              tooltip: 'Open Menu',
            ),
            const SizedBox(width: 8),
          ],

          // Clean Page Title (Full header is low-opacity blue, no chip card)
          Expanded(
            child: Text(
              activeTitle,
              style: TextStyle(
                fontSize: isMobile ? 18 : 21,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                letterSpacing: -0.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Operational Status Indicators with Real-Time Clock & Date
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              if (screenWidth < 900) return const SizedBox.shrink();

              return const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LivePlantFacilityStatus(),
                  SizedBox(width: 16),
                ],
              );
            },
          ),

          // User Profile Tag with Emerald Gradient Avatar
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.25),
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      user.employeeCode,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
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

class _LivePlantFacilityStatus extends StatefulWidget {
  const _LivePlantFacilityStatus();

  @override
  State<_LivePlantFacilityStatus> createState() => _LivePlantFacilityStatusState();
}

class _LivePlantFacilityStatusState extends State<_LivePlantFacilityStatus> {
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = Formatters.formatTimeWithSeconds(_currentTime);
    final dateStr = Formatters.formatDate(_currentTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.headerBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accentCyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Plant Facility Active • $timeStr • $dateStr',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
