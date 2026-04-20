import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:msaratwasel_services/core/network/api_config.dart';
import 'package:msaratwasel_services/core/presentation/widgets/custom_menu_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/glass_card.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';
import 'package:msaratwasel_services/features/driver/maintenance/domain/entities/bus_expense.dart';
import 'package:msaratwasel_services/features/driver/maintenance/presentation/manager/maintenance_cubit.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class MaintenanceEntryScreen extends StatelessWidget {
  const MaintenanceEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MaintenanceCubit>()..fetchLogs(),
      child: const _MaintenanceEntryContent(),
    );
  }
}

class _MaintenanceEntryContent extends StatelessWidget {
  const _MaintenanceEntryContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
          ),
          CustomScrollView(
            slivers: [
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

              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: 0.9,
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
                      onTap: () => context.push(AppRoutes.driverMaintenanceRequest),
                      isArabic: isArabic,
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentLogs,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.driverMaintenanceLogs),
                        child: Text(isArabic ? "عرض الكل" : "View All"),
                      ),
                    ],
                  ),
                ),
              ),

              BlocBuilder<MaintenanceCubit, MaintenanceState>(
                builder: (context, state) {
                  if (state is MaintenanceLoadingLogs) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  if (state is MaintenanceLogsError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(state.message),
                        ),
                      ),
                    );
                  }

                  final expenses = (state is MaintenanceLogsLoaded) ? state.expenses : <dynamic>[];

                  if (expenses.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpacing.xl),
                            Icon(
                              PhosphorIconsRegular.clipboardText,
                              size: 48,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.noDataFound ?? "لا توجد سجلات",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    sliver: SliverList.separated(
                      itemCount: expenses.length > 3 ? 3 : expenses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final expense = expenses[index] as BusExpense;
                        return _MaintenanceExpenseCard(expense: expense);
                      },
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaintenanceExpenseCard extends StatelessWidget {
  final BusExpense expense;

  const _MaintenanceExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFuel = expense.type == 'fuel';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => _showDetails(context, expense),
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isFuel ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFuel ? PhosphorIconsRegular.gasPump : PhosphorIconsRegular.wrench,
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
                    isFuel ? l10n.fuelEntry : l10n.requestMaintenance,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(expense.date),
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
                Text(
                  isFuel ? '${expense.amount} L' : '${expense.amount} OMR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }

  void _showDetails(BuildContext context, BusExpense expense) {
    final theme = Theme.of(context);
    final isFuel = expense.type == 'fuel';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isFuel ? "تفاصيل الوقود" : "تفاصيل الصيانة",
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('yyyy/MM/dd').format(expense.date),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _DetailRow(
                      label: "المبلغ",
                      value: "${expense.amount} OMR",
                      icon: PhosphorIconsRegular.coins,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _DetailRow(
                      label: isFuel ? "قراءة العداد" : "الوصف",
                      value: expense.extraInfo ?? "-",
                      icon: isFuel ? PhosphorIconsRegular.speedometer : PhosphorIconsRegular.note,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (expense.receiptPhoto != null) ...[
                      const Text(
                        "صورة الفاتورة",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          ApiConfig.getImageUrl(expense.receiptPhoto),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 150,
                            color: theme.colorScheme.error.withValues(alpha: 0.05),
                            child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
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
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

