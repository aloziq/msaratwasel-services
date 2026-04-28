import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme/app_spacing.dart';

class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.icon,
    this.color,
    this.gradient,
    this.height = 56,
    this.borderRadius = 48,
  });

  final String text;
  final VoidCallback onTap;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final Gradient? gradient;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      child: Animate(
        effects: const [ScaleEffect(curve: Curves.elasticOut)],
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: gradient != null ? Colors.transparent : (color ?? theme.colorScheme.primary),
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent, // Shadow will be handled by container or elevation
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: gradient != null ? 0 : 8,
          ),
          child: isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(icon, size: 20, color: Colors.white),
                    ],
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
