import 'package:flutter/material.dart';
import 'app_text_sizes.dart';

/// Centralized Typography & Font Weight System for CASEYA.
///
/// Restricted to ONLY 4 Poppins font weights bundled in `assets/fonts`:
/// 1. Poppins Regular (400) — body text, descriptions, normal content
/// 2. Poppins Medium (500) — labels, navigation, metadata, secondary emphasis
/// 3. Poppins SemiBold (600) — headings, section titles, buttons, important values
/// 4. Poppins Bold (700) — major page titles and strong/high-priority numbers
class AppFontWeights {
  AppFontWeights._();

  /// 400 Regular — body text, descriptions, normal content
  static const FontWeight regular = FontWeight.w400;

  /// 500 Medium — labels, navigation, metadata, secondary emphasis
  static const FontWeight medium = FontWeight.w500;

  /// 600 SemiBold — headings, section titles, buttons, important values
  static const FontWeight semiBold = FontWeight.w600;

  /// 700 Bold — major page titles and strong/high-priority numbers
  static const FontWeight bold = FontWeight.w700;
}

/// Central Typography definition guaranteeing Poppins font family
/// and standard weight assignments across the application.
class AppTypography {
  AppTypography._();

  /// The singular Poppins font family registered from assets/fonts
  static const String fontFamily = 'Poppins';

  /// Helper to create a TextStyle with Poppins font family and validated weight
  static TextStyle style({
    double? fontSize,
    FontWeight fontWeight = AppFontWeights.regular,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  // ===========================================================================
  // SEMANTIC TEXT STYLES (5 Golden Ratio Sizes + 4 Poppins Weights)
  // ===========================================================================

  /// Major Page Titles & Hero Numbers (700 Bold, 38px)
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTextSizes.display,
    fontWeight: AppFontWeights.bold,
    letterSpacing: -1.0,
  );

  /// Major Headings & Strong KPI Values (700 Bold, 24px)
  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTextSizes.heading,
    fontWeight: AppFontWeights.bold,
    letterSpacing: -0.6,
  );

  /// Section Titles, Card Headers, Subheadings (600 SemiBold, 18px)
  static const TextStyle subheading = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTextSizes.subheading,
    fontWeight: AppFontWeights.semiBold,
    letterSpacing: -0.3,
  );

  /// Buttons, Table Column Headers, Important Values (600 SemiBold, 14px)
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTextSizes.body,
    fontWeight: AppFontWeights.semiBold,
    letterSpacing: 0.2,
  );

  /// Body Text, Form Inputs, Standard Content (400 Regular, 14px)
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTextSizes.body,
    fontWeight: AppFontWeights.regular,
    height: 1.45,
  );

  /// Labels, Navigation, Secondary Emphasis (500 Medium, 14px)
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTextSizes.body,
    fontWeight: AppFontWeights.medium,
  );

  /// Metadata, Status Badges, Secondary Captions (500 Medium, 11px)
  static const TextStyle metadata = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTextSizes.caption,
    fontWeight: AppFontWeights.medium,
    letterSpacing: 0.1,
  );

  /// Captions & Micro Badges (500 Medium, 11px)
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTextSizes.caption,
    fontWeight: AppFontWeights.medium,
  );
}
