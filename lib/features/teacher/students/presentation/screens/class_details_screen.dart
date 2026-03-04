import 'package:flutter/material.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_button.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import '../../../teacher/domain/entities/classroom_entity.dart';
import '../../domain/entities/student_entity.dart';
import '../cubit/class_details_cubit.dart';
import '../cubit/class_details_state.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';

class ClassDetailsScreen extends StatefulWidget {
  final ClassroomEntity classroom;

  const ClassDetailsScreen({super.key, required this.classroom});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ClassDetailsCubit>().loadStudents(widget.classroom.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          AdaptiveSliverAppBar(
            title: widget.classroom.name,
            leading: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  PhosphorIconsRegular.list,
                  color: theme.colorScheme.onSurface,
                  size: 32,
                ),
                onPressed: () => MainShell.of(context)?.openDrawer(),
              ),
            ),
            trailing: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  PhosphorIconsRegular.qrCode,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
                onPressed: () => context.push(AppRoutes.qrScan),
              ),
            ),
            backgroundColor: theme.scaffoldBackgroundColor.withValues(
              alpha: 0.9,
            ),
          ),
          BlocBuilder<ClassDetailsCubit, ClassDetailsState>(
            builder: (context, state) {
              if (state is ClassDetailsLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (state is ClassDetailsLoaded) {
                return _buildStudentsSliverList(state.students);
              } else if (state is ClassDetailsError) {
                return SliverFillRemaining(
                  child: Center(child: Text(state.message)),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStudentsSliverList(List<StudentEntity> students) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = students[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _StudentCard(student: student)
                .animate()
                .fadeIn(delay: (50 * index).ms)
                .slideX(begin: 0.1, end: 0),
          );
        }, childCount: students.length),
      ),
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.5),
        ),
      ),
      child: SafeArea(
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return PremiumButton(
              text: l10n.finishAttendance,
              icon: PhosphorIconsRegular.paperPlaneRight,
              onTap: () => _showConfirmationDialog(context),
            );
          },
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.read<ClassDetailsCubit>().state;
    if (state is! ClassDetailsLoaded) return;

    final students = state.students;
    final totalCount = students.length;
    final presentCount = students
        .where((s) => s.status == AttendanceStatus.present)
        .length;
    final absentCount = students
        .where((s) => s.status == AttendanceStatus.absent)
        .length;
    final unmarkedCount = students
        .where((s) => s.status == AttendanceStatus.unknown)
        .length;

    showDialog(
      context: context,
      builder: (dialogContext) => _ConfirmationDialog(
        totalCount: totalCount,
        presentCount: presentCount,
        absentCount: absentCount,
        unmarkedCount: unmarkedCount,
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.dailyReportSentSuccess),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        },
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentEntity student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStudentDetails(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'student_${student.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getStatusColor(
                              context,
                              student.status,
                            ).withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(
                                context,
                                student.status,
                              ).withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage: student.photoUrl != null
                              ? NetworkImage(student.photoUrl!)
                              : null,
                          child: student.photoUrl == null
                              ? Icon(
                                  PhosphorIconsRegular.student,
                                  color: isDark
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.user,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                student.parentName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIconsRegular.caretLeft, // RTL Aware
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildAttendanceButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AttendanceButton(
              label: AppLocalizations.of(context)!.present, // Present
              icon: PhosphorIconsFill.checkCircle,
              color: AppColors.successGreen,
              isSelected: student.status == AttendanceStatus.present,
              onTap: () => _updateStatus(context, AttendanceStatus.present),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _AttendanceButton(
              label: AppLocalizations.of(context)!.absent, // Absent
              icon: PhosphorIconsFill.xCircle,
              color: AppColors.dangerRed,
              isSelected: student.status == AttendanceStatus.absent,
              onTap: () => _updateStatus(context, AttendanceStatus.absent),
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, AttendanceStatus status) {
    context.read<ClassDetailsCubit>().markAttendance(
      student.id,
      status,
      'class_id_placeholder',
    );
  }

  void _showStudentDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentDetailsModal(student: student),
    );
  }

  Color _getStatusColor(BuildContext context, AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.successGreen;
      case AttendanceStatus.absent:
        return AppColors.dangerRed;
      default:
        return Colors.grey.withValues(alpha: 0.5);
    }
  }
}

class _AttendanceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _AttendanceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? color
                  : Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentDetailsModal extends StatelessWidget {
  final StudentEntity student;

  const _StudentDetailsModal({required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
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
          Hero(
            tag: 'student_${student.id}',
            child: CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: student.photoUrl != null
                  ? NetworkImage(student.photoUrl!)
                  : null,
              child: student.photoUrl == null
                  ? Icon(
                      PhosphorIconsRegular.student,
                      size: 40,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
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
            AppLocalizations.of(
              context,
            )!.classPlaceholder, // Placeholder class name
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildInfoRow(
            context,
            icon: PhosphorIconsDuotone.user,
            label: AppLocalizations.of(context)!.parentGuardian,
            value: student.parentName,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            icon: PhosphorIconsDuotone.phone,
            label: AppLocalizations.of(context)!.parentPhone,
            value: '050 123 4567',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            icon: PhosphorIconsDuotone.whatsappLogo,
            label: AppLocalizations.of(context)!.whatsapp,
            value: '050 123 4567',
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
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Icon(
              icon,
              color: isDark ? Colors.white70 : AppColors.primary,
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
        ],
      ),
    );
  }
}

class _ConfirmationDialog extends StatelessWidget {
  final int totalCount;
  final int presentCount;
  final int absentCount;
  final int unmarkedCount;
  final VoidCallback onConfirm;

  const _ConfirmationDialog({
    required this.totalCount,
    required this.presentCount,
    required this.absentCount,
    required this.unmarkedCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsFill.clipboardText,
                size: 48,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.attendanceSummary, // Attendance Summary
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.confirmSendReport, // Are you sure?
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: PhosphorIconsDuotone.users,
                    label: l10n.total, // Total
                    value: totalCount.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: PhosphorIconsDuotone.checkCircle,
                    label: l10n.present, // Present
                    value: presentCount.toString(),
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: PhosphorIconsDuotone.xCircle,
                    label: l10n.absent, // Absent
                    value: absentCount.toString(),
                    color: AppColors.dangerRed,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: PhosphorIconsDuotone.question,
                    label: l10n.unmarked, // Unmarked
                    value: unmarkedCount.toString(),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (unmarkedCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.warningCircle,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.unmarkedStudentsWarning(unmarkedCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.cancel, // Cancel
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.confirmSend, // Confirm
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
