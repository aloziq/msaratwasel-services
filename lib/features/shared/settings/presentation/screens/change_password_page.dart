import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/brand_colors.dart';
import 'package:msaratwasel_services/features/shared/presentation/widgets/app_sliver_header.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: Integrate with AuthRepository.changePassword when available
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.passwordUpdatedSuccess,
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          AppSliverHeader(title: l10n.changePassword, hasLeading: true),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _PasswordField(
                      controller: _currentController,
                      label: l10n.currentPassword,
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.fieldRequired;
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 100.ms).moveY(begin: 10, end: 0),
                    const SizedBox(height: AppSpacing.md),
                    _PasswordField(
                      controller: _newController,
                      label: l10n.newPassword,
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return l10n.passwordLengthError;
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
                    const SizedBox(height: AppSpacing.md),
                    _PasswordField(
                      controller: _confirmController,
                      label: l10n.confirmPassword,
                      isDark: isDark,
                      validator: (v) {
                        if (v != _newController.text) {
                          return l10n.passwordMismatch;
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 300.ms).moveY(begin: 10, end: 0),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.saveChanges,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.isDark,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool isDark;
  final String? Function(String?)? validator;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      style: GoogleFonts.cairo(
        fontWeight: FontWeight.w600,
        color: widget.isDark ? Colors.white : BrandColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.cairo(
          color: widget.isDark ? Colors.white70 : BrandColors.textSecondary,
        ),
        filled: true,
        fillColor: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.1)
                : BrandColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.1)
                : BrandColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BrandColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? PhosphorIcons.eye(PhosphorIconsStyle.regular)
                : PhosphorIcons.eyeSlash(PhosphorIconsStyle.regular),
            color: widget.isDark ? Colors.white60 : Colors.grey,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
