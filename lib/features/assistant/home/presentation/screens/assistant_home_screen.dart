import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/app_theme.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import '../../../core/domain/entities/bus_student_entity.dart';
import '../../../core/presentation/cubit/bus_trip_cubit.dart';

class AssistantHomeScreen extends StatelessWidget {
  const AssistantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            PhosphorIconsRegular.list,
            color: theme.colorScheme.onSurface,
            size: 32,
          ),
          onPressed: () {
            MainShell.of(context)?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              PhosphorIconsRegular.chatCircle,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => context.push(AppRoutes.chats),
          ),
          IconButton(
            icon: Icon(
              PhosphorIconsRegular.bell,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<BusTripCubit, BusTripState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(context),
                const SizedBox(height: AppSpacing.xl),
                if (state is BusTripLoaded)
                  _buildTripSummaryCard(context, state.trip),
                const SizedBox(height: AppSpacing.xl),
                _buildQuickActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripSummaryCard(BuildContext context, dynamic trip) {
    final theme = Theme.of(context);
    final total = trip.students.length;
    final onBus = trip.students
        .where((s) => s.status == BusStudentStatus.onBus)
        .length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsFill.bus,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الرحلة النشطة - حافلة ${trip.busNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'السائق: ${trip.driverName}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              _StatusBadge(label: 'قيد التنفيذ', color: Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, '$total', 'إجمالي الطلاب'),
              _buildStatItem(context, '$onBus', 'صعدوا'),
              _buildStatItem(context, '${total - onBus}', 'متبقي'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final theme = Theme.of(context);
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
                  'مرحباً بك',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                        : theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  UserRole.busAssistant.displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'نتمنى لك يوماً سعيداً في واصل',
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
                "https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?w=400",
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخدمات الأساسية',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.2,
          children: [
            _ActionCard(
              icon: PhosphorIconsFill.users,
              label: 'قائمة الطلاب',
              color: Colors.blue,
              onTap: () => context.push(AppRoutes.busStudents),
              delay: 400,
            ),
            _ActionCard(
              icon: PhosphorIconsFill.checkCircle,
              label: 'القائمة اليومية',
              color: Colors.orange,
              onTap: () => context.push(AppRoutes.dailyChecklist),
              delay: 500,
            ),
            _ActionCard(
              icon: PhosphorIconsFill.mapPin,
              label: 'تتبع الحافلة',
              color: Colors.green,
              onTap: () => context.push(AppRoutes.busMap),
              delay: 700,
            ),
            _ActionCard(
              icon: PhosphorIconsFill.chatCircle,
              label: 'المحادثات',
              color: Colors.purple,
              onTap: () => context.push(AppRoutes.chats),
              delay: 800,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
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
