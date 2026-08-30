import 'dart:async';
import 'package:flutter/material.dart';
import 'package:msaratwasel_services/core/presentation/widgets/directional_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:msaratwasel_services/features/driver/route/domain/entities/student_stop.dart';
import 'package:msaratwasel_services/core/responsive/adaptive_list_view.dart';
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
  bool _isFirstLock = true;
  final Map<String, BitmapDescriptor> _customMarkers = {};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadCustomMarkers(SupervisorTrackingLoaded state) async {
    bool hasChanges = false;

    // 1. Load Bus Marker
    if (!_customMarkers.containsKey('bus')) {
      try {
        final busMarker = await const BusMarkerWidget().toBitmapDescriptor(
          logicalSize: const Size(100, 100),
          imageSize: const Size(200, 200),
        );
        _customMarkers['bus'] = busMarker;
        hasChanges = true;
      } catch (_) {}
    }

    // 2. Load Student Number Markers
    int stopNum = 1;
    for (var stop in state.stops) {
      if (stop.location.latitude == 0 || stop.location.longitude == 0) continue;
      final isBoarded = state.tripType == 'morning' ? stop.isBoarded : stop.isDroppedOff;
      final cacheKey = 'student_${stop.id}_${isBoarded}_${stop.isAbsent}';

      if (!_customMarkers.containsKey(cacheKey)) {
        try {
          final marker = await StudentNumberMarkerWidget(
            index: stopNum,
            isCompleted: isBoarded,
            isAbsent: stop.isAbsent,
          ).toBitmapDescriptor(
            logicalSize: const Size(80, 100),
            imageSize: const Size(160, 200),
          );
          _customMarkers[cacheKey] = marker;
          hasChanges = true;
        } catch (_) {}
      }
      stopNum++;
    }

    if (hasChanges && mounted) {
      setState(() {});
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
              if (state.busPosition != null) {
                if (_isFirstLock) {
                  _isFirstLock = false;
                  _moveCamera(state.busPosition!, zoom: 16.0);
                } else if (_followBus) {
                  _moveCamera(state.busPosition!);
                }
              }
              _loadCustomMarkers(state);
            }
          },
          builder: (context, state) {
            if (state is SupervisorTrackingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SupervisorTrackingError) {
              return Scaffold(
                backgroundColor: Colors.grey[50],
                body: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade800,
                                size: 56,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'تنبيه الصلاحية والمتابعة',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Outfit',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A73E8).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.1)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'جاري محاولة الاتصال تلقائياً...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A73E8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_back, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'رجوع',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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

            if (state is SupervisorTrackingLoaded) {
              final markers = _getMarkers(state);
              final polylines = _getPolylines(state);

              String nextStopName = '';
              final target = state.targetPosition;
              if (target != null && target.latitude != 0.0 && target.longitude != 0.0) {
                try {
                  final matchedStop = state.stops.firstWhere(
                    (s) => (s.location.latitude - target.latitude).abs() < 0.00015 &&
                           (s.location.longitude - target.longitude).abs() < 0.00015
                  );
                  nextStopName = matchedStop.nameAr;
                } catch (_) {
                  if (state.schoolPosition != null &&
                      (state.schoolPosition!.latitude - target.latitude).abs() < 0.00015 &&
                      (state.schoolPosition!.longitude - target.longitude).abs() < 0.00015) {
                    nextStopName = 'المدرسة';
                  } else {
                    nextStopName = 'الوجهة المحددة';
                  }
                }
              } else {
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
              }

              final remaining = state.stops.where((s) => state.tripType == 'morning' ? (!s.isBoarded && !s.isAbsent && !s.isDroppedOff) : (!s.isDroppedOff && !s.isAbsent)).length;
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

                  // 2b. Beautiful Floating Warning Alert (when there's no active trip)
                  if (!state.hasActiveTrip && _isMapMode)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 60,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD), // Soft Amber background
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFEBAA), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFE8A1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFF856404), // Dark Amber
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'لا توجد رحلة نشطة حالياً لهذا الباص',
                                    style: TextStyle(
                                      color: Color(0xFF856404),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'الموقع المعروض هو آخر موقع تم تسجيله للحافلة.',
                                    style: TextStyle(
                                      color: Color(0xFF856404),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 3. Floating Compass (Top Left, Map Mode only)
                  if (_isMapMode)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + (state.hasActiveTrip ? 60 : 145),
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          _fitRouteBounds(state);
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
                          child: const Icon(
                            Icons.explore_outlined,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                  // 4. Floating Center Location (Top Right, Map Mode only)
                  if (_isMapMode)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + (state.hasActiveTrip ? 60 : 145),
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
                        // Live tracking status pill (updates automatically)
                        const _LiveTrackingPill(),

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
                                child: const DirectionalIcon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.black87),
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
                        color: Colors.grey[50],
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
                              child: AdaptiveListView(
                                storageKey: 'supervisor_student_list_${widget.busId}',
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                itemCount: state.stops.length,
                                childAspectRatio: 3.5,
                                maxExtent: 400.0,
                                itemBuilder: (context, index) {
                                  final stop = state.stops[index];
                                  final isBoarded = state.tripType == 'morning' ? stop.isBoarded : stop.isDroppedOff;

                                  Color statusColor = const Color(0xFF1A73E8);
                                  String statusText = 'في الانتظار';
                                  String subtitleText = 'في انتظار وصول الحافلة';
                                  IconData statusIcon = Icons.access_time_rounded;

                                  if (stop.isAbsent) {
                                    statusColor = const Color(0xFFEF4444);
                                    statusText = 'غائب';
                                    subtitleText = 'تم تسجيل غياب الطالب اليوم';
                                    statusIcon = Icons.cancel_outlined;
                                  } else if (isBoarded) {
                                    statusColor = const Color(0xFF10B981);
                                    statusText = state.tripType == 'morning' ? 'تم الركوب' : 'تم النزول';
                                    subtitleText = state.tripType == 'morning' ? 'صعد الطالب إلى الحافلة' : 'نزل الطالب بسلام';
                                    statusIcon = Icons.check_circle_outline_rounded;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.grey.shade100,
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        children: [
                                          // Right colored status indicator line
                                          Positioned(
                                            top: 0,
                                            bottom: 0,
                                            right: 0,
                                            width: 5,
                                            child: Container(color: statusColor),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
                                            child: Row(
                                              children: [
                                                // Student Avatar with indicator border
                                                _buildStudentAvatar(stop, index, statusColor),
                                                const SizedBox(width: 16),
                                                
                                                // Student Info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        stop.nameAr,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.location_on_outlined,
                                                            size: 14,
                                                            color: Colors.grey[500],
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              stop.parentAr.isNotEmpty ? 'ولي الأمر: ${stop.parentAr}' : 'المحطة #${index + 1}',
                                                              style: TextStyle(
                                                                color: Colors.grey[600],
                                                                fontSize: 12,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        subtitleText,
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                // Status Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        statusIcon,
                                                        color: statusColor,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        statusText,
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
      final cacheKey = 'student_${stop.id}_${isBoarded}_${stop.isAbsent}';
      markers.add(
        Marker(
          markerId: MarkerId('student_${stop.id}'),
          position: stop.location,
          icon: _customMarkers[cacheKey] ??
              BitmapDescriptor.defaultMarkerWithHue(
                stop.isAbsent
                    ? BitmapDescriptor.hueRed
                    : (isBoarded ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure),
              ),
          infoWindow: InfoWindow(
            title: stop.nameAr,
            snippet: stop.isAbsent
                ? 'غائب'
                : (isBoarded ? 'تم التوصيل' : 'في انتظار التوصيل'),
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

  Future<void> _moveCamera(LatLng position, {double? zoom}) async {
    final controller = await _mapController.future;
    _isProgrammaticMove = true;
    if (zoom != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
    } else {
      controller.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  Future<void> _fitRouteBounds(SupervisorTrackingLoaded state) async {
    final controller = await _mapController.future;
    final List<LatLng> points = [];
    
    if (state.busPosition != null && state.busPosition!.latitude != 0.0) {
      points.add(state.busPosition!);
    }
    if (state.schoolPosition != null && state.schoolPosition!.latitude != 0.0) {
      points.add(state.schoolPosition!);
    }
    for (var stop in state.stops) {
      if (stop.location.latitude != 0.0 && stop.location.longitude != 0.0) {
        points.add(stop.location);
      }
    }

    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _isProgrammaticMove = true;
    setState(() {
      _followBus = false;
    });

    if (minLat == maxLat && minLng == maxLng) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 15));
    } else {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  Widget _buildStudentAvatar(StudentStop stop, int index, Color statusColor) {
    if (stop.photoUrl != null && stop.photoUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: statusColor, width: 2),
          image: DecorationImage(
            image: NetworkImage(stop.photoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final initial = stop.nameAr.isNotEmpty ? stop.nameAr.trim().split(' ').last.substring(0, 1) : '${index + 1}';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: statusColor, width: 2),
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.8),
            statusColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
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
  final bool isAbsent;

  const StudentNumberMarkerWidget({
    super.key,
    required this.index,
    required this.isCompleted,
    this.isAbsent = false,
  });

  @override
  Widget build(BuildContext context) {
    Color pinColor = const Color(0xFF1A73E8); // Google Blue for waiting
    IconData centerIcon = Icons.home_filled;
    Color centerIconColor = const Color(0xFF1A73E8);

    if (isAbsent) {
      pinColor = const Color(0xFFEF4444); // Red for absent
      centerIcon = Icons.cancel_rounded;
      centerIconColor = const Color(0xFFEF4444);
    } else if (isCompleted) {
      pinColor = const Color(0xFF10B981); // Green for completed
      centerIcon = Icons.check_circle_rounded;
      centerIconColor = const Color(0xFF10B981);
    }

    return SizedBox(
      width: 80,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pin Icon
          Positioned(
            bottom: 10,
            child: Icon(
              Icons.location_on,
              size: 70,
              color: pinColor,
            ),
          ),
          // White Circle holding the icon status
          Positioned(
            top: 15,
            child: Container(
              width: 38,
              height: 38,
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
              child: Icon(
                centerIcon,
                size: 24,
                color: centerIconColor,
              ),
            ),
          ),
          // Small Floating stop index badge
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: pinColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
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
                  color: Colors.white,
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
    final remainingCount = state.stops.where((s) => state.tripType == 'morning' ? (!s.isBoarded && !s.isAbsent && !s.isDroppedOff) : (!s.isDroppedOff && !s.isAbsent)).length;
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
                    iconColor: const Color(0xFF1A73E8), // Blue for remaining
                    label: 'المتبقي',
                    value: '$remainingCount',
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: _buildStatItem(
                    icon: Icons.directions_bus_rounded,
                    iconColor: const Color(0xFF10B981), // Green for completed/in bus
                    label: 'في الحافلة',
                    value: '$boardedCount',
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: _buildStatItem(
                    icon: Icons.notifications_off_rounded,
                    iconColor: const Color(0xFFEF4444), // Red for absent
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

class _LiveTrackingPill extends StatefulWidget {
  const _LiveTrackingPill();

  @override
  State<_LiveTrackingPill> createState() => _LiveTrackingPillState();
}

class _LiveTrackingPillState extends State<_LiveTrackingPill> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(
                    alpha: 0.3 + (_pulseController.value * 0.7),
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(
                        alpha: 0.4 * (1.0 - _pulseController.value),
                      ),
                      blurRadius: 6,
                      spreadRadius: 2 * _pulseController.value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'تتبع مباشر نشط',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
