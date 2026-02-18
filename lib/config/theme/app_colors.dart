import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// Main brand blue (from app header / drawer)
  static const Color primary = Color(0xFF062A5A);
  static const Color primaryDark = Color(0xFF041B3A);

  /// Accent yellow used for actions (e.g. طلب بطاقة)
  static const Color accent = Color(0xFFFFD230);

  /// Semantic colors
  // Status Colors from Guide
  static const Color info = primary;
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFE9B949);

  // Error colors (Light: #DC2626, Dark: #FF8A80)
  static const Color error = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFFF8A80);

  /// Neutrals & surfaces
  static const Color surface = Color(0xFFF7F9FC); // Light Background
  static const Color snowWhite = Color(0xFFF9FAFB); // Very Light Snow White
  static const Color surfaceDark = Color(
    0xFF0F172A,
  ); // Dark Background (Slate Dark)

  static const Color surfaceAlt = Colors.white;
  static const Color neutralWarm = Color(0xFFF2E5C8);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // Compatibility aliases for migration
  static const Color secondary = accent;
  static const Color darkSurface = surfaceDark;

  // ============================================
  // NEW COLORS - Extracted from hardcoded values
  // ============================================

  /// Gradient lighter blue
  static const Color lightBlue = Color(0xFF0083DA);

  /// Status colors
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningOrange = Color(0xFFF59E0B);

  /// UI Accent colors
  static const Color slateGray = Color(0xFF94A3B8);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color skyBlue = Color(0xFF38BDF8);
  static const Color indigo = Color(0xFF6366F1);
  static const Color purple = Color(0xFF7C3AED);
  static const Color pink = Color(0xFFEC4899);

  /// Card backgrounds (Dark mode)
  static const Color cardDark = Color(0xFF1E293B);
  static const Color cardBorderDark = Color(0xFF334155);
  static const Color cardLightGray = Color(0xFFF1F5F9);
  static const Color cardBorderLight = Color(0xFFE2E8F0);

  /// Social media brand colors
  static const Color twitter = Color(0xFF1DA1F2);
  static const Color instagram = Color(0xFFE1306C);
  static const Color facebook = Color(0xFF4267B2);
  static const Color whatsapp = Color(0xFF25D366);

  /// Primary gradient blending brand blue + accent or lighter blue.
  /// Guide: #062A5A -> #0083DA
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, lightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static AppThemeColors get light => const AppThemeColors(
    scaffold: surface,
    text: textPrimary,
    text70: textSecondary,
    accent: accent,
    error: error,
  );

  static AppThemeColors get dark => const AppThemeColors(
    scaffold: surfaceDark,
    text: Colors.white,
    text70: Colors.white70,
    accent: Color(0xFF64B5F6), // Dark Mode Accent
    error: errorDark,
  );
}

class AppThemeColors {
  const AppThemeColors({
    required this.scaffold,
    required this.text,
    required this.text70,
    required this.accent,
    required this.error,
  });

  final Color scaffold;
  final Color text;
  final Color text70;
  final Color accent;
  final Color error;
}
