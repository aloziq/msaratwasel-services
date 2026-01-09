import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/brand_colors.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../../domain/entities/report_entity.dart';
import '../../../../../core/presentation/widgets/main_shell.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsCubit>().loadReports();
  }

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
        title: Text(
          'التقارير والإحصائيات',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ReportsError) {
            return Center(child: Text(state.message));
          } else if (state is ReportsLoaded) {
            return _buildContent(state.stats);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(AttendanceStatsEntity stats) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildSummaryGrid(stats),
        const SizedBox(height: AppSpacing.xl),
        _buildTrendChart(stats.weeklyTrend),
        const SizedBox(height: AppSpacing.xl),
        _buildInsights(stats),
      ],
    );
  }

  Widget _buildSummaryGrid(AttendanceStatsEntity stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _SummaryCard(
          title: 'إجمالي الطلاب',
          value: '${stats.totalStudents}',
          icon: PhosphorIconsFill.users,
          color: BrandColors.primary,
          index: 0,
        ),
        _SummaryCard(
          title: 'حضور اليوم',
          value: '${stats.presentToday}',
          icon: PhosphorIconsFill.checkCircle,
          color: Colors.green,
          index: 1,
        ),
        _SummaryCard(
          title: 'غياب اليوم',
          value: '${stats.absentToday}',
          icon: PhosphorIconsFill.xCircle,
          color: Colors.red,
          index: 2,
        ),
        _SummaryCard(
          title: 'متوسط الحضور',
          value: '${stats.averageAttendance.toStringAsFixed(1)}%',
          icon: PhosphorIconsFill.chartLineUp,
          color: Colors.orange,
          index: 3,
        ),
      ],
    );
  }

  Widget _buildTrendChart(List<ReportEntity> trend) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: theme.brightness == Brightness.dark
            ? Border.all(color: theme.dividerColor)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اتجاه الحضور الأسبوعي',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trend.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value.attendancePercentage,
                      );
                    }).toList(),
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildInsights(AttendanceStatsEntity stats) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsFill.lightbulb,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رؤية ذكية',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  stats.averageAttendance >= 90
                      ? 'أداء الحضور ممتاز هذا الأسبوع! استمر في تحفيز الطلاب.'
                      : 'هناك انخفاض طفيف في الحضور. قد ترغب في مراجعة الأسباب.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: theme.brightness == Brightness.dark
                ? Border.all(color: theme.dividerColor)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (100 * index).ms)
        .scale(begin: const Offset(0.9, 0.9));
  }
}
