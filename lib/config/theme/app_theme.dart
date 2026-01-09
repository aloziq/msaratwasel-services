import 'package:flutter/material.dart';
import 'brand_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData light() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: BrandColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme.copyWith(
        primary: BrandColors.primary,
        secondary: BrandColors.secondary,
      ),
      textTheme: AppTypography.textTheme(base: ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        color: Colors.white,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
    );
  }

  static ThemeData dark() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: BrandColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme.copyWith(
        primary: BrandColors.primary,
        secondary: BrandColors.secondary,
      ),
      textTheme: AppTypography.textTheme(base: ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        color: Colors.black.withValues(alpha: 0.3),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),
    );
  }

  static LinearGradient primaryGradient(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return LinearGradient(
      colors: [
        isDark
            ? Colors.black.withValues(alpha: 0.8)
            : theme.colorScheme.primary,
        const Color.fromARGB(255, 0, 131, 218),
      ],
      end: Alignment.topLeft,
      begin: Alignment.bottomRight,
    );
  }
}
