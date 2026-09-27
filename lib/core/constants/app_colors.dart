import 'package:flutter/material.dart';

/// CASEYA Golden Ratio & Precision Industrial Dairy Color Palette
/// Designed with harmonious HSL tones, emerald botanical depth,
/// and luminous golden dairy accents (butterfat & steam warmth).
class AppColors {
  // Brand Primary (Luminous Emerald & Nordic Forest)
  static const Color primary = Color(0xFF0F5A47);          // Core Deep Emerald
  static const Color primaryDark = Color(0xFF09382C);      // Rich Obsidian Forest
  static const Color primaryLight = Color(0xFF137A60);     // Lush Pine
  static const Color primaryContainer = Color(0xFFE8F7F2);  // Soft Seafoam Wash
  static const Color primarySurface = Color(0xFFF2FAF7);    // Subtle Botanical Surface

  // Energetic Accent (Vibrant Mint Glow)
  static const Color accentMint = Color(0xFF10B981);       // Electric Mint
  static const Color accentTeal = Color(0xFF0D9488);       // Industrial Teal

  // Golden Dairy Butterfat & Steam Accents (Golden Ratio Harmonizer)
  static const Color goldAccent = Color(0xFFD97706);       // Warm Amber Gold
  static const Color goldLight = Color(0xFFFEF3C7);        // Cream Butterfat
  static const Color goldDark = Color(0xFF92400E);         // Deep Bronze

  // Cool Cold-Chain Accents
  static const Color coolIce = Color(0xFF0284C7);          // Chilled Sky
  static const Color coolIceLight = Color(0xFFE0F2FE);     // Frost White

  // Secondary & Industrial Slate
  static const Color secondary = Color(0xFF1E293B);        // Deep Slate 800
  static const Color secondaryLight = Color(0xFFF1F5F9);   // Slate 100

  // Neutrals / Surfaces
  static const Color background = Color(0xFFF8FAFC);      // Ultra-clean crisp canvas
  static const Color surface = Color(0xFFFFFFFF);         // Pure Crisp Card
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);       // Crisp Slate Border
  static const Color cardBorderSubtle = Color(0xFFEDF2F7);
  static const Color divider = Color(0xFFF1F5F9);

  // Modern Typography (Slate Matrix)
  static const Color textPrimary = Color(0xFF0F172A);      // Slate 900 (High contrast)
  static const Color textSecondary = Color(0xFF475569);    // Slate 600
  static const Color textMuted = Color(0xFF94A3B8);        // Slate 400
  static const Color textLight = Color(0xFFFFFFFF);

  // Status & Operational Indicators
  static const Color success = Color(0xFF059669);          // Emerald 600
  static const Color successLight = Color(0xFFD1FAE5);     // Emerald 100
  static const Color warning = Color(0xFFD97706);          // Amber 600
  static const Color warningLight = Color(0xFFFEF3C7);     // Amber 100
  static const Color danger = Color(0xFFDC2626);           // Rose 600
  static const Color dangerLight = Color(0xFFFEE2E2);      // Rose 100
  static const Color info = Color(0xFF2563EB);             // Blue 600
  static const Color infoLight = Color(0xFFDBEAFE);        // Blue 100

  // Metric Highlight Cards
  static const Color metricBgMilk = Color(0xFFECFDF5);
  static const Color metricBgBoiler = Color(0xFFFFFBEB);
  static const Color metricBgStock = Color(0xFFEFF6FF);
  static const Color metricBgDispatch = Color(0xFFFAF5FF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F5A47), Color(0xFF0A4032)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    colors: [Color(0xFFF0FDF8), Color(0xFFF8FAFC)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
