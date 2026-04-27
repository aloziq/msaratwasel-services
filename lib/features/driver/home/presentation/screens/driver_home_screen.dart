import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';

import 'package:msaratwasel_services/features/driver/home/presentation/widgets/quick_action_button.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/widgets/daily_trips_list.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/manager/driver_home_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/core/network/api_config.dart';
import 'package:intl/intl.dart';

import 'package:msaratwasel_services/features/driver/home/domain/entities/trip_status.dart';
import 'package:msaratwasel_services/core/di/injection.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DriverHomeCubit>()..loadDashboard(),
      child: const _DriverHomeContent(),
    );
  }
}

class _DriverHomeContent extends StatefulWidget {
  const _DriverHomeContent();

  @override
  State<_DriverHomeContent> createState() => _DriverHomeContentState();
}

class _DriverHomeContentState extends State<_DriverHomeContent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final authState = context.watch<AuthCubit>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.name
        : 'Driver';
    final date = DateFormat.MMMMEEEEd(
      isArabic ? 'ar' : 'en',
    ).format(DateTime.now());

    return BlocListener<DriverHomeCubit, DriverHomeState>(
      listener: (context, state) {
        if (state is DriverHomeTripConfirmed) {
          // Auto-navigate to map/route screen when supervisor confirms
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic ? 'تم تأكيد الرحلة! جاري الانتقال...' : 'Trip confirmed! Navigating...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          context.push('/driver/route');
        }
      },
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: const Color(0xFF2563EB),
        backgroundColor: theme.colorScheme.surface,
        edgeOffset: 100,
        displacement: 40,
        strokeWidth: 3,
        onRefresh: () async {
          await context.read<DriverHomeCubit>().loadDashboard(showLoading: false);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          AdaptiveSliverAppBar(
            title: l10n.home,
            leading: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => MainShell.of(context)?.openDrawer(),
              ),
            ),
            trailing: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  PhosphorIconsRegular.bell,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {},
              ),
            ),
            backgroundColor: theme.scaffoldBackgroundColor.withValues(
              alpha: 0.9,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome Header Card ──
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      final user = authState is AuthAuthenticated
                          ? authState.user
                          : null;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Decorative circle
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                // Avatar
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: Image.network(
                                        ApiConfig.getImageUrl(user?.avatar),
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return Container(
                                                color: Colors.white24,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              );
                                            },
                                        errorBuilder: (context, error, _) {
                                          final initial =
                                              (user?.name.isNotEmpty == true)
                                              ? user!.name[0].toUpperCase()
                                              : 'D';
                                          return Container(
                                            color: Colors.white24,
                                            child: Center(
                                              child: Text(
                                                initial,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${l10n.welcome} 👋',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              fontSize: 13,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user?.name ?? userName,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 20,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          date,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                                fontSize: 12,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ).animate().fadeIn().slideY(begin: -0.2, duration: 500.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // Trip Status Card with BlocBuilder
                  BlocBuilder<DriverHomeCubit, DriverHomeState>(
                    builder: (context, state) {
                      // Extract trips from either Loaded or TripConfirmed states
                      List<TripStatus>? trips;
                      if (state is DriverHomeLoaded) {
                        trips = state.trips;
                      } else if (state is DriverHomeTripConfirmed) {
                        trips = state.trips;
                      }
                      
                      if (trips != null) {
                        if (trips.isEmpty) {
                          return _buildNoTripsCard(context, l10n);
                        }

                        final allCompleted = trips.isNotEmpty && trips.every((t) => t.isCompleted);
                        
                        if (allCompleted) {
                          return _buildCompletedTripsCard(
                                context,
                                isArabic,
                                isDark,
                              )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.1, end: 0);
                        }
                        
                        return DailyTripsList(
                              trips: trips,
                              isArabic: isArabic,
                              isDark: isDark,
                              onTripAction: (trip) async {
                                final cubit = context.read<DriverHomeCubit>();
                                if (trip.status == 'in_progress') {
                                  await context.push('/driver/route');
                                  if (context.mounted) {
                                    cubit.loadDashboard();
                                  }
                                  return;
                                }

                                await cubit.startTrip(trip.id.toString());

                                if (context.mounted) {
                                  final updatedState = cubit.state;
                                  if (updatedState is DriverHomeLoaded) {
                                      // Optional: could check if the trip changed status
                                      // and navigate if in_progress. For now we stay on home or let the driver click resume
                                      cubit.loadDashboard();
                                  } else if (updatedState is DriverHomeError) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(updatedState.message),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.1, end: 0);
                      } else if (state is DriverHomeError) {
                        return Center(
                          child: Text(
                            state.message.replaceAll('Exception: ', ''),
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Quick Actions Title
                  Text(
                    l10n.quickActions,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: AppSpacing.md),

                  // Quick Actions Grid
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DriverQuickAction(
                              icon: PhosphorIconsRegular.users,
                              label: l10n.myStudents,
                              color: Colors.green,
                              onTap: () =>
                                  context.push(AppRoutes.driverStudents),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DriverQuickAction(
                              icon: PhosphorIconsRegular.chatCircle,
                              label: l10n.chats,
                              color: Colors.blue,
                              onTap: () => context.push('/chats'),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: DriverQuickAction(
                              icon: PhosphorIconsRegular.clockCounterClockwise,
                              label: isArabic ? 'سجل الرحلات' : 'Trip History',
                              color: Colors.orange,
                              onTap: () => context.push(AppRoutes.driverTrips),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DriverQuickAction(
                              icon: PhosphorIconsRegular.warningOctagon,
                              label: l10n.sos,
                              color: Colors.red,
                              isDanger: true,
                              onTap: () => context.push('/incident-report'),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    ),
    );
  }

  Widget _buildCompletedTripsCard(
    BuildContext context,
    bool isArabic,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.8)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsFill.checkCircle,
              color: Colors.green,
              size: 48,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isArabic
                ? 'لقد اكتملت جميع رحلاتك اليوم!'
                : 'All trips completed today!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isArabic
                ? 'شكراً لك على التزامك وجهودك الرائعة.'
                : 'Thank you for your commitment and great effort.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoTripsCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.8)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsFill.calendarBlank,
              color: theme.colorScheme.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "لا توجد رحلات مجدولة اليوم",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "سيتم عرض رحلاتك هنا بمجرد تخصيصها لك.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
