import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';

class PremiumTextField extends StatelessWidget {
  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.isPassword = false,
    this.validator,
    this.textColor,
    this.iconColor,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextColor = textColor ?? theme.colorScheme.onSurface;
    final effectiveIconColor =
        iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      validator: validator,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: effectiveTextColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        floatingLabelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: effectiveTextColor,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: effectiveIconColor),
        filled: true,
        fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
        ),
        errorStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
