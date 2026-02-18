import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/presentation/widgets/custom_menu_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/glass_card.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class MaintenanceEntryScreen extends StatelessWidget {
  const MaintenanceEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient/Image if needed (optional, keeping consistent with theme)
          Container(
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
          ),

          CustomScrollView(
            slivers: [
              // 1. Premium Sliver App Bar
              AdaptiveSliverAppBar(
                title: l10n.maintenanceLog,
                leading: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CustomMenuButton(),
                ),
                backgroundColor: theme.scaffoldBackgroundColor.withValues(
                  alpha: 0.9,
                ),
              ),

              // 2. Options Grid
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: 1.0, // Square cards to prevent overflow
                  children: [
                    _MaintenanceOptionCard(
                      title: l10n.fuelEntry,
                      icon: PhosphorIconsRegular.gasPump,
                      color: Colors.orange,
                      onTap: () => context.push(AppRoutes.driverFuel),
                      isArabic: isArabic,
                    ),
                    _MaintenanceOptionCard(
                      title: l10n.requestMaintenance,
                      icon: PhosphorIconsRegular.wrench,
                      color: Colors.blue,
                      onTap: () =>
                          context.push(AppRoutes.driverMaintenanceRequest),
                      isArabic: isArabic,
                    ),
                  ],
                ),
              ),

              // 3. Recent Logs Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    l10n.recentLogs,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              // 4. Recent Logs List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg, // Bottom padding
                ),
                sliver: SliverList.separated(
                  itemCount: 3, // Mock count
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    // Mock Data
                    final isFuel = index == 0;
                    return GlassCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isFuel ? Colors.orange : Colors.blue)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFuel
                                  ? PhosphorIconsRegular.gasPump
                                  : PhosphorIconsRegular.wrench,
                              color: isFuel ? Colors.orange : Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFuel
                                      ? l10n.fuelEntry
                                      : l10n.requestMaintenance,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '20 Jan 2024',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isFuel)
                                Text(
                                  '35 L',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isArabic ? 'مكتمل' : 'Done',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom spacer for safe area
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaintenanceOptionCard extends StatelessWidget {
  const _MaintenanceOptionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isArabic,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
