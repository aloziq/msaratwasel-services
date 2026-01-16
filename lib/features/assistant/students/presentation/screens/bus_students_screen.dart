import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import '../../../core/domain/entities/bus_student_entity.dart';
import '../../../core/presentation/cubit/bus_trip_cubit.dart';

class BusStudentsScreen extends StatefulWidget {
  const BusStudentsScreen({super.key});

  @override
  State<BusStudentsScreen> createState() => _BusStudentsScreenState();
}

class _BusStudentsScreenState extends State<BusStudentsScreen> {
  String _searchQuery = '';
  BusStudentStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<BusTripCubit, BusTripState>(
        builder: (context, state) {
          if (state is BusTripLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BusTripError) {
            return Center(child: Text(state.message));
          }

          if (state is BusTripLoaded) {
            final filteredStudents = state.trip.students.where((student) {
              final matchesSearch =
                  student.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  student.schoolId.contains(_searchQuery);
              final matchesStatus =
                  _selectedStatus == null || student.status == _selectedStatus;
              return matchesSearch && matchesStatus;
            }).toList();

            return CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  leading: const BackButton(),
                  largeTitle: Text(
                    l10n.studentsList,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontFamily: theme.textTheme.titleLarge?.fontFamily,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  border: null,
                  stretch: true,
                ),
                SliverToBoxAdapter(
                  child: _buildTripSummary(context, state.trip),
                ),
                SliverToBoxAdapter(
                  child: _buildSearchAndFilter(context, isDark),
                ),
                if (filteredStudents.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('لا يوجد طلاب يطابقون البحث')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final student = filteredStudents[index];
                        return _StudentCard(student: student)
                            .animate()
                            .fadeIn(delay: (index * 50).ms)
                            .slideX(begin: 0.1);
                      }, childCount: filteredStudents.length),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            onTapOutside: (event) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, l10n.all),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(BusStudentStatus.atHome, l10n.atHome),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(BusStudentStatus.onBus, l10n.onBus),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(BusStudentStatus.atSchool, l10n.atSchool),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(BusStudentStatus.absent, l10n.absent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BusStudentStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTripSummary(BuildContext context, dynamic trip) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final total = trip.students.length;
    final atSchool = trip.students
        .where((s) => s.status == BusStudentStatus.atSchool)
        .length;
    final onBus = trip.students
        .where((s) => s.status == BusStudentStatus.onBus)
        .length;
    final progress = total > 0 ? atSchool / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tripProgress,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.deliveredStudentsCount(atSchool, total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.bus,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatInfo(l10n.onBus, onBus.toString()),
              _buildStatInfo(
                l10n.remaining,
                (total - atSchool - onBus).toString(),
              ),
              _buildStatInfo(
                l10n.percentage,
                '${(progress * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Removed _SummaryItem since it's replaced by a better layout in _buildTripSummary

class _StudentCard extends StatelessWidget {
  final BusStudentEntity student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(student.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      backgroundImage: student.photoUrl != null
                          ? NetworkImage(student.photoUrl!)
                          : null,
                      child: student.photoUrl == null
                          ? Icon(PhosphorIconsRegular.user, color: statusColor)
                          : null,
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
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.graduationCap,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              student.grade,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              PhosphorIconsRegular.identificationCard,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              student.schoolId,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: student.status),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey.withValues(alpha: 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildIconButton(
                        context,
                        PhosphorIconsFill.phone,
                        Colors.green,
                        () {},
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(
                        context,
                        PhosphorIconsFill.chatCircleText,
                        Colors.blue,
                        () => context.push(
                          AppRoutes.messages,
                          extra: 'ولي أمر ${student.name}',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildActionButton(context),
                      const SizedBox(width: 4),
                      _buildMoreButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (student.status == BusStudentStatus.atSchool) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(
              PhosphorIconsFill.checkCircle,
              color: Colors.green,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.arrivedSafely,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final isAtHome = student.status == BusStudentStatus.atHome;
    final color = isAtHome ? Colors.orange : Colors.green;
    final label = isAtHome ? l10n.boardedBus : l10n.reachedSchool;
    final icon = isAtHome ? PhosphorIconsFill.bus : PhosphorIconsFill.buildings;
    final nextStatus = isAtHome
        ? BusStudentStatus.onBus
        : BusStudentStatus.atSchool;

    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 36),
      ),
      onPressed: () => context.read<BusTripCubit>().updateStudentStatus(
        student.id,
        nextStatus,
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<BusStudentStatus>(
      icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (status) {
        context.read<BusTripCubit>().updateStudentStatus(student.id, status);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: BusStudentStatus.atHome, child: Text(l10n.atHome)),
        PopupMenuItem(value: BusStudentStatus.onBus, child: Text(l10n.onBus)),
        PopupMenuItem(
          value: BusStudentStatus.atSchool,
          child: Text(l10n.atSchool),
        ),
        PopupMenuItem(value: BusStudentStatus.absent, child: Text(l10n.absent)),
      ],
    );
  }

  Color _getStatusColor(BusStudentStatus status) {
    switch (status) {
      case BusStudentStatus.atHome:
        return Colors.blue;
      case BusStudentStatus.onBus:
        return Colors.orange;
      case BusStudentStatus.atSchool:
        return Colors.green;
      case BusStudentStatus.absent:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final BusStudentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BusStudentStatus.atHome:
        color = Colors.blue;
        break;
      case BusStudentStatus.onBus:
        color = Colors.orange;
        break;
      case BusStudentStatus.atSchool:
        color = Colors.green;
        break;
      case BusStudentStatus.absent:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(context, status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(BuildContext context, BusStudentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case BusStudentStatus.atHome:
        return l10n.atHome;
      case BusStudentStatus.onBus:
        return l10n.onBus;
      case BusStudentStatus.atSchool:
        return l10n.atSchool;
      case BusStudentStatus.absent:
        return l10n.absent;
      default:
        return '';
    }
  }
}
