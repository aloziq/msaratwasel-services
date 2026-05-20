import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

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

class _TripHistoryCard extends StatelessWidget {
  final TripHistoryModel trip;

  const _TripHistoryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return InkWell(
      onTap: () {
        // TODO: Implement trip details navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'سيتم إضافة التفاصيل قريباً' : 'Details coming soon',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isArabic ? trip.typeLabel : (trip.type == 'forth' || trip.typeLabel == 'ذهاب' ? 'Go' : 'Return'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    trip.tripDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                trip.route?.name != null
                    ? (isArabic
                        ? trip.route!.name
                        : trip.route!.name
                            .replaceAll('المسار رقم', 'Route No.')
                            .replaceAll('مسار رقم', 'Route No.')
                            .replaceAll('مسار', 'Route'))
                    : (isArabic ? 'بدون مسار' : 'No Route'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.users,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${trip.totalStudents} ${AppLocalizations.of(context)!.totalStudents}",
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  _StatusBadge(status: trip.status),
                ],
              ),
              if (trip.departureTime != null || trip.arrivalTime != null) ...[
                const Divider(height: AppSpacing.lg),
                Row(
                  children: [
                    if (trip.departureTime != null)
                      Expanded(
                        child: _TimeInfo(
                          label: isArabic ? 'وقت الانطلاق' : 'Departure',
                          time: _formatTime(trip.departureTime!),
                        ),
                      ),
                    if (trip.departureTime != null && trip.arrivalTime != null)
                      const SizedBox(width: AppSpacing.md),
                    if (trip.arrivalTime != null)
                      Expanded(
                        child: _TimeInfo(
                          label: isArabic ? 'وقت الوصول' : 'Arrival',
                          time: _formatTime(trip.arrivalTime!),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      if (timeStr.contains('T')) {
        final dateTime = DateTime.parse(timeStr).toLocal();
        return DateFormat('hh:mm a').format(dateTime);
      }
      return timeStr;
    } catch (e) {
      return timeStr;
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
    final color = isCompleted ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isCompleted ? 'مكتملة' : 'قيد المعالجة',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        Text(
          time,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
