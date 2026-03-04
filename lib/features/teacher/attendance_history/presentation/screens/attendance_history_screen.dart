import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import '../cubit/attendance_history_cubit.dart';
import '../cubit/attendance_history_state.dart';
import '../../domain/entities/attendance_history_entity.dart';
import '../../../students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  AttendanceHistoryEntity? selectedClass;
  AttendanceHistoryRecord? selectedRecord;
  AttendanceStatus? _filterStatus;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    context.read<AttendanceHistoryCubit>().loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
        builder: (context, state) {
          if (state is AttendanceHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AttendanceHistoryError) {
            return Center(child: Text(state.message));
          } else if (state is AttendanceHistoryLoaded) {
            return CustomScrollView(
              slivers: [
                AdaptiveSliverAppBar(
                  leading: selectedRecord != null || selectedClass != null
                      ? BackButton(
                          onPressed: () {
                            setState(() {
                              if (selectedRecord != null) {
                                selectedRecord = null;
                                _filterStatus = null;
                              } else if (selectedClass != null) {
                                selectedClass = null;
                                _selectedDate =
                                    null; // Reset date filter when going back
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
                  title: _getTitle(context),
                  trailing: (selectedClass != null && selectedRecord == null)
                      ? IconButton(
                          icon: Icon(
                            _selectedDate != null
                                ? PhosphorIconsFill.calendarX
                                : PhosphorIconsRegular.calendarPlus,
                            color: _selectedDate != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                          tooltip: _selectedDate != null
                              ? AppLocalizations.of(context)!.clearFilter
                              : AppLocalizations.of(context)!.searchByDate,
                          onPressed: () {
                            if (_selectedDate != null) {
                              setState(() {
                                _selectedDate = null;
                              });
                            } else {
                              _pickDate(context);
                            }
                          },
                        )
                      : null,
                  backgroundColor: Colors.transparent,
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

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2023),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (selectedRecord != null) {
      if (_filterStatus == AttendanceStatus.present) return l10n.presentToday;
      if (_filterStatus == AttendanceStatus.absent) return l10n.absentToday;
      return l10n.studentCount;
    } else if (selectedClass != null) {
      if (_selectedDate != null) {
        return "${selectedClass!.className} (${_formatDate(_selectedDate!)})";
      }
      return selectedClass!.className;
    }
    return l10n.attendanceHistory;
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
    final theme = Theme.of(context);

    // Filter records by selected date if set
    final filteredRecords = _selectedDate == null
        ? records
        : records.where((r) => isSameDay(r.date, _selectedDate!)).toList();

    if (filteredRecords.isEmpty && _selectedDate != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsDuotone.calendarX,
                size: 64,
                color: theme.disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noRecordsForDate,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _selectedDate = null),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.showAllRecords),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final record = filteredRecords[index];
          return _HistoryCard(
            record: record,
            index: index,
            onTap: () => setState(() {
              selectedRecord = record;
              _filterStatus = null;
            }),
            onPresentTap: () => setState(() {
              selectedRecord = record;
              _filterStatus = AttendanceStatus.present;
            }),
            onAbsentTap: () => setState(() {
              selectedRecord = record;
              _filterStatus = AttendanceStatus.absent;
            }),
          );
        }, childCount: filteredRecords.length),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  Widget _buildStudentsSliverList(List<StudentEntity> students) {
    // Filter students based on _filterStatus
    final filteredStudents = _filterStatus == null
        ? students
        : students.where((s) => s.status == _filterStatus).toList();

    if (filteredStudents.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsDuotone.userList,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noStudentsInList,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = filteredStudents[index];
          return _StudentHistoryCard(student: student, index: index);
        }, childCount: filteredStudents.length),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white, // Cleaner white border in light mode
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 4,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            PhosphorIconsFill.chalkboardTeacher,
            color: isDark ? Colors.white : theme.colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          className,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                PhosphorIconsRegular.fileText,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.dailyRecordCount(recordCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? PhosphorIconsRegular.caretLeft
                : PhosphorIconsRegular.caretRight,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
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
  final VoidCallback onPresentTap;
  final VoidCallback onAbsentTap;

  const _HistoryCard({
    required this.record,
    required this.index,
    required this.onTap,
    required this.onPresentTap,
    required this.onAbsentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIconsFill.calendarBlank,
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _formatDate(record.date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getAttendanceColor(
                        context,
                        record.attendanceRate,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getAttendanceColor(
                          context,
                          record.attendanceRate,
                        ).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${record.attendanceRate.toStringAsFixed(0)}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getAttendanceColor(
                          context,
                          record.attendanceRate,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Visual Progress Bar
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: record.attendanceRate / 100,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getAttendanceColor(
                          context,
                          record.attendanceRate,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onPresentTap,
                      child: _StatItem(
                        label: AppLocalizations.of(context)!.present,
                        value: record.presentCount,
                        color: AppColors.successGreen,
                        isPill: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: onAbsentTap,
                      child: _StatItem(
                        label: AppLocalizations.of(context)!.absent,
                        value: record.absentCount,
                        color: AppColors.dangerRed,
                        isPill: true,
                      ),
                    ),
                  ),
                  // const SizedBox(width: 8),
                  // Expanded(
                  //   child: _StatItem(
                  //     label: 'تأخير',
                  //     value: record.lateCount,
                  //     color: Colors.orange,
                  //     isPill: true,
                  //   ),
                  // ),
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
    if (rate >= 90) return AppColors.successGreen;
    if (rate >= 75) return Colors.orange;
    return AppColors.dangerRed;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isPill;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    this.isPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isPill) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

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
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1E293B).withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              PhosphorIconsRegular.student,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : theme.colorScheme.primary,
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
                  AppLocalizations.of(
                    context,
                  )!.parentNameLabel(student.parentName),
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
