import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/responsive_layout.dart';
import '../utils/formatters.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final String activeTitle;
  final String? activeSubtitle;

  const AppHeader({
    super.key,
    this.onMenuPressed,
    required this.activeTitle,
    this.activeSubtitle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
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

          // Clean Page Title & Subtitle
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: activeSubtitle != null && !isMobile ? 30 : 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        activeTitle,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 17.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F2448),
                          letterSpacing: -0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (activeSubtitle != null && !isMobile) ...[
                        const SizedBox(height: 2),
                        Text(
                          activeSubtitle!,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            letterSpacing: -0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Plant Facility Active Badge with Real-time Clock & Date
          _LivePlantHeaderBadge(isMobile: isMobile),
        ],
      ),
    );
  }
}

class _LivePlantHeaderBadge extends StatefulWidget {
  final bool isMobile;
  const _LivePlantHeaderBadge({required this.isMobile});

  @override
  State<_LivePlantHeaderBadge> createState() => _LivePlantHeaderBadgeState();
}

class _LivePlantHeaderBadgeState extends State<_LivePlantHeaderBadge> {
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 4 : 8,
        vertical: 4,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Plant Facility Active',
                style: TextStyle(
                  fontSize: widget.isMobile ? 12 : 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F2448),
                  letterSpacing: -0.3,
                ),
              ),
              if (!widget.isMobile) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF16A34A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2.5),
          Text(
            widget.isMobile ? timeStr : '$timeStr • $dateStr',
            style: TextStyle(
              fontSize: widget.isMobile ? 13 : 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A),
              letterSpacing: -0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
