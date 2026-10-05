import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

export 'app_typography.dart';
export 'app_text_sizes.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: AppColors.textPrimary,
        fontWeight: AppFontWeights.bold, // 700
        fontSize: AppTextSizes.display,
        letterSpacing: -1.0,
      ),
      headlineLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: AppColors.textPrimary,
        fontWeight: AppFontWeights.bold, // 700
        fontSize: AppTextSizes.heading,
        letterSpacing: -0.6,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: AppColors.textPrimary,
        fontWeight: AppFontWeights.semiBold, // 600
        fontSize: AppTextSizes.subheading,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: AppColors.textPrimary,
        fontWeight: AppFontWeights.semiBold, // 600
        fontSize: AppTextSizes.subheading,
      ),
      titleMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: AppColors.textPrimary,
        fontWeight: AppFontWeights.semiBold, // 600
        fontSize: AppTextSizes.body,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: AppColors.textPrimary,
        fontSize: AppTextSizes.body,
        fontWeight: AppFontWeights.regular, // 400
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: AppColors.textSecondary,
        fontSize: AppTextSizes.caption,
        fontWeight: AppFontWeights.regular, // 400
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontWeight: AppFontWeights.semiBold, // 600
        fontSize: AppTextSizes.body,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontWeight: AppFontWeights.medium, // 500
        fontSize: AppTextSizes.caption,
      ),
      labelSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontWeight: AppFontWeights.medium, // 500
        fontSize: AppTextSizes.caption,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.22),
        selectionHandleColor: AppColors.primary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textSecondary,
          fontSize: AppTextSizes.body,
          fontWeight: AppFontWeights.medium, // 500
        ),
        hintStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textMuted,
          fontSize: AppTextSizes.caption,
          fontWeight: AppFontWeights.regular, // 400
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppTextSizes.body,
            fontWeight: AppFontWeights.semiBold, // 600
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppTextSizes.body,
            fontWeight: AppFontWeights.semiBold, // 600
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.subheading,
          fontWeight: AppFontWeights.semiBold, // 600
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.caption,
          fontWeight: AppFontWeights.medium, // 500
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: Colors.white,
          fontSize: AppTextSizes.caption,
          fontWeight: AppFontWeights.semiBold, // 600
        ),
        iconTheme: const IconThemeData(
          size: 16,
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }
}
