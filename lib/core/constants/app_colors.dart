import 'package:flutter/material.dart';

/// CASEYA Deep Precision Cobalt Navy & Arctic Cyan Color Palette
/// Inspired by modern dairy tech, milk cold-chain, and automated plant control rooms
/// (Tetra Pak, GEA, Alfa Laval industrial standard).
class AppColors {
  // Brand Primary (Deep Precision Cobalt Navy)
  static const Color primary = Color(0xFF1E40AF); // Core Deep Cobalt (Blue 800)
  static const Color primaryDark = Color(0xFF0F2448); // Midnight Navy
  static const Color primaryLight = Color(
    0xFF2563EB,
  ); // Vibrant Precision Blue (Blue 600)
  static const Color primaryContainer = Color(
    0xFFEFF6FF,
  ); // Soft Arctic Ice Wash (Blue 50)
  static const Color primarySurface = Color(
    0xFFF4F8FE,
  ); // Subtle Porcelain Tint

  // Energetic Accent (Arctic Cyan & Glacier Flow)
  static const Color accentCyan = Color.fromARGB(
    255,
    2,
    101,
    147,
  ); // Electric Sky Cyan
  static const Color accentCyanDeep = Color(0xFF0284C7); // Chilled Marine Blue
  static const Color accentCyanLight = Color(0xFFE0F2FE); // Frosted Ice
  static const Color coolIce = Color(0xFF0284C7); // Chilled Arctic Blue
  static const Color coolIceLight = Color(
    0xFFE0F2FE,
  ); // Frosted Arctic Ice Light
  static const Color accentMint = Color(0xFF0EA5E9); // Cyan pulse
  static const Color accentTeal = Color(0xFF0284C7); // Marine accent

  // Golden Dairy Butterfat & Steam Accents
  static const Color goldAccent = Color(0xFFD97706); // Warm Amber Gold
  static const Color goldLight = Color(0xFFFEF3C7); // Cream Butterfat
  static const Color goldDark = Color(0xFF92400E); // Deep Bronze

  // Secondary & Industrial Slate
  static const Color secondary = Color(0xFF1E293B); // Deep Slate 800
  static const Color secondaryLight = Color(0xFFF1F5F9); // Slate 100

  // Neutrals / Surfaces
  static const Color background = Color(0xFFF8FAFC); // Ultra-clean crisp canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure Crisp Card
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0); // Crisp Slate Border
  static const Color cardBorderSubtle = Color(0xFFEDF2F7);
  static const Color divider = Color(0xFFF1F5F9);

  // Modern Typography (Slate Matrix)
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Slate 900 (High contrast)
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textLight = Color(0xFFFFFFFF);

  // Operational Status Indicators
  static const Color success = Color(0xFF0284C7); // Verified Cyan-Blue
  static const Color successLight = Color(0xFFE0F2FE); // Frost Light
  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color danger = Color(0xFFDC2626); // Rose 600
  static const Color dangerLight = Color(0xFFFEE2E2); // Rose 100
  static const Color info = Color(0xFF1D4ED8); // Pure Cobalt 700
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100

  // Metric Highlight Cards
  static const Color metricBgMilk = Color(0xFFEFF6FF); // Milk Ice Blue
  static const Color metricBgBoiler = Color(0xFFFFFBEB); // Steam Amber Warmth
  static const Color metricBgStock = Color(
    0xFFF0F9FF,
  ); // Finished Storage Sky Tint
  static const Color metricBgDispatch = Color(0xFFFAF5FF); // Dispatch Lavender

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF0F2850)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Welcome Back Card Blue (Plant Control Center / Deep Executive Navy)
  static const Color welcomeCardBgStart = Color(0xFF0F2448);
  static const Color welcomeCardBgEnd = Color(0xFF1E3A8A);
  static const LinearGradient welcomeCardGradient = LinearGradient(
    colors: [Color(0xFF0F2448), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Left Sidebar CASEYA Brand Header (Uses Welcome Card Blue)
  static const Color brandHeaderBackground = Color(0xFF0F2448);
  static const Color brandHeaderBorder = Color(0xFF1E3A8A);
  static const LinearGradient brandHeaderGradient = LinearGradient(
    colors: [Color(0xFF0F2448), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Right Page Heading Header Section (Modern Low-Opacity Precision Blue)
  static const Color headerBackground = Color(0xFFF0F7FF);
  static const Color headerBorder = Color(0xFFCCE2FE);
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFF0F7FF), Color(0xFFE2EFFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
