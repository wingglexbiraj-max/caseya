import 'package:flutter/material.dart';

/// CASEYA 4-Color Golden Ratio Design System:
/// 1. Midnight Navy (30% - Structural Identity & Key Actions)
/// 2. White (60% - Crisp Foundation Canvas & Surfaces)
/// 3. Black (Contrast, Typography & Precision Outlines)
/// 4. Golden (10% - Golden Ratio Accent, Badges & High-Value Highlights)
class AppColors {
  // ===========================================================================
  // 1. MIDNIGHT NAVY (30% - Structural Identity & Key Actions)
  // ===========================================================================
  static const Color primary = Color(0xFF0F2448); // Executive Midnight Navy
  static const Color primaryDark = Color(0xFF08152B); // Deepest Midnight
  static const Color primaryLight = Color(0xFF1E3A8A); // Rich Midnight Blue
  static const Color primaryContainer = Color(
    0xFFF0F7FF,
  ); // Low-opacity navy tint
  static const Color primarySurface = Color(0xFFF8FAFC); // Clean Porcelain Tint

  static const Color secondary = Color(0xFF0F2448);
  static const Color secondaryLight = Color(0xFFF0F7FF);

  // Left Sidebar CASEYA Brand Header (PRESERVED: Welcome Card Navy Gradient)
  static const Color brandHeaderBackground = Color(0xFF0F2448);
  static const Color brandHeaderBorder = Color(0xFF1E3A8A);
  static const LinearGradient brandHeaderGradient = LinearGradient(
    colors: [Color(0xFF0F2448), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Right Page Heading Header Section (PRESERVED: Low-Opacity Precision Blue)
  static const Color headerBackground = Color(0xFFF0F7FF);
  static const Color headerBorder = Color(0xFFCCE2FE);
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFF0F7FF), Color(0xFFE2EFFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Glowing Cyan 'C' Container Gradient (PRESERVED in Brand Header)
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Welcome Back Card Blue Gradient (PRESERVED)
  static const Color welcomeCardBgStart = Color(0xFF0F2448);
  static const Color welcomeCardBgEnd = Color(0xFF1E3A8A);
  static const LinearGradient welcomeCardGradient = LinearGradient(
    colors: [Color(0xFF0F2448), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary Gradient (Midnight Navy)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F2448), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================================================
  // 2. WHITE (60% - Dominant Foundation Canvas & Surfaces)
  // ===========================================================================
  static const Color surface = Color(0xFFFFFFFF); // Pure White Cards & Panels
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC); // Crisp Light Canvas
  static const Color textLight = Color(0xFFFFFFFF); // Crisp White Typography

  // Metric White Surfaces
  static const Color metricBgMilk = Color(0xFFF0F7FF); // Low-opacity navy tint
  static const Color metricBgStock = Color(0xFFFFFFFF); // Pure White Card

  // ===========================================================================
  // 3. BLACK (Precision Typography & Sharp Outlines)
  // ===========================================================================
  static const Color textPrimary = Color(
    0xFF000000,
  ); // True Black (Maximum Legibility)
  static const Color textSecondary = Color(0xFF374151); // Dark Charcoal Black
  static const Color textMuted = Color(0xFF6B7280); // Slate Charcoal
  static const Color cardBorder = Color(0xFFE5E7EB); // Crisp Precision Border
  static const Color cardBorderSubtle = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB); // Sharp Divider

  // Status Colors:
  static const Color info = Color(0xFF0F2448); // Midnight Navy
  static const Color infoLight = Color(0xFFF0F7FF);
  static const Color success = Color(0xFF0F2448); // Midnight Navy Verified
  static const Color successLight = Color(0xFFF0F7FF);

  // Alert / No Entry / Empty / Error Red (Color(0xFF991B1B))
  static const Color alert = Color(0xFF991B1B); // Alert Red
  static const Color alertLight = Color(0xFFFEF2F2); // Soft Alert Tint
  static const Color danger = Color(0xFF991B1B); // Critical / Danger Red
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color error = Color(0xFF991B1B);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color noEntry = Color(0xFF991B1B); // No Entry Restriction
  static const Color noEntryLight = Color(0xFFFEF2F2);
  static const Color empty = Color(0xFF991B1B); // Empty State Red Accent
  static const Color emptyLight = Color(0xFFFEF2F2);

  // ===========================================================================
  // 4. GOLDEN (10% - Golden Ratio Accent, Badges & High-Value Highlights)
  // ===========================================================================
  static const Color goldAccent = Color(0xFFD97706); // Rich Dairy Gold
  static const Color goldLight = Color(0xFFFEF3C7); // Warm Golden Glow
  static const Color goldDark = Color(0xFF92400E); // Deep Bronze Gold
  static const Color warning = Color(0xFFD97706); // Golden Indicator
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color metricBgBoiler = Color(0xFFFEF3C7); // Warm Steam Gold
  static const Color metricBgDispatch = Color(0xFFFEF3C7); // Gold Milestone

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    colors: [Color(0xFFF0F7FF), Color(0xFFFFFFFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Compatibility aliases mapped strictly to 4-color system
  static const Color accentCyan = Color(0xFF0F2448);
  static const Color accentCyanDeep = Color(0xFF0F2448);
  static const Color accentCyanLight = Color(0xFFF0F7FF);
  static const Color coolIce = Color(0xFF0F2448);
  static const Color coolIceLight = Color(0xFFF0F7FF);
  static const Color accentMint = Color(0xFF0F2448);
  static const Color accentTeal = Color(0xFF0F2448);
}
