import 'package:flutter/material.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/core/network/api_config.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';

/// Premium drawer for Field Supervisor navigation.
/// Inspired by parent app's RootShell design.
class SupervisorDrawer extends StatelessWidget {
  const SupervisorDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final drawerBg = isDark ? AppColors.darkSurface : Colors.white;

    return Drawer(
      elevation: 10,
      backgroundColor: drawerBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          end: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              String name = l10n.fieldSupervisor;
              String? avatar;
              
              if (state is AuthAuthenticated) {
                name = state.user.name;
                avatar = state.user.avatar;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 42),
                decoration: BoxDecoration(
                  color: drawerBg,
                  borderRadius: const BorderRadiusDirectional.only(
                    bottomEnd: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.profile);
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : AppColors.primary.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                backgroundImage: avatar != null && avatar.isNotEmpty
                                    ? NetworkImage(ApiConfig.getImageUrl(avatar))
                                    : null,
                                child: avatar == null || avatar.isEmpty
                                    ? Icon(
                                        Icons.supervisor_account_rounded,
                                        size: 40,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.supervisorRole,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              children: [
                _DrawerItem(
                  title: l10n.home,
                  icon: Icons.home_rounded,
                  isSelected: currentIndex == 0,
                  isDark: isDark,
                  onTap: () => onSelect(0),
                ),
                _DrawerItem(
                  title: l10n.busTracking,
                  icon: Icons.directions_bus_rounded,
                  isSelected: currentIndex == 1,
                  isDark: isDark,
                  onTap: () => onSelect(1),
                ),
                _DrawerItem(
                  title: l10n.driversAndSupervisors,
                  icon: Icons.people_alt_rounded,
                  isSelected: currentIndex == 2,
                  isDark: isDark,
                  onTap: () => onSelect(2),
                ),

                _DrawerItem(
                  title: l10n.incidentsAndEmergencies,
                  icon: Icons.sos_rounded,
                  isSelected: currentIndex == 4,
                  isDark: isDark,
                  onTap: () => onSelect(4),
                ),
                _DrawerItem(
                  title: l10n.fieldInspection,
                  icon: Icons.fact_check_rounded,
                  isSelected: currentIndex == 5,
                  isDark: isDark,
                  onTap: () => onSelect(5),
                ),
                _DrawerItem(
                  title: l10n.registerDelays,
                  icon: Icons.timer_off_rounded,
                  isSelected: currentIndex == 6,
                  isDark: isDark,
                  onTap: () => onSelect(6),
                ),
                _DrawerItem(
                  title: l10n.fieldTrips,
                  icon: Icons.explore_rounded,
                  isSelected: currentIndex == 7,
                  isDark: isDark,
                  onTap: () => onSelect(7),
                ),
                _DrawerItem(
                  title: l10n.reports,
                  icon: Icons.bar_chart_rounded,
                  isSelected: currentIndex == 8,
                  isDark: isDark,
                  onTap: () => onSelect(8),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),
                _DrawerItem(
                  title: l10n.settings,
                  icon: Icons.settings_rounded,
                  isSelected: currentIndex == 9,
                  isDark: isDark,
                  onTap: () => onSelect(9),
                ),
              ],
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AuthCubit>().logout();
                },
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.errorDark
                      : AppColors.error,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: (isDark ? AppColors.errorDark : AppColors.error)
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  backgroundColor: isDark
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                icon: const Icon(Icons.logout_rounded, size: 22),
                label: Text(
                  l10n.logout,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? (isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.08))
        : Colors.transparent;

    final foregroundColor = isSelected
        ? (isDark ? AppColors.secondary : AppColors.primary)
        : (isDark ? Colors.white70 : AppColors.textSecondary);

    final fontWeight = isSelected ? FontWeight.w700 : FontWeight.w500;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          minLeadingWidth: 24,
          leading: Icon(icon, color: foregroundColor, size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: fontWeight,
              color: foregroundColor,
              fontSize: 14,
            ),
          ),
          trailing: isSelected
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: foregroundColor,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
