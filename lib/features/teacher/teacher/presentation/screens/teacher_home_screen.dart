import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../../config/routes/app_routes.dart';

import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../features/shared/auth/presentation/cubit/auth_cubit.dart';
import '../../../../../features/shared/auth/presentation/cubit/auth_state.dart';
import '../../../../../../core/presentation/widgets/main_shell.dart';
import '../cubit/teacher_cubit.dart';
import '../cubit/teacher_state.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TeacherCubit>().loadClassroom();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              PhosphorIconsRegular.list,
              color: Theme.of(context).colorScheme.onSurface,
              size: 32,
            ),
            onPressed: () {
              MainShell.of(context)?.openDrawer();
            },
          ),
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            String teacherName = 'المعلم';
            if (authState is AuthAuthenticated) {
              teacherName = authState.user.name;
            }
            return BlocBuilder<TeacherCubit, TeacherState>(
              builder: (context, teacherState) {
                return _buildDashboard(context, teacherName, teacherState);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    String teacherName,
    TeacherState teacherState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _WelcomeHeader(teacherName: teacherName),
          const SizedBox(height: 20),

          // Stats Cards
          _StatsSection(teacherState: teacherState),
          const SizedBox(height: 24),

          // Quick Actions Title
          Text(
            l10n.quickActions,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              // fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 16),

          // Quick Actions Grid
          if (teacherState is TeacherLoading)
            const Center(child: CircularProgressIndicator())
          else if (teacherState is TeacherClassLoaded)
            _QuickActionsGrid(classroom: teacherState.classroom)
          else if (teacherState is TeacherError)
            Center(child: Text(teacherState.message)),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String teacherName;

  const _WelcomeHeader({required this.teacherName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcome,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                        : theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  teacherName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _getGreeting(context),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                        : theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400",
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }
}

class _StatsSection extends StatelessWidget {
  final TeacherState teacherState;

  const _StatsSection({required this.teacherState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    int studentCount = 0;
    if (teacherState is TeacherClassLoaded) {
      studentCount =
          (teacherState as TeacherClassLoaded).classroom.studentCount;
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: PhosphorIconsFill.users,
            label: l10n.studentCount,
            value: '$studentCount',
            color: Theme.of(context).colorScheme.onSurface,
            delay: 200,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _StatCard(
              icon: PhosphorIconsFill.checkCircle,
              label: l10n.presentToday,
              value: '22', // Placeholder
              color: Colors.green,
              delay: 300,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: PhosphorIconsFill.xCircle,
            label: l10n.absentToday,
            value: '3', // Placeholder
            color: Colors.red,
            delay: 400,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: theme.brightness == Brightness.light ? 0.1 : 0.2,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.brightness == Brightness.light
                    ? color
                    : color.withValues(alpha: 0.9),
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).scale(begin: const Offset(0.8, 0.8));
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final dynamic classroom;

  const _QuickActionsGrid({required this.classroom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.3,
      children: [
        _ActionCard(
          icon: PhosphorIconsFill.users,
          label: l10n.myStudents,
          color: Colors.tealAccent,
          onTap: () {
            context.push(AppRoutes.myClasses);
          },
          delay: 600,
        ),
        _ActionCard(
          icon: PhosphorIconsFill.qrCode,
          label: l10n.scanAttendance,
          color: theme.colorScheme.onPrimaryContainer,
          onTap: () {
            context.push(AppRoutes.qrScan);
          },
          delay: 700,
        ),
        _ActionCard(
          icon: PhosphorIconsFill.clockCounterClockwise,
          label: l10n.attendanceHistory,
          color: Colors.green,
          onTap: () {
            context.go(AppRoutes.attendanceHistory);
          },
          delay: 800,
        ),
        _ActionCard(
          icon: PhosphorIconsFill.chartBar,
          label: l10n.reports,
          color: theme.colorScheme.secondary,
          onTap: () {
            context.pushNamed('reports');
          },
          delay: 900,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: theme.brightness == Brightness.light ? 0.1 : 0.2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: theme.brightness == Brightness.light
                      ? color
                      : color.withValues(alpha: 0.9),
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2);
  }
}
