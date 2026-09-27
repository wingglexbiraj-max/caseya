import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ResultItem {
  final String label;
  final String value;
  final String? unit;
  final Color? highlightColor;
  final String? subtitle;

  const ResultItem({
    required this.label,
    required this.value,
    this.unit,
    this.highlightColor,
    this.subtitle,
  });
}

class ResultCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ResultItem> items;
  final Widget? trailingAction;
  final Color? headerColor;

  const ResultCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    this.trailingAction,
    this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Soft Emerald Gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 15),
            decoration: BoxDecoration(
              gradient: AppColors.cardHeaderGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 15,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (trailingAction != null) trailingAction!,
              ],
            ),
          ),

          // Items Grid with Golden Ratio Proportions
          Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final int crossAxisCount = constraints.maxWidth < 450
                    ? 1
                    : (constraints.maxWidth < 750 ? 2 : (items.length <= 4 ? items.length : 3));

                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: items.map((item) {
                    final itemWidth =
                        (constraints.maxWidth - ((crossAxisCount - 1) * 14)) / crossAxisCount;

                    return SizedBox(
                      width: itemWidth.clamp(140.0, double.infinity),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    item.value,
                                    style: TextStyle(
                                      fontSize: 28, // Golden ratio metric display
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                      color: item.highlightColor ?? AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (item.unit != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    item.unit!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (item.subtitle != null) ...[
                              const SizedBox(height: 5),
                              Text(
                                item.subtitle!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
