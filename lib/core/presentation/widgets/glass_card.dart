import 'package:flutter/material.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';

/// A reusable glassmorphism-styled card with dark/light mode support.
///
/// This widget provides consistent styling across the app for cards
/// with the following features:
/// - Dark/Light mode adaptive backgrounds
/// - Subtle border styling
/// - Optional shadow effects
/// - Configurable border radius
///
/// Usage:
/// ```dart
/// GlassCard(
///   child: YourContent(),
/// )
/// ```
class GlassCard extends StatelessWidget {
  /// The child widget to display inside the card.
  final Widget child;

  /// Padding inside the card. Defaults to 16.0.
  final EdgeInsetsGeometry? padding;

  /// Border radius of the card. Defaults to 20.0.
  final double borderRadius;

  /// Optional margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Whether to show a shadow. Defaults to true in light mode.
  final bool showShadow;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20.0,
    this.margin,
    this.showShadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.cardBorderLight,
        ),
        boxShadow: (showShadow && !isDark)
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// A section header styled consistently with the app design.
class GlassSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const GlassSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
