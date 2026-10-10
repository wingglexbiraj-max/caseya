import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String? unit;
  final String? subtitle;
  final Widget? subtitleWidget;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final Color? cardBgColor;
  final Color? borderColor;
  final bool showBorder;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.subtitle,
    this.subtitleWidget,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.cardBgColor,
    this.borderColor,
    this.showBorder = true,
    this.onTap,
    this.padding,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: widget.cardBgColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: widget.showBorder
              ? Border.all(
                  color: _isHovered
                      ? (widget.borderColor != null
                          ? widget.borderColor!.withValues(alpha: 0.25)
                          : const Color(0x33000000))
                      : (widget.borderColor ?? AppColors.cardBorder),
                  width: _isHovered ? 1.4 : 1.1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0x140F172A)
                  : const Color(0x060F172A),
              blurRadius: _isHovered ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: widget.onTap != null
              ? InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: effectivePadding,
                    child: _buildCardContent(),
                  ),
                )
              : SelectionArea(
                  child: Padding(
                    padding: effectivePadding,
                    child: _buildCardContent(),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    final effectiveIconBgColor = widget.iconBgColor ??
        (widget.cardBgColor != null
            ? Colors.black.withValues(alpha: 0.06)
            : AppColors.primaryContainer);
    final effectiveIconColor = widget.iconColor ??
        (widget.cardBgColor != null
            ? Colors.black.withValues(alpha: 0.60)
            : AppColors.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTextSizes.caption,
                  fontWeight: AppFontWeights.semiBold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: effectiveIconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: effectiveIconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                widget.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTextSizes.heading, // Golden ratio metric display
                  fontWeight: AppFontWeights.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            if (widget.unit != null) ...[
              const SizedBox(width: 4),
              Text(
                widget.unit!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTextSizes.body,
                  fontWeight: AppFontWeights.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        if (widget.subtitleWidget != null) ...[
          const SizedBox(height: 5),
          widget.subtitleWidget!,
        ] else if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppTextSizes.caption,
              fontWeight: AppFontWeights.medium,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
