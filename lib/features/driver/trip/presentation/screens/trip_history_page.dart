import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:msaratwasel_services/core/presentation/widgets/custom_menu_button.dart';

import 'package:msaratwasel_services/config/theme/app_spacing.dart';

import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/manager/trip_history_cubit.dart';
import 'package:msaratwasel_services/features/driver/trip/data/models/trip_history_model.dart';
import 'package:msaratwasel_services/features/driver/trip/domain/repositories/trip_history_repository.dart';
import 'package:msaratwasel_services/features/driver/trip/data/datasources/trip_history_remote_datasource.dart';

class TripHistoryPage extends StatelessWidget {
  const TripHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripHistoryCubit(
        TripHistoryRepositoryImpl(
          TripHistoryRemoteDataSourceImpl(ApiClient.instance),
        ),
      )..loadTrips(),
      child: const TripHistoryView(),
    );
  }
}

class TripHistoryView extends StatefulWidget {
  const TripHistoryView({super.key});

  @override
  State<TripHistoryView> createState() => _TripHistoryViewState();
}

class _TripHistoryViewState extends State<TripHistoryView> {
  String? _statusFilter;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trips),
        leading: const CustomMenuButton(),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.funnel),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<TripHistoryCubit, TripHistoryState>(
        builder: (context, state) {
          if (state is TripHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TripHistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<TripHistoryCubit>().loadTrips(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (state is TripHistoryLoaded) {
            final trips = state.response.trips;

            if (trips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIconsRegular.calendarBlank,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.noDataFound),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: trips.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _TripHistoryCard(trip: trip);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final cubit = context.read<TripHistoryCubit>();
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.filter,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _statusFilter = null;
                            _dateRange = null;
                          });
                        },
                        child: Text(l10n.clearFilter),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.status),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      _FilterChip(
                        label: l10n.statusCompleted,
                        isSelected: _statusFilter == 'completed',
                        onSelected: (selected) {
                          setModalState(
                            () => _statusFilter = selected ? 'completed' : null,
                          );
                        },
                      ),
                      _FilterChip(
                        label: l10n.statusInProgress,
                        isSelected: _statusFilter == 'in_progress',
                        onSelected: (selected) {
                          setModalState(
                            () =>
                                _statusFilter = selected ? 'in_progress' : null,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.date),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateRange,
                      );
                      if (picked != null) {
                        setModalState(() => _dateRange = picked);
                      }
                    },
                    leading: const Icon(PhosphorIconsRegular.calendar),
                    title: Text(
                      _dateRange == null
                          ? l10n.searchByDate
                          : "${DateFormat('yyyy-MM-dd').format(_dateRange!.start)} - ${DateFormat('yyyy-MM-dd').format(_dateRange!.end)}",
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        cubit.filterTrips(
                          startDate: _dateRange?.start.toIso8601String().split(
                            'T',
                          )[0],
                          endDate: _dateRange?.end.toIso8601String().split(
                            'T',
                          )[0],
                          status: _statusFilter,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(l10n.confirm),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}

String getLocalizedType(String type, String typeLabel, bool isArabic) {
  if (isArabic) {
    if (type == 'forth' || typeLabel == 'ذهاب' || typeLabel.toLowerCase() == 'go' || typeLabel.toLowerCase() == 'forth') {
      return 'ذهاب';
    } else {
      return 'إياب';
    }
  } else {
    if (type == 'forth' || typeLabel == 'ذهاب' || typeLabel.toLowerCase() == 'go' || typeLabel.toLowerCase() == 'forth') {
      return 'Go';
    } else {
      return 'Return';
    }
  }
}

String getLocalizedRouteName(String? name, bool isArabic) {
  if (name == null) {
    return isArabic ? 'بدون مسار' : 'No Route';
  }
  if (isArabic) {
    return name
        .replaceAll(RegExp(r'Route\s+No\.?\s*', caseSensitive: false), 'المسار رقم ')
        .replaceAll(RegExp(r'Route\s*', caseSensitive: false), 'مسار ')
        .replaceAll(RegExp(r'No\.?\s*', caseSensitive: false), 'رقم ');
  } else {
    return name
        .replaceAll('المسار رقم', 'Route No.')
        .replaceAll('مسار رقم', 'Route No.')
        .replaceAll('مسار', 'Route');
  }
}

class _TripHistoryCard extends StatelessWidget {
  final TripHistoryModel trip;

  const _TripHistoryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isCompleted = trip.status == 'completed' || trip.status == 'finished';
    final statusColor = isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    final typeLabelText = getLocalizedType(trip.type, trip.typeLabel, isArabic);
    final isGo = trip.type == 'forth' || trip.typeLabel == 'ذهاب' || trip.typeLabel.toLowerCase() == 'go' || trip.typeLabel.toLowerCase() == 'forth';
    final typeColor = isGo ? const Color(0xFF2563EB) : const Color(0xFF8B5CF6);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF1E293B) : Colors.white,
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isArabic ? 'سيتم إضافة التفاصيل قريباً' : 'Details coming soon',
                  ),
                ),
              );
            },
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Side status indicator strip
                  Container(
                    width: 6,
                    color: statusColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Type Badge & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Type Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: typeColor.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isGo ? PhosphorIconsFill.student : PhosphorIconsFill.houseLine,
                                      size: 14,
                                      color: typeColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      typeLabelText,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: typeColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Date
                              Row(
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.calendarBlank,
                                    size: 14,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    trip.tripDate,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Route Name
                          Text(
                            getLocalizedRouteName(trip.route?.name, isArabic),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Students & Status Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      PhosphorIconsRegular.users,
                                      size: 14,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${trip.totalStudents} ${AppLocalizations.of(context)!.totalStudents}",
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _StatusBadge(status: trip.status),
                            ],
                          ),
                          if (trip.departureTime != null || trip.arrivalTime != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            // Modern clean divider
                            Divider(
                              height: 1,
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                if (trip.departureTime != null)
                                  Expanded(
                                    child: _TimeInfo(
                                      label: isArabic ? 'وقت الانطلاق' : 'Departure',
                                      time: _formatTime(trip.departureTime!, isArabic),
                                    ),
                                  ),
                                if (trip.departureTime != null && trip.arrivalTime != null)
                                  const SizedBox(width: AppSpacing.md),
                                if (trip.arrivalTime != null)
                                  Expanded(
                                    child: _TimeInfo(
                                      label: isArabic ? 'وقت الوصول' : 'Arrival',
                                      time: _formatTime(trip.arrivalTime!, isArabic),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String timeStr, bool isArabic) {
    try {
      DateTime dateTime;
      if (timeStr.contains('T')) {
        dateTime = DateTime.parse(timeStr).toLocal();
      } else {
        final parts = timeStr.split(':');
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final now = DateTime.now();
        dateTime = DateTime(now.year, now.month, now.day, hours, minutes);
      }
      final timeFormat = DateFormat('hh:mm');
      final timeOnly = timeFormat.format(dateTime);
      final amPm = DateFormat('a').format(dateTime); // "AM" or "PM"
      if (isArabic) {
        final amPmAr = amPm == 'AM' ? 'ص' : 'م';
        return '$timeOnly $amPmAr';
      } else {
        return '$timeOnly $amPm';
      }
    } catch (e) {
      String result = timeStr;
      if (isArabic) {
        result = result.replaceAll('PM', 'م').replaceAll('AM', 'ص');
      }
      return result;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = status == 'completed' || status == 'finished';
    final color = isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.clock,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isCompleted ? 'مكتملة' : 'قيد المعالجة',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label;
  final String time;

  const _TimeInfo({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsRegular.clock,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
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
