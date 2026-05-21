import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../config/theme/app_spacing.dart';

class PremiumTextField extends StatefulWidget {
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
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextColor = widget.textColor ?? theme.colorScheme.onSurface;
    final effectiveIconColor =
        widget.iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      validator: widget.validator,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines ?? 1,
      minLines: widget.minLines,
      textInputAction: widget.textInputAction,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: effectiveTextColor,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        alignLabelWithHint: widget.alignLabelWithHint,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        floatingLabelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: effectiveTextColor,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: widget.prefixWidget != null
            ? Padding(padding: const EdgeInsets.all(12), child: widget.prefixWidget)
            : (widget.icon != null ? Icon(widget.icon, color: effectiveIconColor) : null),
        suffixIcon: widget.suffixWidget != null
            ? Padding(padding: const EdgeInsets.all(12), child: widget.suffixWidget)
            : (widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? PhosphorIcons.eye(PhosphorIconsStyle.regular)
                          : PhosphorIcons.eyeSlash(PhosphorIconsStyle.regular),
                      color: effectiveIconColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null),
        filled: true,
        fillColor:
            widget.fillColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.08),
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
