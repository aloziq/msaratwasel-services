import 'package:flutter/material.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../../config/routes/app_routes.dart';
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
            String teacherName = AppLocalizations.of(context)!.theTeacher;
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

    // Gradient from Image: Cyan/Blue to Dark Blue - now using AppColors
    final gradient = LinearGradient(
      colors: [AppColors.lightBlue, AppColors.primary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(
                "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400",
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcome,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  teacherName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.greetingAfternoon, // Dynamic greeting
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
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

    // Colors using AppColors
    const absentColor = AppColors.dangerRed;
    const presentColor = AppColors.successGreen;
    // const totalColor = AppColors.slateGray; // Removed as we use AppColors.lightBlue directly

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.cancel_rounded, // X Icon
            label: l10n.absentToday, // "غائبون اليوم"
            value: '3',
            color: absentColor,
            isDarkBg: true,
            delay: 400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            label: l10n.presentToday, // "حاضرون اليوم"
            value: '22',
            color: presentColor,
            isDarkBg: true,
            delay: 300,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.groups_rounded,
            label: l10n.studentCount, // "عدد الطلاب"
            value: '$studentCount',
            color: AppColors.lightBlue, // Changed from slateGray to Blue
            isDarkBg: true,
            delay: 200,
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
  final bool isDarkBg;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isDarkBg = false,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic Card Background based on Theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.cardDark.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.7); // Glassy White for Light Mode

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(
                  alpha: 0.5,
                ), // Lighter border in light mode
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Colors.white
                  : AppColors.textPrimary, // Dynamic Text Color
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? Colors.white70
                  : AppColors.textSecondary, // Dynamic Subtitle Color
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final dynamic classroom;

  const _QuickActionsGrid({required this.classroom});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4, // squarish but wide enough
      children: [
        _ActionCard(
          icon: PhosphorIconsFill.users,
          label: l10n.myStudents, // "طلابي"
          color: AppColors.lightBlue, // Changed from teal to Blue
          onTap: () {
            context.push(AppRoutes.myClasses);
          },
          delay: 600,
        ),
        _ActionCard(
          icon: PhosphorIconsFill.qrCode, // Grid icon kinda
          label: l10n.scanAttendance, // "مسح الحضور"
          color: AppColors.accent, // Changed from slateGray to Amber/Yellow
          onTap: () {
            context.push(AppRoutes.qrScan);
          },
          delay: 700,
        ),
        _ActionCard(
          icon: PhosphorIconsFill.clockCounterClockwise,
          label: l10n.attendanceHistory, // "سجل الحضور"
          color: AppColors.purple, // Changed from successGreen to Purple
          onTap: () {
            context.go(AppRoutes.attendanceHistory);
          },
          delay: 800,
        ),
        _ActionCard(
          icon: PhosphorIconsFill.chartBar,
          label: l10n.reports, // "التقارير"
          color: AppColors.pink, // Changed from skyBlue to Pink
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
    // Dynamic Card Background based on Theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.cardDark.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.7); // Glassy White for Light Mode

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.5),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32, // Large icon
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }
}
