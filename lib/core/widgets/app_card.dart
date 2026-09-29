import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool hasGlow;
  final Color? topBorderColor;
  final double topBorderHeight;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22), // Golden ratio padding ~21px
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 12,
    this.onTap,
    this.hasGlow = false,
    this.topBorderColor,
    this.topBorderHeight = 3.5,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.cardBorder,
        width: 1.1,
      ),
      boxShadow: [
        BoxShadow(
          color: hasGlow
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0x080F172A),
          blurRadius: hasGlow ? 18 : 10,
          offset: const Offset(0, 3),
        ),
      ],
    );

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (topBorderColor != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: topBorderHeight,
            color: topBorderColor,
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      );
    }

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: decoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: content,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: SelectionArea(
            child: content,
          ),
        ),
      ),
    );
  }
}
