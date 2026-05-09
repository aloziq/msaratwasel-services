import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:go_router/go_router.dart';

import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

import 'package:msaratwasel_services/core/di/injection.dart';
import '../../domain/entities/fleet_bus.dart';
import '../cubit/fleet_tracking_cubit.dart';

/// Fleet tracking map screen for Field Supervisor.
/// Shows all buses on a Google Map with status-colored markers.
class BusesListScreen extends StatelessWidget {
  const BusesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FleetTrackingCubit>()..loadFleet(),
      child: const _FleetTrackingBody(),
    );
  }
}

class _FleetTrackingBody extends StatefulWidget {
  const _FleetTrackingBody();

  @override
  State<_FleetTrackingBody> createState() => _FleetTrackingBodyState();
}

class _FleetTrackingBodyState extends State<_FleetTrackingBody> {
  GoogleMapController? _mapController;
  final Map<String, BitmapDescriptor> _busIcons = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: SupervisorDrawer(
        currentIndex: 1,
        onSelect: (index) => handleSupervisorNavigation(context, index, 1),
      ),
      body: BlocBuilder<FleetTrackingCubit, FleetTrackingState>(
        builder: (context, state) {
          if (state is FleetTrackingLoading || state is FleetTrackingInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FleetTrackingError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as FleetTrackingLoaded;
          final buses = loaded.buses;

          return Stack(
            children: [
              // ── Google Map ──
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(23.5880, 58.3829), // Muscat center
                    zoom: 12,
                  ),
                  markers: _buildMarkers(buses, context),
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (_) =>
                      context.read<FleetTrackingCubit>().clearSelection(),
                ),
              ),

              // ── Top bar: Back + Title ──
              Positioned(
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: Row(
                  children: [
                    _CircleAction(
                      icon: Icons.menu_rounded,
                      isDark: isDark,
                      onTap: () => Scaffold.of(context).openDrawer(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm + 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.busTracking,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CircleAction(
                      icon: Icons.my_location_rounded,
                      isDark: isDark,
                      onTap: () => _fitAllBuses(buses),
                    ),
                  ],
                ),
              ),

              // ── Stats chips ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 64,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: _StatsRow(loaded: loaded, l10n: l10n, isDark: isDark),
              ),

              // ── Selected bus bottom sheet ──
              if (loaded.selectedBus != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _BusDetailSheet(
                    bus: loaded.selectedBus!,
                    l10n: l10n,
                    isDark: isDark,
                    onClose: () =>
                        context.read<FleetTrackingCubit>().clearSelection(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadBusIcons(List<FleetBus> buses) async {
    for (final bus in buses) {
      if (_busIcons.containsKey(bus.id)) continue;
      final color = switch (bus.status) {
        FleetBusStatus.active => const Color(0xFF16A34A),
        FleetBusStatus.stopped => const Color(0xFFF59E0B),
        FleetBusStatus.maintenance => const Color(0xFFEF4444),
      };
      try {
        final icon = await _BusMarkerWidget(color: color).toBitmapDescriptor(
          logicalSize: const Size(48, 48),
          imageSize: const Size(96, 96),
        );
        _busIcons[bus.id] = icon;
      } catch (_) {
        _busIcons[bus.id] = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        );
      }
    }
    if (mounted) setState(() {});
  }

  Set<Marker> _buildMarkers(List<FleetBus> buses, BuildContext context) {
    // Trigger icon loading if not yet loaded
    if (_busIcons.isEmpty && buses.isNotEmpty) {
      _loadBusIcons(buses);
    }

    return buses.map((bus) {
      return Marker(
        markerId: MarkerId(bus.id),
        position: LatLng(bus.lat, bus.lng),
        icon: _busIcons[bus.id] ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: bus.name,
          snippet: '${bus.driverName} • ${bus.speedKmh.toInt()} km/h',
        ),
        onTap: () {
          context.read<FleetTrackingCubit>().selectBus(bus.id);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(bus.lat, bus.lng), 14),
          );
        },
      );
    }).toSet();
  }

  void _fitAllBuses(List<FleetBus> buses) {
    if (buses.isEmpty || _mapController == null) return;

    double minLat = buses.first.lat, maxLat = buses.first.lat;
    double minLng = buses.first.lng, maxLng = buses.first.lng;

    for (final bus in buses) {
      if (bus.lat < minLat) minLat = bus.lat;
      if (bus.lat > maxLat) maxLat = bus.lat;
      if (bus.lng < minLng) minLng = bus.lng;
      if (bus.lng > maxLng) maxLng = bus.lng;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.loaded,
    required this.l10n,
    required this.isDark,
  });

  final FleetTrackingLoaded loaded;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          label: l10n.totalBuses,
          value: '${loaded.buses.length}',
          color: AppColors.primary,
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          label: l10n.activeBuses,
          value: '${loaded.activeCount}',
          color: AppColors.success,
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          label: l10n.stoppedBuses,
          value: '${loaded.stoppedCount}',
          color: AppColors.warningOrange,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusDetailSheet extends StatelessWidget {
  const _BusDetailSheet({
    required this.bus,
    required this.l10n,
    required this.isDark,
    required this.onClose,
  });

  final FleetBus bus;
  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final statusColor = switch (bus.status) {
      FleetBusStatus.active => AppColors.success,
      FleetBusStatus.stopped => AppColors.warningOrange,
      FleetBusStatus.maintenance => AppColors.error,
    };
    final statusLabel = switch (bus.status) {
      FleetBusStatus.active => l10n.activeBuses,
      FleetBusStatus.stopped => l10n.stoppedBuses,
      FleetBusStatus.maintenance => l10n.stoppedBuses,
    };

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.lg + bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header: Bus name + status + close
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Info rows
            _InfoRow(
              icon: Icons.person_rounded,
              label: 'السائق',
              value: bus.driverName,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.woman_rounded,
              label: 'المشرفة',
              value: bus.supervisorName,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.confirmation_number_rounded,
              label: 'رقم الحافلة',
              value: bus.id,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.school_rounded,
              label: 'المدرسة',
              value: bus.schoolName,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                context.push(AppRoutes.supervisorTrackingPath(bus.id));
              },
              icon: const Icon(Icons.location_on_rounded),
              label: const Text('تتبع الحافلة الآن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

/// Custom marker widget rendered as a bitmap for Google Maps.
/// Shows a bus icon inside a colored circle.
class _BusMarkerWidget extends StatelessWidget {
  const _BusMarkerWidget({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_bus_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}
