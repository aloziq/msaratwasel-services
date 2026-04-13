import 'package:flutter/material.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/data/field_supervisor_remote_datasource.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

enum FieldTripStatus { scheduled, planning, completed }

/// Screen for managing field trips.
class FieldTripsScreen extends StatefulWidget {
  const FieldTripsScreen({super.key});

  @override
  State<FieldTripsScreen> createState() => _FieldTripsScreenState();
}

class _FieldTripsScreenState extends State<FieldTripsScreen> {
  List<_FieldTripData> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await FieldSupervisorRemoteDataSource.getFieldTrips();

    if (mounted) {
      setState(() {
        _trips = data.map<_FieldTripData>((d) {
          return _FieldTripData(
            d['trip_name'] ?? '',
            DateTime.tryParse(d['trip_date'] ?? '') ?? DateTime.now(),
            d['school'] ?? 'N/A',
            d['bus_code'] ?? 'N/A',
            _mapStatus(d['status']),
            destination: d['destination'] ?? '',
            students: d['students'] ?? 0,
          );
        }).toList();
        _isLoading = false;
      });
    }
  }

  FieldTripStatus _mapStatus(String? status) {
    switch (status) {
      case 'approved': return FieldTripStatus.scheduled;
      case 'completed': return FieldTripStatus.completed;
      default: return FieldTripStatus.planning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: SupervisorDrawer(
        currentIndex: 7,
        onSelect: (index) => handleSupervisorNavigation(context, index, 7),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    AppSliverHeader(
                      title: l10n.fieldTrips,
                      showMenu: true,
                    ),

                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981),
                              const Color(0xFF10B981).withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.upcomingTrips,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_trips.where((t) => t.status != FieldTripStatus.completed).length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.explore,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_trips.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                Icon(Icons.explore_off, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                Text('لا توجد رحلات ميدانية', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final trip = _trips[index];
                          final statusColor = trip.status == FieldTripStatus.completed
                              ? const Color(0xFF16A34A)
                              : trip.status == FieldTripStatus.scheduled
                              ? AppColors.primary
                              : const Color(0xFFF59E0B);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.explore,
                                        color: Color(0xFF10B981),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            trip.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${trip.date.day}/${trip.date.month}/${trip.date.year}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white54 : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        trip.statusLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (trip.destination.isNotEmpty)
                                      Expanded(
                                        child: Text(
                                          '📍 ${trip.destination}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    Text(
                                      '${l10n.bus}: ${trip.busId}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                                      ),
                                    ),
                                    if (trip.students > 0) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        '👥 ${trip.students}',
                                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        }, childCount: _trips.length),
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FieldTripData {
  final String name;
  final DateTime date;
  final String school;
  final String busId;
  final FieldTripStatus status;
  final String destination;
  final int students;

  _FieldTripData(this.name, this.date, this.school, this.busId, this.status, {this.destination = '', this.students = 0});

  String get statusLabel => switch (status) {
    FieldTripStatus.scheduled => 'مجدولة',
    FieldTripStatus.planning => 'قيد التخطيط',
    FieldTripStatus.completed => 'مكتملة',
  };
}
