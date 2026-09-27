import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color? textColor;
  final Color? backgroundColor;
  final IconData? icon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.text,
    this.textColor,
    this.backgroundColor,
    this.icon,
    this.fontSize = 12,
  });

  factory StatusBadge.success(String text, {IconData? icon, double fontSize = 12}) {
    return StatusBadge(
      text: text,
      textColor: AppColors.success,
      backgroundColor: AppColors.successLight,
      icon: icon ?? Icons.check_circle_outline,
      fontSize: fontSize,
    );
  }

  factory StatusBadge.warning(String text, {IconData? icon, double fontSize = 12}) {
    return StatusBadge(
      text: text,
      textColor: AppColors.warning,
      backgroundColor: AppColors.warningLight,
      icon: icon ?? Icons.access_time,
      fontSize: fontSize,
    );
  }

  factory StatusBadge.info(String text, {IconData? icon, double fontSize = 12}) {
    return StatusBadge(
      text: text,
      textColor: AppColors.info,
      backgroundColor: AppColors.infoLight,
      icon: icon ?? Icons.info_outline,
      fontSize: fontSize,
    );
  }

  factory StatusBadge.neutral(String text, {IconData? icon, double fontSize = 12}) {
    return StatusBadge(
      text: text,
      textColor: AppColors.textSecondary,
      backgroundColor: const Color(0xFFF1F5F3),
      icon: icon,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: textColor ?? AppColors.primaryDark),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
