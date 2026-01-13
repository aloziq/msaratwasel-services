import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import '../cubit/attendance_history_cubit.dart';
import '../cubit/attendance_history_state.dart';
import '../../domain/entities/attendance_history_entity.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../../../core/presentation/widgets/main_shell.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  AttendanceHistoryEntity? selectedClass;
  AttendanceHistoryRecord? selectedRecord;

  @override
  void initState() {
    super.initState();
    context.read<AttendanceHistoryCubit>().loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
        builder: (context, state) {
          if (state is AttendanceHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AttendanceHistoryError) {
            return Center(child: Text(state.message));
          } else if (state is AttendanceHistoryLoaded) {
            return CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  leading: selectedRecord != null || selectedClass != null
                      ? BackButton(
                          onPressed: () {
                            setState(() {
                              if (selectedRecord != null) {
                                selectedRecord = null;
                              } else if (selectedClass != null) {
                                selectedClass = null;
                              }
                            });
                          },
                        )
                      : IconButton(
                          icon: Icon(
                            PhosphorIconsRegular.list,
                            color: theme.colorScheme.onSurface,
                            size: 32,
                          ),
                          onPressed: () {
                            MainShell.of(context)?.openDrawer();
                          },
                        ),
                  largeTitle: Text(
                    _getTitle(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontFamily: theme.textTheme.titleLarge?.fontFamily,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  border: null,
                  stretch: true,
                ),
                if (selectedRecord != null)
                  _buildStudentsSliverList(selectedRecord!.attendedStudents)
                else if (selectedClass != null)
                  _buildDailyRecordsSliverList(selectedClass!.dailyRecords)
                else
                  _buildClassesSliverList(state.history),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _getTitle() {
    if (selectedRecord != null) {
      return 'الطلاب الحاضرون';
    } else if (selectedClass != null) {
      return selectedClass!.className;
    }
    return 'سجل الحضور';
  }

  Widget _buildClassesSliverList(List<AttendanceHistoryEntity> history) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = history[index];
          return _ClassCard(
            className: item.className,
            recordCount: item.dailyRecords.length,
            onTap: () => setState(() => selectedClass = item),
            index: index,
          );
        }, childCount: history.length),
      ),
    );
  }

  Widget _buildDailyRecordsSliverList(List<AttendanceHistoryRecord> records) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final record = records[index];
          return _HistoryCard(
            record: record,
            index: index,
            onTap: () => setState(() => selectedRecord = record),
          );
        }, childCount: records.length),
      ),
    );
  }

  Widget _buildStudentsSliverList(List<StudentEntity> students) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = students[index];
          return _StudentHistoryCard(student: student, index: index);
        }, childCount: students.length),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String className;
  final int recordCount;
  final VoidCallback onTap;
  final int index;

  const _ClassCard({
    required this.className,
    required this.recordCount,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: theme.brightness == Brightness.dark
            ? Border.all(color: theme.dividerColor)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIconsFill.chalkboardTeacher,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          className,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('$recordCount سجل يومي'),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        onTap: onTap,
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1);
  }
}

class _HistoryCard extends StatelessWidget {
  final AttendanceHistoryRecord record;
  final int index;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.record,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: theme.brightness == Brightness.dark
            ? Border.all(color: theme.dividerColor)
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsFill.calendar,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _formatDate(record.date),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${record.attendanceRate.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getAttendanceColor(
                        context,
                        record.attendanceRate,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'حاضر',
                    value: record.presentCount,
                    color: Colors.green,
                  ),
                  _StatItem(
                    label: 'غائب',
                    value: record.absentCount,
                    color: Colors.red,
                  ),
                  _StatItem(
                    label: 'تأخير',
                    value: record.lateCount,
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1);
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  Color _getAttendanceColor(BuildContext context, double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.orange;
    return Colors.red;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _StudentHistoryCard extends StatelessWidget {
  final StudentEntity student;
  final int index;

  const _StudentHistoryCard({required this.student, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: theme.brightness == Brightness.dark
            ? Border.all(color: theme.dividerColor)
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              PhosphorIconsRegular.student,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ولي الأمر: ${student.parentName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1);
  }
}
