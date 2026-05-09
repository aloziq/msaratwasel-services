import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_services/core/presentation/widgets/glass_card.dart';
import 'package:msaratwasel_services/features/driver/route/domain/entities/student_stop.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../cubit/supervisor_tracking_cubit.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';

class SupervisorTrackingScreen extends StatefulWidget {
  final int busId;
  const SupervisorTrackingScreen({super.key, required this.busId});

  @override
  State<SupervisorTrackingScreen> createState() => _SupervisorTrackingScreenState();
}

class _SupervisorTrackingScreenState extends State<SupervisorTrackingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  bool _followBus = true;
  bool _isProgrammaticMove = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SupervisorTrackingCubit(busId: widget.busId)..init(),
      child: Scaffold(
        body: BlocConsumer<SupervisorTrackingCubit, SupervisorTrackingState>(
          listener: (context, state) {
            if (state is SupervisorTrackingLoaded) {
              if (_followBus && state.busPosition != null) {
                _moveCamera(state.busPosition!);
              }
            }
          },
          builder: (context, state) {
            if (state is SupervisorTrackingLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SupervisorTrackingError) {
              return Center(child: Text(state.message));
            }
            if (state is SupervisorTrackingLoaded) {
              final markers = _getMarkers(state);
              final polylines = _getPolylines(state);

              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: state.busPosition ?? state.schoolPosition ?? const LatLng(13.9307, 43.7773),
                      zoom: 15,
                    ),
                    markers: markers,
                    polylines: polylines,
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) {
                      if (!_mapController.isCompleted) {
                        _mapController.complete(controller);
                      }
                    },
                    onCameraMoveStarted: () {
                      if (!_isProgrammaticMove && _followBus) {
                        setState(() {
                          _followBus = false;
                        });
                      }
                    },
                    onCameraIdle: () {
                      _isProgrammaticMove = false;
                    },
                  ),

                  // Top Panel
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: GlassCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'تتبع الحافلة ${state.busNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Text(
                                  state.tripType == 'morning' ? 'رحلة الذهاب (إلى المدرسة)' : 'رحلة العودة (إلى المنزل)',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(PhosphorIconsFill.gauge, color: AppColors.success, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${state.speed.toInt()} كم/س',
                                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Info Panel
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _BottomTrackingInfo(state: state),
                  ),

                  // Floating Buttons
                  Positioned(
                    right: 20,
                    bottom: 220,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          heroTag: 'recenter',
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: () {
                            setState(() {
                              _followBus = !_followBus;
                            });
                            if (_followBus && state.busPosition != null) {
                              _moveCamera(state.busPosition!);
                            }
                          },
                          child: Icon(_followBus ? PhosphorIconsBold.navigationArrow : PhosphorIconsBold.crosshair),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Set<Marker> _getMarkers(SupervisorTrackingLoaded state) {
    final Set<Marker> markers = {};

    // 1. Bus Marker
    if (state.busPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('bus'),
          position: state.busPosition!,
          rotation: state.heading,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'الحافلة ${state.busNumber}',
            snippet: 'السرعة: ${state.speed.toStringAsFixed(1)} كم/س',
          ),
        ),
      );
    }

    // 2. School Marker
    if (state.schoolPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('school'),
          position: state.schoolPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'المدرسة'),
        ),
      );
    }

    // 3. Student Markers (Homes)
    for (StudentStop stop in state.stops) {
      if (stop.location.latitude == 0 || stop.location.longitude == 0) continue;
      
      final isBoarded = state.tripType == 'morning' ? stop.isBoarded : stop.isDroppedOff;
      markers.add(
        Marker(
          markerId: MarkerId('student_${stop.id}'),
          position: stop.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isBoarded ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: stop.nameAr,
            snippet: isBoarded ? 'تم التوصيل' : 'في انتظار التوصيل',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _getPolylines(SupervisorTrackingLoaded state) {
    final Set<Polyline> polylines = {};
    if (state.polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: state.polylinePoints,
          color: AppColors.primary,
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    return polylines;
  }

  Future<void> _moveCamera(LatLng position) async {
    final controller = await _mapController.future;
    _isProgrammaticMove = true;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }
}

class _BottomTrackingInfo extends StatelessWidget {
  final SupervisorTrackingLoaded state;
  const _BottomTrackingInfo({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boardedCount = state.stops.where((s) => state.tripType == 'morning' ? s.isBoarded : s.isDroppedOff).length;
    final totalCount = state.stops.length;

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildStat(
                context,
                icon: PhosphorIconsFill.gauge,
                label: 'السرعة',
                value: '${state.speed.toStringAsFixed(0)} كم/س',
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              _buildStat(
                context,
                icon: PhosphorIconsFill.users,
                label: 'الطلاب',
                value: '$boardedCount/$totalCount',
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStat(
                context,
                icon: PhosphorIconsFill.clockAfternoon,
                label: 'تحديث',
                value: 'الآن',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: totalCount > 0 ? boardedCount / totalCount : 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            boardedCount == totalCount ? 'اكتملت عملية التوصيل' : 'جاري تتبع الرحلة...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
