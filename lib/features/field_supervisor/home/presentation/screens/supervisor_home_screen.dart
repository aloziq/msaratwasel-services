import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/network/api_config.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/data/field_supervisor_remote_datasource.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

/// Main dashboard screen for Field Supervisor role.
/// Provides access to all supervisor functions with a premium UI.
class SupervisorHomeScreen extends StatefulWidget {
  const SupervisorHomeScreen({super.key});

  @override
  State<SupervisorHomeScreen> createState() => _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends State<SupervisorHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: SupervisorDrawer(
        currentIndex: 0,
        onSelect: (index) => handleSupervisorNavigation(context, index, 0),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: const SafeArea(top: false, child: _SupervisorDashboard()),
    );
  }
}

/// The main dashboard view with stats and quick actions.
class _SupervisorDashboard extends StatefulWidget {
  const _SupervisorDashboard();

  @override
  State<_SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<_SupervisorDashboard> {
  int _activeBuses = 0;
  int _activeDrivers = 0;
  int _activeTrips = 0;
  bool _isLoading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load user name from SharedPreferences
    try {
      final prefs = GetIt.instance<SharedPreferences>();
      _userName = prefs.getString('USER_NAME') ?? '';
    } catch (_) {}

    // Fetch stats from API
    final stats = await FieldSupervisorRemoteDataSource.getDashboardStats();

    if (mounted) {
      setState(() {
        _activeBuses = stats['active_buses'] ?? 0;
        _activeDrivers = stats['active_drivers'] ?? 0;
        _activeTrips = stats['active_trips'] ?? 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: l10n.fieldSupervisor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  size: 28,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),

          // Welcome Header
          SliverToBoxAdapter(
            child: _WelcomeHeader(l10n: l10n, isDark: isDark, userName: _userName),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: _StatsSection(
              l10n: l10n,
              isDark: isDark,
              activeBuses: _activeBuses,
              activeDrivers: _activeDrivers,
              activeTrips: _activeTrips,
              isLoading: _isLoading,
            ),
          ),

          // Quick Actions Title
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.quickActions,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Quick Actions Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildListDelegate([
                _QuickActionCard(
                  icon: Icons.directions_bus_rounded,
                  label: l10n.busTracking,
                  color: AppColors.primary,
                  onTap: () => handleSupervisorNavigation(
                    context,
                    1,
                    0,
                    closeDrawer: false,
                  ),
                ),
                _QuickActionCard(
                  icon: Icons.people_alt_rounded,
                  label: l10n.driversAndSupervisors,
                  color: const Color(0xFF7C3AED),
                  onTap: () => handleSupervisorNavigation(
                    context,
                    2,
                    0,
                    closeDrawer: false,
                  ),
                ),
                _QuickActionCard(
                  icon: Icons.sos_rounded,
                  label: l10n.incidentsAndEmergencies,
                  color: AppColors.error,
                  onTap: () => handleSupervisorNavigation(
                    context,
                    4,
                    0,
                    closeDrawer: false,
                  ),
                ),
                _QuickActionCard(
                  icon: Icons.fact_check_rounded,
                  label: l10n.fieldInspection,
                  color: const Color(0xFFF59E0B),
                  onTap: () => handleSupervisorNavigation(
                    context,
                    5,
                    0,
                    closeDrawer: false,
                  ),
                ),
                _QuickActionCard(
                  icon: Icons.timer_off_rounded,
                  label: l10n.registerDelays,
                  color: const Color(0xFFF59E0B),
                  onTap: () => handleSupervisorNavigation(
                    context,
                    6,
                    0,
                    closeDrawer: false,
                  ),
                ),
                _QuickActionCard(
                  icon: Icons.explore_rounded,
                  label: l10n.fieldTrips,
                  color: const Color(0xFF10B981),
                  onTap: () => handleSupervisorNavigation(
                    context,
                    7,
                    0,
                    closeDrawer: false,
                  ),
                ),
                _QuickActionCard(
                  icon: Icons.bar_chart_rounded,
                  label: l10n.reports,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => handleSupervisorNavigation(
                    context,
                    8,
                    0,
                    closeDrawer: false,
                  ),
                ),
              ]),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.l10n, required this.isDark, this.userName = ''});

  final AppLocalizations l10n;
  final bool isDark;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = l10n.greetingMorning;
    } else if (hour < 18) {
      greeting = l10n.greetingAfternoon;
    } else {
      greeting = l10n.greetingEvening;
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String name = userName.isNotEmpty ? userName : l10n.fieldSupervisor;
        String? avatar;
        
        if (state is AuthAuthenticated) {
          name = state.user.name;
          avatar = state.user.avatar;
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.85),
              ],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.welcome,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        greeting,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: avatar != null && avatar.isNotEmpty
                      ? NetworkImage(ApiConfig.getImageUrl(avatar))
                      : null,
                  child: avatar == null || avatar.isEmpty
                      ? const Icon(
                          Icons.supervisor_account_rounded,
                          color: Colors.white,
                          size: 36,
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.l10n,
    required this.isDark,
    required this.activeBuses,
    required this.activeDrivers,
    required this.activeTrips,
    required this.isLoading,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final int activeBuses;
  final int activeDrivers;
  final int activeTrips;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.directions_bus,
              label: l10n.activeBuses,
              value: isLoading ? '...' : '$activeBuses',
              color: AppColors.primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.person,
              label: l10n.activeDrivers,
              value: isLoading ? '...' : '$activeDrivers',
              color: const Color(0xFF16A34A),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.route,
              label: l10n.activeTrips,
              value: isLoading ? '...' : '$activeTrips',
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.border,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.border,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
