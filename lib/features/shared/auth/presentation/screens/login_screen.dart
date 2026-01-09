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
    if (!(_formKey.currentState?.validate() ?? false)) {
      _animC.forward(from: 0);
      return;
    }
    FocusScope.of(context).unfocus();

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

        return Stack(
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
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            'assets/images/msaratwasel_services.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'واصل',
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            height: 1.1,
          ),
        ),
      ],
    ).animate().fadeIn().scale();
  }

  Widget _buildRoleSelectionRow() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: UserRole.values.map((role) {
          final isSelected = role == _selectedRole;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildGlassCard(bool isLoading) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface.withValues(alpha: 0.4)
                : theme.shadowColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.xxl),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitle(),
              const SizedBox(height: AppSpacing.xl),
              PremiumTextField(
                controller: _idController,
                label: 'الرقم المدني',
                icon: PhosphorIconsRegular.identificationCard,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v?.isNotEmpty == true ? null : 'الرجاء إدخال الرقم المدني',
              ).animate().fadeIn(delay: 150.ms).scale(),
              const SizedBox(height: AppSpacing.lg),
              PremiumTextField(
                controller: _passwordController,
                label: 'كلمة المرور',
                icon: PhosphorIconsRegular.lock,
                keyboardType: TextInputType.visiblePassword,
                isPassword: true,
                validator: (v) =>
                    v?.isNotEmpty == true ? null : 'الرجاء إدخال كلمة المرور',
              ).animate().fadeIn(delay: 250.ms).scale(),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {
                    context.push(AppRoutes.resetPassword);
                  },
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PremiumButton(
                text: 'تسجيل الدخول',
                onTap: _handleLogin,
                isLoading: isLoading,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'مرحباً بعودتك',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'سجل الدخول للمتابعة كـ ${_selectedRole.displayName}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    ).animate().fadeIn().moveY(begin: 10, end: 0);
  }
}

/* ==================== Widgets ==================== */

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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : isDark
              ? theme.colorScheme.surface.withValues(alpha: 0.7)
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.secondary.withValues(alpha: 0.8)
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getRoleIcon(role), color: Colors.white, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              role.displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 10,
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
}
