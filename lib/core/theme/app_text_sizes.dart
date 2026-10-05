import 'package:flutter/material.dart';
import 'app_typography.dart';
export 'app_typography.dart';

/// Central Typography & Font Size Design System for CASEYA.
///
/// Engineered around the Golden Ratio (φ ≈ 1.618) to deliver visual harmony,
/// crisp industrial legibility, and effortless global control.
///
/// Modifying these 5 constants updates the typography scale across the
/// ENTIRE website and application.
class AppTextSizes {
  AppTextSizes._();

  // ===========================================================================
  // 5 GOLDEN RATIO TYPOGRAPHY SIZES (Global Single Source of Truth)
  // ===========================================================================

  /// Level 1: Micro metadata, status badges, chip tags, footnotes, captions
  /// (~14 / 1.272 harmonic golden mean)
  static const double caption = 11.0;

  /// Level 2: Core body text, form inputs, data table cells, action buttons
  /// (Base body scale)
  static const double body = 14.0;

  /// Level 3: Card headers, section subtitles, dialog titles, tab labels
  /// (~11 * 1.618)
  static const double subheading = 18.0;

  /// Level 4: Page titles, primary section headers, medium KPI numbers
  /// (~14.5 * 1.618)
  static const double heading = 24.0;

  /// Level 5: Hero display headlines, prominent KPI values, plant counters
  /// (~23.5 * 1.618)
  static const double display = 38.0;

  // ===========================================================================
  // SEMANTIC T-SHIRT SIZING ALIASES (Mapped 1:1 to the 5 Golden Ratio Levels)
  // ===========================================================================
  static const double xs = caption;     // 11.0
  static const double sm = body;        // 14.0
  static const double md = subheading;  // 18.0
  static const double lg = heading;     // 24.0
  static const double xl = display;     // 38.0

  // ===========================================================================
  // CONVENIENCE TEXT STYLES (Utilizing 5 Golden Sizes + 4 Poppins Weights)
  // ===========================================================================
  static const TextStyle captionStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: caption,
    fontWeight: AppFontWeights.medium, // 500
    letterSpacing: 0.1,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: body,
    fontWeight: AppFontWeights.regular, // 400
    height: 1.45,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: subheading,
    fontWeight: AppFontWeights.semiBold, // 600
    letterSpacing: -0.2,
  );

  static const TextStyle headingStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: heading,
    fontWeight: AppFontWeights.bold, // 700
    letterSpacing: -0.5,
  );

  static const TextStyle displayStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: display,
    fontWeight: AppFontWeights.bold, // 700
    letterSpacing: -1.0,
  );
}
