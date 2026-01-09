import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/presentation/widgets/background_widget.dart';
import '../../../../../core/presentation/widgets/premium_button.dart';
import '../../../../../core/presentation/widgets/premium_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
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
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _animC.forward(from: 0);
      return;
    }
    FocusScope.of(context).unfocus();

    context.read<AuthCubit>().resetPassword(_idController.text.trim());
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
        } else if (state is AuthPasswordResetSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال رابط إعادة تعيين كلمة المرور بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
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
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                body: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      physics: const BouncingScrollPhysics(),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 48),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
          child: Icon(
            Icons.lock_reset,
            size: 60,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'استعادة كلمة المرور',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'أدخل الرقم التعريفي لاستعادة حسابك',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    ).animate().fadeIn().scale();
  }

  Widget _buildGlassCard(bool isLoading) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface.withValues(alpha: 0.4)
                : theme.shadowColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(32),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumTextField(
                controller: _idController,
                label: 'الرقم المدني',
                icon: PhosphorIconsRegular.identificationCard,
                keyboardType: TextInputType.number,
                textColor: theme.colorScheme.onSurface,
                iconColor: theme.colorScheme.onSurface,
                validator: (v) =>
                    v?.isNotEmpty == true ? null : 'الرجاء إدخال الرقم المدني',
              ).animate().fadeIn(delay: 150.ms).scale(),
              const SizedBox(height: 32),
              PremiumButton(
                text: 'إرسال رابط الاستعادة',
                onTap: _handleReset,
                isLoading: isLoading,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
