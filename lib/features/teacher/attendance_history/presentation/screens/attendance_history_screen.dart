import 'package:flutter/material.dart';
import 'package:msaratwasel_services/core/presentation/widgets/directional_icon.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';
import '../cubit/attendance_history_cubit.dart';
import '../cubit/attendance_history_state.dart';
import '../../domain/entities/attendance_history_entity.dart';
import '../../../students/domain/entities/student_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  AttendanceHistoryEntity? selectedClass;
  AttendanceHistoryRecord? selectedRecord;
  AttendanceStatus? _filterStatus; // null means "All"

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    context.read<AttendanceHistoryCubit>().loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (selectedClass != null) {
          setState(() {
            if (selectedRecord != null) {
              selectedRecord = null;
            } else {
              selectedClass = null;
            }
          });
        } else {
          context.go(AppRoutes.teacherHome);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
      body: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
        builder: (context, state) {
          if (state is AttendanceHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AttendanceHistoryError) {
            return Center(child: Text(state.message));
          } else if (state is AttendanceHistoryLoaded) {
            final history = state.history;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                AdaptiveSliverAppBar(
                  title: selectedRecord != null 
                      ? l10n.students
                      : (selectedClass != null 
                          ? '${selectedClass!.className} (${intl.DateFormat('yyyy/M/d').format(_selectedDay ?? _focusedDay)})'
                          : l10n.attendanceHistory),
                  leading: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: DirectionalIcon(
                        selectedClass != null 
                          ? PhosphorIconsRegular.arrowLeft
                          : PhosphorIconsRegular.list,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 28,
                      ),
                      onPressed: () {
                        if (selectedClass != null) {
                          setState(() {
                            if (selectedRecord != null) {
                              selectedRecord = null;
                            } else {
                              selectedClass = null;
                            }
                          });
                        } else {
                          MainShell.of(context)?.openDrawer();
                        }
                      },
                    ),
                  ),
                ),
                if (selectedClass != null)
                  ..._buildClassHistoryContent(selectedClass!)
                else
                  _buildClassesSliverList(history),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ),
   );
  }

  Widget _buildClassesSliverList(List<AttendanceHistoryEntity> history) {
    return SliverPadding(
      padding: EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final classModel = history[index];
            return _ClassCard(
              classModel: classModel,
              onTap: () => setState(() => selectedClass = classModel),
            ).animate().fadeIn(delay: (index * 50).ms).slideX();
          },
          childCount: history.length,
        ),
      ),
    );
  }

  List<Widget> _buildClassHistoryContent(AttendanceHistoryEntity classModel) {
    final records = classModel.dailyRecords;
    final currentRecord = records.any((r) => isSameDay(r.date, _selectedDay))
        ? records.firstWhere((r) => isSameDay(r.date, _selectedDay))
        : null;

    int totalPresent = 0;
    int totalAbsent = 0;
    for (var r in records) {
      if (r.date.month == _focusedDay.month && r.date.year == _focusedDay.year) {
        totalPresent += r.presentCount;
        totalAbsent += r.absentCount;
      }
    }

    return [
      SliverToBoxAdapter(
        child: Column(
          children: [
        // 1. Top Summary Cards (Present/Absent)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _HeaderSummaryCard(
                  label: '${AppLocalizations.of(context)!.present} (هذا الشهر)',
                  value: totalPresent.toString(),
                  color: const Color(0xFF10B981),
                  icon: PhosphorIconsFill.checkCircle,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HeaderSummaryCard(
                  label: '${AppLocalizations.of(context)!.absent} (هذا الشهر)',
                  value: totalAbsent.toString(),
                  color: const Color(0xFFEF4444),
                  icon: PhosphorIconsFill.xCircle,
                ),
              ),
            ],
          ),
        ),

        // 2. Calendar Card
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildCalendarHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildCustomCalendar(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        SizedBox(height: AppSpacing.lg),

        // 3. Daily Status Card
            if (currentRecord != null)
              _DailyDetailCard(
                record: currentRecord,
                onFilterSelected: (status) => setState(() => _filterStatus = status),
                currentFilter: _filterStatus,
                onTap: () => setState(() => _filterStatus = null),
              )
            else
              _EmptyRecordCard(date: _selectedDay ?? DateTime.now()),
          ],
        ),
      ),
      if (currentRecord != null)
        _buildStudentsSliverList(currentRecord.attendedStudents)
    ];
  }

  Widget _buildCalendarHeader() {
    final languageCode = Localizations.localeOf(context).languageCode;
    final monthName = intl.DateFormat.MMMM(languageCode).format(_focusedDay);
    final year = _focusedDay.year;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const DirectionalIcon(Icons.chevron_left, color: Color(0xFF1E293B)),
            onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
          ),
          Text(
            '$monthName $year',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          IconButton(
            icon: const DirectionalIcon(Icons.chevron_right, color: Color(0xFF1E293B)),
            onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCalendar() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    
    int getColumnIndex(int weekday) {
      if (weekday == DateTime.sunday) return 0;
      if (weekday >= DateTime.monday && weekday <= DateTime.thursday) return weekday;
      return -1;
    }
    
    int firstWorkingDay = 1;
    while (firstWorkingDay <= daysInMonth && getColumnIndex(DateTime(_focusedDay.year, _focusedDay.month, firstWorkingDay).weekday) == -1) {
      firstWorkingDay++;
    }
    
    int emptyCellsAtStart = firstWorkingDay <= daysInMonth 
        ? getColumnIndex(DateTime(_focusedDay.year, _focusedDay.month, firstWorkingDay).weekday) 
        : 0;
    
    List<DateTime?> gridDays = List.generate(emptyCellsAtStart, (index) => null, growable: true);
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime day = DateTime(_focusedDay.year, _focusedDay.month, i);
      if (day.weekday != DateTime.friday && day.weekday != DateTime.saturday) {
        gridDays.add(day);
      }
    }
    
    return Column(
      children: [
        // Days of week header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: gridDays.length,
            itemBuilder: (context, index) {
              final day = gridDays[index];
              if (day == null) return const SizedBox();
              
              final isSelected = isSameDay(day, _selectedDay);
              final isToday = isSameDay(day, DateTime.now());
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                    _focusedDay = day;
                  });
                },
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFFECFDF5) 
                        : (isToday ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: GoogleFonts.cairo(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : (isToday ? Colors.blue : const Color(0xFF475569)),
                        fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsSliverList(List<StudentEntity> students) {
    final filteredStudents = _filterStatus == null 
        ? students 
        : students.where((s) => s.status == _filterStatus).toList();

    return SliverPadding(
      padding: EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final student = filteredStudents[index];
            return _StudentHistoryCard(student: student, index: index)
                .animate()
                .fadeIn(delay: (index * 50).ms)
                .slideY(begin: 0.1);
          },
          childCount: filteredStudents.length,
        ),
      ),
    );
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _HeaderSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _HeaderSummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyDetailCard extends StatelessWidget {
  final AttendanceHistoryRecord record;
  final VoidCallback onTap;
  final Function(AttendanceStatus?) onFilterSelected;
  final AttendanceStatus? currentFilter;

  const _DailyDetailCard({
    required this.record, 
    required this.onTap,
    required this.onFilterSelected,
    this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = record.totalStudents > 0 ? record.totalStudents : 1;
    final rate = (record.presentCount / total * 100).toInt();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    onFilterSelected(null);
                    onTap();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '$rate%',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                intl.DateFormat('yyyy/M/d').format(record.date),
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(PhosphorIconsFill.calendar, size: 20, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: record.presentCount / total,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onFilterSelected(AttendanceStatus.absent),
                        child: _StatusBox(
                          label: l10n.absent,
                          value: record.absentCount.toString(),
                          color: const Color(0xFFEF4444),
                          bgColor: const Color(0xFFFFF1F2),
                          isSelected: currentFilter == AttendanceStatus.absent,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onFilterSelected(AttendanceStatus.present),
                        child: _StatusBox(
                          label: l10n.present,
                          value: record.presentCount.toString(),
                          color: const Color(0xFF10B981),
                          bgColor: const Color(0xFFECFDF5),
                          isSelected: currentFilter == AttendanceStatus.present,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final bool isSelected;

  const _StatusBox({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final AttendanceHistoryEntity classModel;
  final VoidCallback onTap;

  const _ClassCard({required this.classModel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(PhosphorIconsFill.chalkboardTeacher, color: AppColors.primary),
        ),
        title: Text(
          classModel.className,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          AppLocalizations.of(context)!.dailyRecordCount(classModel.dailyRecords.length),
          style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const DirectionalIcon(
          PhosphorIconsRegular.caretRight, 
          size: 20, 
          color: Color(0xFF94A3B8),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StudentHistoryCard extends StatelessWidget {
  final StudentEntity student;
  final int index;

  const _StudentHistoryCard({required this.student, required this.index});

  @override
  Widget build(BuildContext context) {
    final isPresent = student.status == AttendanceStatus.present;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _StudentDetailsModal.show(context, student),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty ? NetworkImage(student.photoUrl!) : null,
                  child: student.photoUrl == null || student.photoUrl!.isEmpty
                      ? Text(student.name.isNotEmpty ? student.name[0] : '?', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primary))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        student.parentName,
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPresent ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPresent ? l10n.present : l10n.absent,
                    style: GoogleFonts.cairo(
                      color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentDetailsModal extends StatelessWidget {
  final StudentEntity student;

  const _StudentDetailsModal({required this.student});

  static void show(BuildContext context, StudentEntity student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentDetailsModal(student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
                ? NetworkImage(student.photoUrl!)
                : null,
            child: (student.photoUrl == null || student.photoUrl!.isEmpty)
                ? Icon(
                    PhosphorIconsRegular.student,
                    size: 40,
                    color: theme.colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            student.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)!.classPlaceholder,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildInfoRow(
            context,
            icon: PhosphorIconsDuotone.user,
            imageUrl: student.parentPhotoUrl,
            label: AppLocalizations.of(context)!.parentGuardian,
            value: student.parentName,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            icon: PhosphorIconsDuotone.phone,
            label: AppLocalizations.of(context)!.parentPhone,
            value: student.parentPhone.isNotEmpty ? student.parentPhone : 'N/A',
            onTap: student.parentPhone.isNotEmpty ? () => _launchCaller(student.parentPhone) : null,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: onTap != null 
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.1))
              : null,
        ),
        child: Row(
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(imageUrl),
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              )
            else
              Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(
                  icon,
                  color: onTap != null 
                      ? AppColors.primary 
                      : (isDark ? Colors.white70 : Colors.black45),
                  size: 24,
                ),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                PhosphorIconsRegular.arrowSquareOut,
                size: 16,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  void _launchCaller(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch caller for $phone');
    }
  }

  void _launchWhatsApp(String phone) async {
    final Uri url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch WhatsApp for $phone');
    }
  }
}

class _EmptyRecordCard extends StatelessWidget {
  final DateTime date;
  const _EmptyRecordCard({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(PhosphorIconsRegular.calendarX, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noRecordsForDate,
              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
