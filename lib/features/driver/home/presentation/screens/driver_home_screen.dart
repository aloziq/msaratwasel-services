import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';
import '../../data/repositories/home_mock_repository.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/widgets/quick_action_button.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/widgets/trip_status_card.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/manager/driver_home_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DriverHomeCubit(HomeMockRepository())..loadDashboard(),
      child: const _DriverHomeContent(),
    );
  }
}

class _DriverHomeContent extends StatelessWidget {
  const _DriverHomeContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
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
                  // Welcome Section
                  // TODO: Get actual user name
                  Text(
                    '${l10n.welcome} Mohammed 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ).animate().fadeIn().slideX(begin: 0.1, end: 0),
                  Text(
                    // TODO: Format date properly
                    'Wednesday, 22 Jan',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // Trip Status Card with BlocBuilder
                  BlocBuilder<DriverHomeCubit, DriverHomeState>(
                    builder: (context, state) {
                      if (state is DriverHomeLoaded) {
                        return TripStatusCard(
                          isArabic: isArabic,
                          isDark: isDark,
                          departureTime: state.tripStatus.departureTime,
                          studentCount: state.tripStatus.totalStudents
                              .toString(),
                          onStartTrip: () {
                            context.push('/driver/route');
                          },
                        );
                      } else if (state is DriverHomeError) {
                        return Center(child: Text(l10n.errorOccurred));
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

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
                  Row(
                    children: [
                      Expanded(
                        child: DriverQuickAction(
                          icon: PhosphorIconsRegular.flag,
                          label: l10n.endTripTitle,
                          color: Colors.red,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(l10n.endTripTitle),
                                content: Text(l10n.confirmEndTrip),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.push(AppRoutes.driverEndTrip);
                                    },
                                    child: Text(
                                      l10n.confirm,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

                  // Emergency Button
                  Row(
                    children: [
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
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(child: SizedBox()),
                    ],
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
