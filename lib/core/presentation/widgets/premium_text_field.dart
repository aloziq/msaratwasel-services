import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';

class PremiumTextField extends StatelessWidget {
  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.prefixWidget,
    this.suffixWidget,
    required this.keyboardType,
    this.isPassword = false,
    this.validator,
    this.textColor,
    this.iconColor,
    this.fillColor,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.minLines,
    this.textInputAction,
    this.alignLabelWithHint,
  }) : assert(
         icon != null || prefixWidget != null || suffixWidget != null,
         'Either icon, prefixWidget, or suffixWidget must be provided',
       );

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final Color? textColor;
  final Color? iconColor;
  final Color? fillColor;
  final TextAlign textAlign;

  final int? maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final bool? alignLabelWithHint;

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
      textAlign: textAlign,
      maxLines: maxLines ?? 1,
      minLines: minLines,
      textInputAction: textInputAction,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: effectiveTextColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: alignLabelWithHint,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        floatingLabelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: effectiveTextColor,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: prefixWidget != null
            ? Padding(padding: const EdgeInsets.all(12), child: prefixWidget)
            : (icon != null ? Icon(icon, color: effectiveIconColor) : null),
        suffixIcon: suffixWidget != null
            ? Padding(padding: const EdgeInsets.all(12), child: suffixWidget)
            : null,
        filled: true,
        fillColor:
            fillColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.08),
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
