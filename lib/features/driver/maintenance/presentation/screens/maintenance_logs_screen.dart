import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:msaratwasel_services/core/network/api_config.dart';
import 'package:msaratwasel_services/core/presentation/widgets/background_widget.dart';
import 'package:msaratwasel_services/core/presentation/widgets/glass_card.dart';
import 'package:msaratwasel_services/features/driver/maintenance/domain/entities/bus_expense.dart';
import 'package:msaratwasel_services/features/driver/maintenance/presentation/manager/maintenance_cubit.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class MaintenanceLogsScreen extends StatelessWidget {
  const MaintenanceLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MaintenanceCubit>()..fetchLogs(),
      child: const _MaintenanceLogsContent(),
    );
  }
}

class _MaintenanceLogsContent extends StatefulWidget {
  const _MaintenanceLogsContent();

  @override
  State<_MaintenanceLogsContent> createState() => _MaintenanceLogsContentState();
}

class _MaintenanceLogsContentState extends State<_MaintenanceLogsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      context.read<MaintenanceCubit>().fetchLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n.recentLogs,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
      ),
      body: Stack(
        children: [
          const BackgroundWidget(),
          BlocBuilder<MaintenanceCubit, MaintenanceState>(
            builder: (context, state) {
              if (state is MaintenanceLoadingLogs) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is MaintenanceLogsError) {
                return Center(child: Text(state.message));
              }

              if (state is MaintenanceLogsLoaded || state is MaintenanceInitial) {
                final expenses = (state is MaintenanceLogsLoaded) ? state.expenses : <BusExpense>[];

                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.clipboardText,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.noDataFound ?? "لا توجد سجلات",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<MaintenanceCubit>().fetchLogs(refresh: true),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      130,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    itemCount: (state is MaintenanceLogsLoaded && state.hasReachedMax)
                        ? expenses.length
                        : expenses.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      if (index >= expenses.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final expense = expenses[index] as BusExpense;
                      return _ExpenseLogCard(expense: expense, isDark: isDark);
                    },
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}

class _ExpenseLogCard extends StatelessWidget {
  final BusExpense expense;
  final bool isDark;

  const _ExpenseLogCard({required this.expense, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFuel = expense.type == 'fuel';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return InkWell(
      onTap: () => _showDetails(context),
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isFuel ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFuel ? PhosphorIconsRegular.gasPump : PhosphorIconsRegular.wrench,
                color: isFuel ? Colors.orange : Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFuel ? "وقود" : "صيانة",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(expense.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${expense.amount} OMR",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (expense.receiptPhoto != null) ...[
                  const SizedBox(height: 4),
                  Icon(
                    PhosphorIconsRegular.image,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
                      Text(
                        "صورة الفاتورة",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
