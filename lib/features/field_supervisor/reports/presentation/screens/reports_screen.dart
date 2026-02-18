import 'package:flutter/material.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

/// Reports screen with completed trips, issues, delays, violations.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: SupervisorDrawer(
        currentIndex: 8,
        onSelect: (index) => handleSupervisorNavigation(context, index, 8),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            AppSliverHeader(
              title: l10n.reports,
              showMenu: true,
              trailing: IconButton(
                icon: Icon(Icons.download, color: AppColors.primary),
                onPressed: () {},
              ),
            ),

            // Summary Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _SummaryCard(
                      value: '156',
                      label: l10n.completedTrips,
                      color: const Color(0xFF16A34A),
                      icon: Icons.check_circle,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      value: '12',
                      label: l10n.issues,
                      color: AppColors.error,
                      icon: Icons.warning,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _SummaryCard(
                      value: '8',
                      label: l10n.delays,
                      color: const Color(0xFFEC4899),
                      icon: Icons.timer_off,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      value: '3',
                      label: l10n.violations,
                      color: const Color(0xFFF59E0B),
                      icon: Icons.gavel,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

            // Report Categories
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.reportCategories,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ReportTile(
                    icon: Icons.route,
                    title: l10n.completedTrips,
                    subtitle: l10n.viewAllTrips,
                    color: const Color(0xFF16A34A),
                    isDark: isDark,
                  ),
                  _ReportTile(
                    icon: Icons.report_problem,
                    title: l10n.issues,
                    subtitle: l10n.viewAllIssues,
                    color: AppColors.error,
                    isDark: isDark,
                  ),
                  _ReportTile(
                    icon: Icons.timer_off,
                    title: l10n.delays,
                    subtitle: l10n.viewAllDelays,
                    color: const Color(0xFFEC4899),
                    isDark: isDark,
                  ),
                  _ReportTile(
                    icon: Icons.gavel,
                    title: l10n.violations,
                    subtitle: l10n.viewAllViolations,
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                  _ReportTile(
                    icon: Icons.explore,
                    title: l10n.fieldTrips,
                    subtitle: l10n.viewFieldTrips,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ]),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
  });
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
      ),
    );
  }
}
