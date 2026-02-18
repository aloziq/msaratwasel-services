import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';

import '../../../../../core/presentation/widgets/background_widget.dart';
import '../../../../../core/presentation/widgets/premium_button.dart';
import '../../../../../core/presentation/widgets/premium_text_field.dart';
import '../../domain/entities/user_entity.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../../config/theme/theme_controller.dart';
import '../../../../../config/settings/settings_controller.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.driver;

  late AnimationController _animC;

  @override
  void initState() {
    super.initState();
    _animC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animC.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    debugPrint('Login button pressed');
    if (!(_formKey.currentState?.validate() ?? false)) {
      debugPrint('Form validation failed');
      _animC.forward(from: 0);
      return;
    }
    FocusScope.of(context).unfocus();

    debugPrint(
      'Form valid, attempting login with ID: ${_idController.text}, Role: $_selectedRole',
    );
    context.read<AuthCubit>().login(
      id: _idController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is AuthAuthenticated) {
          // The router will handle the redirection automatically based on the new state
          // and its refreshListenable: GoRouterRefreshStream(authCubit.stream)
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final theme = Theme.of(context);

        return Theme(
          data: theme,
          child: Stack(
            children: [
              const BackgroundWidget(),
              GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  resizeToAvoidBottomInset: true,
                  body: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              // Role Selection Row
                              _buildRoleSelectionRow(),
                              const SizedBox(height: 18),
                              _buildGlassCard(isLoading),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: _buildTopControls(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/icon 4.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(
              l10n.appTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                height: 1.2,
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildRoleSelectionRow() {
    return Container(
          height: 115, // Fixed height sufficient for 2 lines
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Force all items to be same height
            children: UserRole.values.map((role) {
              final isSelected = role == _selectedRole;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _RoleItem(
                    role: role,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedRole = role;
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        )
        .animate()
        .fadeIn(delay: 150.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut);
  }

  Widget _buildGlassCard(bool isLoading) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitle(),
              const SizedBox(height: 32),
              PremiumTextField(
                controller: _idController,
                label: AppLocalizations.of(context)!.civilId,
                icon: PhosphorIconsRegular.identificationCard,
                keyboardType: TextInputType.number,
                fillColor: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.05),
                validator: (v) => v?.isNotEmpty == true
                    ? null
                    : AppLocalizations.of(context)!.pleaseEnterCivilId,
              ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: _passwordController,
                label: AppLocalizations.of(context)!.password,
                icon: PhosphorIconsRegular.lock,
                keyboardType: TextInputType.visiblePassword,
                isPassword: true,
                fillColor: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.05),
                validator: (v) => v?.isNotEmpty == true
                    ? null
                    : AppLocalizations.of(context)!.pleaseEnterPassword,
              ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {
                    context.push(AppRoutes.resetPassword);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.tertiary,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.forgotPassword,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PremiumButton(
                text: AppLocalizations.of(context)!.login,
                onTap: _handleLogin,
                isLoading: isLoading,
                icon: Icons.arrow_forward_rounded,
              ).animate().fadeIn(delay: 400.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    String getRoleLoginText(UserRole role) {
      switch (role) {
        case UserRole.driver:
          return l10n.driverLogin;
        case UserRole.busAssistant:
          return l10n.assistantLogin;
        case UserRole.fieldSupervisor:
          return l10n.supervisorLogin;
        case UserRole.teacher:
          return l10n.teacherLogin;
      }
    }

    return Column(
      children: [
        Text(
          l10n.welcomeBack,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            getRoleLoginText(_selectedRole),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    ).animate().fadeIn().moveY(begin: 10, end: 0);
  }
  /* ==================== Widgets ==================== */

  Widget _buildTopControls() {
    final themeController = ThemeProvider.of(context);
    final settingsController = SettingsProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Theme Toggle
        _buildCircularButton(
          onTap: () {
            final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
            themeController.setMode(newMode);
          },
          icon: isDark ? PhosphorIconsRegular.sun : PhosphorIconsRegular.moon,
        ),
        // Language Toggle
        _buildCircularButton(
          onTap: () {
            final currentLocale = Localizations.localeOf(context);
            final newLocale = currentLocale.languageCode == 'ar'
                ? const Locale('en')
                : const Locale('ar');
            settingsController.setLocale(newLocale);
          },
          icon: PhosphorIconsRegular.globe,
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: -1, end: 0);
  }

  Widget _buildCircularButton({
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
          ),
        ),
      ),
    );
  }
}

class _RoleItem extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleItem({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : theme.colorScheme.surface.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getRoleIcon(role),
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getRoleName(context, role),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 10,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return PhosphorIconsRegular.steeringWheel;
      case UserRole.busAssistant:
        return PhosphorIconsRegular.users;
      case UserRole.fieldSupervisor:
        return PhosphorIconsRegular.userList;
      case UserRole.teacher:
        return PhosphorIconsRegular.chalkboardTeacher;
    }
  }

  String _getRoleName(BuildContext context, UserRole role) {
    final l10n = AppLocalizations.of(context)!;
    switch (role) {
      case UserRole.driver:
        return l10n.roleDriver;
      case UserRole.busAssistant:
        return l10n.roleBusAssistant;
      case UserRole.fieldSupervisor:
        return l10n.roleFieldSupervisor;
      case UserRole.teacher:
        return l10n.roleTeacher;
    }
  }
}
