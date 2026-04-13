import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';

import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../../domain/entities/report_entity.dart';
import '../../../../../core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import '../../../../../core/presentation/widgets/adaptive_sliver_app_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _searchQuery = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    context.read<ReportsCubit>().loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : AppColors.snowWhite,
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ReportsError) {
            return Center(child: Text(state.message));
          } else if (state is ReportsLoaded) {
            return CustomScrollView(
              slivers: [
                AdaptiveSliverAppBar(
                  title: l10n.reportsTitle,
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
                  backgroundColor: isDark
                      ? theme.scaffoldBackgroundColor
                      : AppColors.snowWhite, // Seamless header
                  stretch: true,
                ),
                _buildSummaryGrid(context, state.stats),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsFill.student,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.studentStatistics,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildSearchBar(context),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
                _buildStudentList(context, state.stats.studentReports),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xl),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, AttendanceStatsEntity stats) {
    final l10n = AppLocalizations.of(context)!;
    return SliverPadding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
      ),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.2, // Made taller to prevent overflow
        children: [
          _SummaryCard(
            title: l10n.totalStudents,
            value: '${stats.totalStudents}',
            icon: PhosphorIconsFill.users,
            color: AppColors.primary,
            index: 0,
          ),
          _SummaryCard(
            title: l10n.attendanceToday,
            value: '${stats.presentToday}',
            icon: PhosphorIconsFill.checkCircle,
            color: Colors.green,
            index: 1,
          ),
          _SummaryCard(
            title: l10n.absenceToday,
            value: '${stats.absentToday}',
            icon: PhosphorIconsFill.xCircle,
            color: Colors.red,
            index: 2,
          ),
          _SummaryCard(
            title: l10n.averageAttendance,
            value: '${stats.averageAttendance.toStringAsFixed(1)}%',
            icon: PhosphorIconsFill.chartLineUp,
            color: Colors.orange,
            index: 3,
          ),
          _SummaryCard(
            title: l10n.unmarkedToday,
            value: '${stats.unmarkedToday}',
            icon: PhosphorIconsFill.warningCircle,
            color: Colors.blueGrey,
            index: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : theme.textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchStudentPlaceholder,
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : theme.hintColor.withValues(alpha: 0.4),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            PhosphorIconsRegular.magnifyingGlass,
            color: isDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildStudentList(
    BuildContext context,
    List<StudentReportEntity> students,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    final filteredStudents = students.where((s) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final matchesName = s.name.toLowerCase().contains(query);
      final matchesCivilId = s.civilId?.toLowerCase().contains(query) ?? false;
      return matchesName || matchesCivilId;
    }).toList();

    if (filteredStudents.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Column(
              children: [
                Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 48,
                  color: theme.disabledColor,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noResultsFound,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = filteredStudents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _StudentAttendanceModal.show(context, student),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    backgroundImage: student.photoUrl != null 
                      ? NetworkImage(student.photoUrl!) 
                      : null,
                    child: student.photoUrl == null 
                      ? Text(
                          student.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
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
                            fontSize: 16,
                          ),
                        ),
                        if (student.civilId != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            "${l10n.civilIdPrefix}: ${student.civilId}",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StatBadge(
                              label: l10n.present,
                              value: "${student.presentCount}",
                              color: AppColors.successGreen,
                              isCompact: true,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _StatBadge(
                              label: l10n.absent,
                              value: "${student.absentCount}",
                              color: AppColors.dangerRed,
                              isCompact: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).animate().fadeIn(delay: 50.ms * index).slideY(begin: 0.1),
          );
        }, childCount: filteredStudents.length),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isCompact;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: $value",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 11 : 13,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -2,
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : color.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8), // Smaller padding
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.15),
                          color.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12), // Slightly smaller radius
                    ),
                    child: Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: Icon(icon, color: color, size: 18),
                    ),
                  ),
                  // Trend indicator removed as per user request for data accuracy
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 26,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4), // Reduced spacing
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // Slightly smaller font
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (100 * index).ms)
        .slideY(begin: 0.1, curve: Curves.easeOutQuad);
  }
}

class _StudentAttendanceModal extends StatefulWidget {
  final StudentReportEntity student;

  const _StudentAttendanceModal({required this.student});

  static void show(BuildContext context, StudentReportEntity student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentAttendanceModal(student: student),
    );
  }

  @override
  State<_StudentAttendanceModal> createState() => _StudentAttendanceModalState();
}

class _StudentAttendanceModalState extends State<_StudentAttendanceModal> {
  DateTime _focusedDay = DateTime.now();
  
  // Mocking markers for presence/absence based on student name to ensure consistent but random-looking data
  bool _isPresent(DateTime day) {
    if (day.isAfter(DateTime.now())) return false;
    if (day.weekday == DateTime.friday || day.weekday == DateTime.saturday) return false;
    
    // Simple deterministic random based on date and student name hash
    final hash = (day.day * 31 + day.month * 7 + widget.student.name.hashCode) % 10;
    return hash > 2; // ~70% attendance
  }

  bool _isAbsent(DateTime day) {
    if (day.isAfter(DateTime.now())) return false;
    if (day.weekday == DateTime.friday || day.weekday == DateTime.saturday) return false;
    return !_isPresent(day);
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
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header Student Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: widget.student.photoUrl != null 
                    ? NetworkImage(widget.student.photoUrl!) 
                    : null,
                  child: widget.student.photoUrl == null 
                    ? const Icon(PhosphorIconsFill.user, color: Colors.white, size: 20)
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.student.name,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Summary Rows
          Row(
            children: [
              Expanded(
                child: _ModalSummaryBox(
                  label: 'أيام الحضور',
                  value: '${widget.student.presentCount}',
                  color: const Color(0xFF10B981),
                  icon: PhosphorIconsFill.checkCircle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModalSummaryBox(
                  label: 'أيام الغياب',
                  value: '${widget.student.absentCount}',
                  color: const Color(0xFFEF4444),
                  icon: PhosphorIconsFill.xCircle,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Calendar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                _buildCalendarHeader(),
                const SizedBox(height: 16),
                _buildCustomCalendar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final languageCode = Localizations.localeOf(context).languageCode;
    final monthName = intl.DateFormat.MMMM(languageCode).format(_focusedDay);
    final year = _focusedDay.year;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0xFF1E293B)),
          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
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
          icon: const Icon(Icons.chevron_left, color: Color(0xFF1E293B)),
          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
        ),
      ],
    );
  }

  Widget _buildCustomCalendar() {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    
    int getColumnIndex(int weekday) {
      if (weekday == DateTime.sunday) return 0;
      if (weekday >= DateTime.monday && weekday <= DateTime.thursday) return weekday;
      return -1;
    }
    
    int firstWorkingDay = 1;
    while (firstWorkingDay <= daysInMonth) {
      DateTime day = DateTime(_focusedDay.year, _focusedDay.month, firstWorkingDay);
      if (getColumnIndex(day.weekday) != -1) break;
      firstWorkingDay++;
    }
    
    int emptyCellsAtStart = 0;
    if (firstWorkingDay <= daysInMonth) {
      emptyCellsAtStart = getColumnIndex(DateTime(_focusedDay.year, _focusedDay.month, firstWorkingDay).weekday);
    }
    
    List<DateTime?> gridDays = List.generate(emptyCellsAtStart, (index) => null);
    for (int i = 1; i <= daysInMonth; i++) {
        DateTime day = DateTime(_focusedDay.year, _focusedDay.month, i);
        if (day.weekday != DateTime.friday && day.weekday != DateTime.saturday) {
          gridDays.add(day);
        }
    }
    
    while (gridDays.length % 5 != 0) {
      gridDays.add(null);
    }

    return Column(
      children: [
        Row(
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
        const SizedBox(height: 12),
        GridView.builder(
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
            
            if (_isPresent(day)) {
              return _buildCalendarDay(day, const Color(0xFF10B981));
            } else if (_isAbsent(day)) {
              return _buildCalendarDay(day, const Color(0xFFEF4444));
            }
            
            return Center(
              child: Text(
                '${day.day}',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF475569),
                  fontSize: 15,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarDay(DateTime day, Color color) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: GoogleFonts.cairo(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalSummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ModalSummaryBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: isDark ? [] : [
           BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
           ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

