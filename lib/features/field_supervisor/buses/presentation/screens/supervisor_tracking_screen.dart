import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:msaratwasel_services/features/driver/route/domain/entities/student_stop.dart';
import '../cubit/supervisor_tracking_cubit.dart';

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
  bool _isMapMode = true; // Switch between Map mode and Student List mode
  final Map<String, BitmapDescriptor> _customMarkers = {};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadCustomMarkers(SupervisorTrackingLoaded state) async {
    final newMarkers = <String, BitmapDescriptor>{};

    // 1. Load Bus Marker
    try {
      final busMarker = await const BusMarkerWidget().toBitmapDescriptor(
        logicalSize: const Size(100, 100),
        imageSize: const Size(200, 200),
      );
      newMarkers['bus'] = busMarker;
    } catch (_) {}

    // 2. Load Student Number Markers
    int stopNum = 1;
    for (var stop in state.stops) {
      if (stop.location.latitude == 0 || stop.location.longitude == 0) continue;
      final isBoarded = state.tripType == 'morning' ? stop.isBoarded : stop.isDroppedOff;
      try {
        final marker = await StudentNumberMarkerWidget(
          index: stopNum,
          isCompleted: isBoarded,
        ).toBitmapDescriptor(
          logicalSize: const Size(80, 100),
          imageSize: const Size(160, 200),
        );
        newMarkers['student_${stop.id}'] = marker;
        stopNum++;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _customMarkers.clear();
        _customMarkers.addAll(newMarkers);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SupervisorTrackingCubit(busId: widget.busId)..init(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: BlocConsumer<SupervisorTrackingCubit, SupervisorTrackingState>(
          listener: (context, state) {
            if (state is SupervisorTrackingLoaded) {
              if (_followBus && state.busPosition != null) {
                _moveCamera(state.busPosition!);
              }
              if (_customMarkers.isEmpty) {
                _loadCustomMarkers(state);
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

              // Next Stop Name and ETA
              String nextStopName = '';
              if (state.tripType == 'morning') {
                try {
                  final nextStop = state.stops.firstWhere((s) => !s.isBoarded && !s.isAbsent);
                  nextStopName = nextStop.nameAr;
                } catch (_) {
                  nextStopName = 'المدرسة';
                }
              } else {
                try {
                  final nextStop = state.stops.firstWhere((s) => !s.isDroppedOff && !s.isAbsent);
                  nextStopName = nextStop.nameAr;
                } catch (_) {
                  nextStopName = 'المستودع/المنزل';
                }
              }

              final remaining = state.stops.where((s) => state.tripType == 'morning' ? (!s.isBoarded && !s.isAbsent) : (!s.isDroppedOff && !s.isAbsent)).length;
              final etaText = remaining == 0 ? 'وصلت الحافلة' : 'على بعد ${remaining * 3} دقائق';

              return Stack(
                children: [
                  // 1. Map View (Only visible in Map Mode)
                  Positioned.fill(
                    child: Opacity(
                      opacity: _isMapMode ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !_isMapMode,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: state.busPosition ?? state.schoolPosition ?? const LatLng(13.9307, 43.7773),
                            zoom: 15,
                          ),
                          markers: markers,
                          polylines: polylines,
                          myLocationEnabled: true,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
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
                      ),
                    ),
                  ),

                  // 2. Custom Speech Bubble over the bus (visible when following bus in Map Mode)
                  if (_isMapMode && _followBus && state.busPosition != null)
                    Align(
                      alignment: const Alignment(0, -0.22),
                      child: SpeechBubble(
                        title: 'النقطة القادمة',
                        description: nextStopName,
                        time: etaText,
                      ),
                    ),

                  // 3. Floating Compass (Top Left, Map Mode only)
                  if (_isMapMode)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 60,
                      left: 16,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.explore_outlined,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                      ),
                    ),

                  // 4. Floating Center Location (Top Right, Map Mode only)
                  if (_isMapMode)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 60,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _followBus = true;
                          });
                          if (state.busPosition != null) {
                            _moveCamera(state.busPosition!);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _followBus ? Icons.my_location_rounded : Icons.location_searching_rounded,
                              color: _followBus ? const Color(0xFF1A73E8) : Colors.black87,
                              size: 22,
                            ),
                          ),
                        ),
                      ),

                  // 5. Floating Top Row (Always visible)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Reload pill button
                        GestureDetector(
                          onTap: () {
                            context.read<SupervisorTrackingCubit>().init();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sync_rounded, size: 16, color: Colors.black87),
                                SizedBox(width: 4),
                                Text(
                                  'آخر تحديث 1 دقيقة',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Back Button & Status
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'في الطريق',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 6. Student Attendance List Mode overlay
                  if (!_isMapMode)
                    Positioned.fill(
                      bottom: 180 + MediaQuery.of(context).padding.bottom,
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 70, 20, 10),
                              child: const Text(
                                'حالة حضور الطلاب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: state.stops.length,
                                separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey[100]),
                                itemBuilder: (context, index) {
                                  final stop = state.stops[index];
                                  final isBoarded = state.tripType == 'morning' ? stop.isBoarded : stop.isDroppedOff;

                                  Color statusColor = const Color(0xFF1A73E8);
                                  String statusText = 'انتظار';
                                  if (stop.isAbsent) {
                                    statusColor = const Color(0xFFF44336);
                                    statusText = 'غائب';
                                  } else if (isBoarded) {
                                    statusColor = const Color(0xFF4CAF50);
                                    statusText = state.tripType == 'morning' ? 'تم الركوب' : 'تم النزول';
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: statusColor.withValues(alpha: 0.1),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                stop.nameAr,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                stop.isAbsent ? 'مسجل كغائب' : (isBoarded ? 'تم بنجاح' : 'في الانتظار حالياً'),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 7. Compact Bottom Details & Spacing Panel
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _BottomTrackingInfo(
                      state: state,
                      isMapMode: _isMapMode,
                      onToggleMode: () {
                        setState(() {
                          _isMapMode = !_isMapMode;
                        });
                      },
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
          icon: _customMarkers['bus'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
          icon: _customMarkers['student_${stop.id}'] ??
              BitmapDescriptor.defaultMarkerWithHue(
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
          color: const Color(0xFF1A73E8), // Vibrant Google Blue
          width: 5,
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

// ─────────────────────────────────────────────────────────────────────────────
// Custom UI Component Widgets
// ─────────────────────────────────────────────────────────────────────────────

class SpeechBubble extends StatelessWidget {
  final String title;
  final String description;
  final String time;

  const SpeechBubble({
    super.key,
    required this.title,
    required this.description,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A73E8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        ClipPath(
          clipper: TriangleClipper(),
          child: Container(
            color: Colors.white,
            width: 16,
            height: 8,
          ),
        ),
      ],
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class StudentNumberMarkerWidget extends StatelessWidget {
  final int index;
  final bool isCompleted;

  const StudentNumberMarkerWidget({
    super.key,
    required this.index,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 10,
            child: Icon(
              Icons.location_on,
              size: 70,
              color: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFF1A73E8),
            ),
          ),
          Positioned(
            top: 15,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_filled,
                size: 20,
                color: Color(0xFF1A73E8),
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFF1A73E8),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BusMarkerWidget extends StatelessWidget {
  const BusMarkerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF1A73E8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomTrackingInfo extends StatelessWidget {
  final SupervisorTrackingLoaded state;
  final bool isMapMode;
  final VoidCallback onToggleMode;

  const _BottomTrackingInfo({
    required this.state,
    required this.isMapMode,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    final remainingCount = state.stops.where((s) => state.tripType == 'morning' ? (!s.isBoarded && !s.isAbsent) : (!s.isDroppedOff && !s.isAbsent)).length;
    final boardedCount = state.stops.where((s) => s.isBoarded).length;
    final absentCount = state.stops.where((s) => s.isAbsent).length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF1A73E8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الحافلة ${state.busNumber}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'تتبع مباشر للرحلة',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: _buildStatItem(
                    icon: Icons.group_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    label: 'المتبقي',
                    value: '$remainingCount',
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: _buildStatItem(
                    icon: Icons.directions_bus_rounded,
                    iconColor: const Color(0xFF1A73E8),
                    label: 'في الحافلة',
                    value: '$boardedCount',
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: _buildStatItem(
                    icon: Icons.notifications_off_rounded,
                    iconColor: const Color(0xFFF44336),
                    label: 'الغياب',
                    value: '$absentCount',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Divider(height: 1, color: Colors.grey[200]),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!isMapMode) onToggleMode();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isMapMode ? const Color(0xFF1A73E8).withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.route_outlined,
                            color: isMapMode ? const Color(0xFF1A73E8) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'المسار',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isMapMode ? const Color(0xFF1A73E8) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (isMapMode) onToggleMode();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isMapMode ? const Color(0xFF1A73E8).withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_list_bulleted_rounded,
                            color: !isMapMode ? const Color(0xFF1A73E8) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'قائمة الطلاب',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: !isMapMode ? const Color(0xFF1A73E8) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
