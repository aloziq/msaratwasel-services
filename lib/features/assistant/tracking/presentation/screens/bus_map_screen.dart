import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/brand_colors.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import '../cubit/bus_tracking_cubit.dart';
import '../../domain/entities/bus_position.dart';
import '../widgets/student_marker_widget.dart';

class BusMapScreen extends StatefulWidget {
  const BusMapScreen({super.key});

  @override
  State<BusMapScreen> createState() => _BusMapScreenState();
}

class _BusMapScreenState extends State<BusMapScreen> {
  GoogleMapController? _mapController;
  final Map<String, Marker> _markers = {};
  bool _isDetailsExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        if (mounted) setState(() {});
      }
    } catch (e) {
      // Handle permission error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => BusTrackingCubit()..startTracking(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.busTracking),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.target),
              onPressed: () => _centerMap(),
            ),
          ],
        ),
        body: BlocConsumer<BusTrackingCubit, BusTrackingState>(
          listener: (context, state) {
            if (state is BusTrackingLoaded) {
              _updateMarkers(state.position);
              _centerMap(position: state.position);
            }
          },
          builder: (context, state) {
            // Initialize markers once if state is already Loaded when builder runs
            if (state is BusTrackingLoaded && _markers.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateMarkers(state.position);
              });
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (state is BusTrackingLoaded) {
                        _updateMarkers(state.position);
                        _centerMap(position: state.position);
                      }
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(24.7136, 46.6753),
                      zoom: 14,
                    ),
                    markers: _markers.values.toSet(),
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
                if (state is BusTrackingLoading)
                  const Center(child: CircularProgressIndicator()),
                if (state is BusTrackingLoaded)
                  _buildBottomDetails(context, state.position, l10n),
              ],
            );
          },
        ),
      ),
    );
  }

  void _updateMarkers(BusPosition position) async {
    // Bus Marker
    final busMarker = Marker(
      markerId: const MarkerId('bus_main'),
      position: LatLng(position.lat, position.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(title: position.busId),
    );

    // Mock Student Marker (Restored custom widget)
    final studentMarkerImage =
        await const StudentMarkerWidget(
          name: 'أحمد',
          color: BrandColors.primary,
        ).toBitmapDescriptor(
          logicalSize: const Size(100, 100),
          imageSize: const Size(200, 200),
        );

    final studentMarker = Marker(
      markerId: const MarkerId('student_1'),
      position: LatLng(position.lat + 0.002, position.lng + 0.002),
      icon: studentMarkerImage,
    );

    if (mounted) {
      setState(() {
        _markers['bus'] = busMarker;
        _markers['student_1'] = studentMarker;
      });
    }
  }

  void _centerMap({BusPosition? position}) {
    if (_mapController == null || position == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.lat, position.lng)),
    );
  }

  Widget _buildBottomDetails(
    BuildContext context,
    BusPosition position,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              GestureDetector(
                onTap: () =>
                    setState(() => _isDetailsExpanded = !_isDetailsExpanded),
                child: Container(
                  height: 32,
                  width: double.infinity,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(
                            PhosphorIconsFill.bus,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                position.busId,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'الرياض، حي النرجس',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        _StatusPill(state: position.state, l10n: l10n),
                      ],
                    ),
                    if (_isDetailsExpanded) ...[
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: PhosphorIconsRegular.speedometer,
                            label: 'السرعة',
                            value: '${position.speedKmh.toInt()} كم/س',
                          ),
                          _StatItem(
                            icon: PhosphorIconsRegular.path,
                            label: 'المسافة',
                            value: '${position.distanceKm} كم',
                          ),
                          _StatItem(
                            icon: PhosphorIconsRegular.timer,
                            label: 'المتبقي',
                            value: '${position.etaMinutes} دقيقة',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final BusState state;
  final AppLocalizations l10n;

  const _StatusPill({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (state) {
      case BusState.atStation:
        color = Colors.orange;
        label = 'في المحطة';
        break;
      case BusState.enRoute:
        color = Colors.green;
        label = 'في الطريق';
        break;
      case BusState.arrived:
        color = Colors.blue;
        label = 'وصل';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
