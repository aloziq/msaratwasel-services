import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/app_theme.dart';
import 'package:msaratwasel_services/config/theme/app_typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme & Design System Suite', () {
    test('1. AppTheme.light provides complete light ThemeData', () {
      final theme = AppTheme.light;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.accent);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Google Sans');

      // Check AppBarTheme
      expect(theme.appBarTheme.centerTitle, isTrue);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.backgroundColor, AppColors.surfaceAlt);

      // Check InputDecorationTheme
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.inputDecorationTheme.fillColor, AppColors.surfaceAlt);
      expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());

      // Check Button Themes
      expect(theme.filledButtonTheme.style, isNotNull);
      expect(theme.elevatedButtonTheme.style, isNotNull);

      // Check Chip and ListTile themes
      expect(theme.chipTheme.backgroundColor, AppColors.surface);
      expect(theme.listTileTheme.iconColor, AppColors.primary);
      expect(theme.dividerColor, AppColors.border);
    });

    test('2. AppTheme.dark provides complete dark ThemeData', () {
      final theme = AppTheme.dark;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.dark.scaffold);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.dark.accent);
      expect(theme.colorScheme.surface, AppColors.dark.scaffold);

      // Check AppBarTheme
      expect(theme.appBarTheme.centerTitle, isTrue);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.backgroundColor, AppColors.dark.scaffold);

      // Check InputDecorationTheme
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());

      // Check Button Themes
      expect(theme.filledButtonTheme.style, isNotNull);
      expect(theme.elevatedButtonTheme.style, isNotNull);
    });

    testWidgets('3. primaryGradient adapts based on theme brightness in context', (tester) async {
      LinearGradient? lightGradient;
      LinearGradient? darkGradient;

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: AppTheme.light,
            child: Builder(
              builder: (context) {
                lightGradient = AppTheme.primaryGradient(context);
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(lightGradient, isNotNull);
      expect(lightGradient!.colors.first, AppColors.primary);
      expect(lightGradient!.begin, Alignment.bottomRight);
      expect(lightGradient!.end, Alignment.topLeft);

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: AppTheme.dark,
            child: Builder(
              builder: (context) {
                darkGradient = AppTheme.primaryGradient(context);
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(darkGradient, isNotNull);
      expect(darkGradient!.begin, Alignment.bottomRight);
      expect(darkGradient!.end, Alignment.topLeft);
      expect(darkGradient!.colors.first, isNot(AppColors.primary));
    });

    test('4. AppColors constants, aliases and gradients integrity', () {
      expect(AppColors.primary, const Color(0xFF062A5A));
      expect(AppColors.primaryDark, const Color(0xFF041B3A));
      expect(AppColors.accent, const Color(0xFFFFD230));
      expect(AppColors.info, AppColors.primary);
      expect(AppColors.success, const Color(0xFF16A34A));
      expect(AppColors.warning, const Color(0xFFE9B949));
      expect(AppColors.error, const Color(0xFFDC2626));
      expect(AppColors.errorDark, const Color(0xFFFF8A80));

      expect(AppColors.surface, const Color(0xFFF7F9FC));
      expect(AppColors.snowWhite, const Color(0xFFF9FAFB));
      expect(AppColors.surfaceDark, const Color(0xFF0F172A));
      expect(AppColors.secondary, AppColors.accent);
      expect(AppColors.darkSurface, AppColors.surfaceDark);

      expect(AppColors.lightBlue, const Color(0xFF0083DA));
      expect(AppColors.dangerRed, const Color(0xFFEF4444));
      expect(AppColors.successGreen, const Color(0xFF22C55E));
      expect(AppColors.warningOrange, const Color(0xFFF59E0B));

      expect(AppColors.brandGradient.colors, [AppColors.primary, AppColors.lightBlue]);

      // AppThemeColors bundles
      final lightColors = AppColors.light;
      expect(lightColors.scaffold, AppColors.surface);
      expect(lightColors.text, AppColors.textPrimary);
      expect(lightColors.text70, AppColors.textSecondary);
      expect(lightColors.accent, AppColors.accent);
      expect(lightColors.error, AppColors.error);

      final darkColors = AppColors.dark;
      expect(darkColors.scaffold, AppColors.surfaceDark);
      expect(darkColors.text, Colors.white);
      expect(darkColors.text70, Colors.white70);
      expect(darkColors.accent, const Color(0xFF64B5F6));
      expect(darkColors.error, AppColors.errorDark);
    });

    test('5. AppSpacing and AppTypography definitions', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);

      final textTheme = AppTypography.textTheme;
      expect(textTheme.titleLarge, isNotNull);
      expect(textTheme.bodyMedium, isNotNull);
      expect(textTheme.labelLarge, isNotNull);
      expect(textTheme.labelMedium, isNotNull);
    });
  });
}
