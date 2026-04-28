import 'dart:async';
import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:msaratwasel_services/core/presentation/widgets/custom_menu_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/glass_card.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_button.dart';
import '../../domain/repositories/route_repository.dart';
import 'package:get_it/get_it.dart';

import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/utils/location_utils.dart';
import '../../domain/entities/student_stop.dart';

class RouteNavigationScreen extends StatefulWidget {
  const RouteNavigationScreen({super.key});

  @override
  State<RouteNavigationScreen> createState() => _RouteNavigationScreenState();
}

class _RouteNavigationScreenState extends State<RouteNavigationScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // Optimized Start Position: Al Mouj/Seeb (West of Azaiba) for linear flow
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(23.6264, 58.2618), // Al Mouj Area
    zoom: 13.0,
  );

  // Simulation Data (Optimized Linear Route: West -> East)
  List<StudentStop> _stops = [];
  bool _isLoading = true;
  String? _error;
  final RouteRepository _routeRepository = GetIt.instance<RouteRepository>();

  int _currentStopIndex = 0;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isArrived = false;
  bool _isActionLoading = false;
  bool _hasDepartedSchool = false; // Only used for afternoon trip
  bool _isFinished = false; // When the trip phase logic finishes

  // Waiting Timer Logic
  Timer? _waitingTimer;
  int _secondsRemaining = 120;
  StudentStop? _waitingStudent;

  Timer? _locationTimer;
  int _routePointIndex = 0;
  final List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _routePoints.addAll(_getMuscatRoutePoints());
    _fetchRouteData();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_routePoints.isNotEmpty) {
        final currentPos = _routePoints[_routePointIndex];
        _routeRepository.updateLocation(
          latitude: currentPos.latitude,
          longitude: currentPos.longitude,
        );
        // Simulate moving along the points
        _routePointIndex = (_routePointIndex + 1) % _routePoints.length;
      }
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _waitingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRouteData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stops = await _routeRepository.getTripStops();

      if (!mounted) return;

      final isMorning = _routeRepository.currentTripType == 'morning';
      int initialIndex = 0;

      if (isMorning) {
        // Skip students who are already boarded OR have an absence request
        initialIndex = stops.indexWhere((s) => !s.isBoarded && !s.isAbsent);
      } else {
        // Skip students who are already dropped off OR have an absence request
        initialIndex = stops.indexWhere((s) => !s.isDroppedOff && !s.isAbsent);
      }

      setState(() {
        _stops = stops;
        _currentStopIndex = initialIndex == -1 ? stops.length : initialIndex;
        _isLoading = false;
        _initMapData();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Manually defined points to strictly follow 18th Nov St & Sultan Qaboos St (Asphalt)
  // UPDATED: High-density points with specific Al Ghubra fix (Way 4293)
  List<LatLng> _getMuscatRoutePoints() {
    return [
      // 1. Start: Al Mouj Street (Asphalt)
      const LatLng(23.6264, 58.2618),
      const LatLng(23.6245, 58.2625),
      const LatLng(23.6230, 58.2630), // Roundabout
      // 2. 18th November Street (Main Highway - Eastbound)
      const LatLng(23.6190, 58.2690),
      const LatLng(23.6170, 58.2750),
      const LatLng(23.6150, 58.2850),
      const LatLng(23.6130, 58.2950),
      const LatLng(23.6110, 58.3050),
      const LatLng(23.6090, 58.3150),
      const LatLng(23.6070, 58.3250),
      const LatLng(23.6050, 58.3350),

      // 3. Turn into Azaiba North (Smooth Curve)
      const LatLng(23.6042, 58.3410),
      const LatLng(23.6035, 58.3430),
      const LatLng(23.6030, 58.3450),
      const LatLng(23.6015, 58.3470),
      const LatLng(23.6000, 58.3500), // Stop 1: Azaiba North
      // 4. Return to 18th Nov St (Retracing)
      const LatLng(23.6015, 58.3470),
      const LatLng(23.6030, 58.3450),
      const LatLng(23.6025, 58.3510),
      const LatLng(23.6000, 58.3550),
      const LatLng(23.5980, 58.3650),
      const LatLng(23.5960, 58.3750),
      const LatLng(23.5940, 58.3850),

      // 5. Turn into Ghubra (FIXED: Avoiding Haitham Jaffer Building)
      const LatLng(23.5935, 58.3880), // Arriving at junction
      const LatLng(23.5938, 58.3910), // Continue East slightly
      const LatLng(23.5930, 58.3930), // Turn Right into Way 4293
      const LatLng(23.5915, 58.3938), // South down the street
      const LatLng(23.5900, 58.3945), // Stop 2: Al Ghubra
      // 6. Navigate to Sultan Qaboos St (Complex Intersection)
      const LatLng(23.5895, 58.3960),
      const LatLng(23.5890, 58.3980),
      const LatLng(23.5880, 58.3950),
      const LatLng(23.5865, 58.3935), // Grand Mosque Roundabout
      const LatLng(23.5850, 58.3920),

      // 7. Sultan Qaboos St (Eastbound Highway - Smooth)
      const LatLng(23.5855, 58.3980),
      const LatLng(23.5860, 58.4050),
      const LatLng(23.5865, 58.4100),
      const LatLng(23.5872, 58.4125),
      const LatLng(23.5880, 58.4150),
      const LatLng(23.5888, 58.4180),
      const LatLng(23.5895, 58.4200),

      // 8. Exit to Al Khuwair (Dohat Al Adab St - Winding)
      const LatLng(23.5905, 58.4215), // Ramp Start
      const LatLng(23.5915, 58.4225),
      const LatLng(23.5925, 58.4235),
      const LatLng(23.5935, 58.4245),
      const LatLng(23.5945, 58.4255), // Thaqafah St
      const LatLng(23.5960, 58.4265),
      const LatLng(23.5975, 58.4275), // Passing Court Complex
      const LatLng(23.5990, 58.4285),
      const LatLng(23.6000, 58.4300), // Stop 3: Al Khuwair 33
      // 9. Continue via Service Roads to MSQ
      const LatLng(23.6005, 58.4310),
      const LatLng(23.6012, 58.4325),
      const LatLng(23.6020, 58.4350),
      const LatLng(23.6028, 58.4370), // Curve
      const LatLng(23.6035, 58.4385),
      const LatLng(23.6040, 58.4400),
      const LatLng(23.6048, 58.4415),
      const LatLng(23.6055, 58.4430),
      const LatLng(23.6062, 58.4445),
      const LatLng(23.6070, 58.4460),
      const LatLng(23.6078, 58.4480), // Turning into MSQ
      const LatLng(23.6080, 58.4500), // Stop 4: MSQ
    ];
  }

  void _initMapData() {
    _markers = _stops.asMap().entries.where((entry) => entry.key >= _currentStopIndex).map((entry) {
      final index = entry.key;
      final stop = entry.value;
      final isNext = index == _currentStopIndex;

      // Ensure the marker always shows the name in the info window
      return Marker(
        markerId: MarkerId('stop_$index'),
        position: stop.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isNext ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
        ),
        infoWindow: InfoWindow(
          title: stop.nameAr,
          snippet: isNext ? 'الوجهة الحالية' : 'محطة ${index + 1}',
        ),
      );
    }).toSet();

    // Add School marker to the map if morning trip and headed to school OR afternoon trip and waiting at school
    final isMorning = _routeRepository.currentTripType == 'morning';
    final showSchool =
        (isMorning && _currentStopIndex == _stops.length && !_isFinished) ||
        (!isMorning && !_hasDepartedSchool);

    if (showSchool) {
      _markers.add(
        Marker(
          markerId: const MarkerId('school_stop'),
          position: const LatLng(23.6080, 58.4500),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: const InfoWindow(title: 'المدرسة', snippet: 'الوجهة'),
        ),
      );
    }

    // Use our realistic points instead of just the stops
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route_line'),
        points: _getMuscatRoutePoints(),
        color: Colors.blue,
        width: 6,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Future<void> _handleNearHouse() async {
    if (_currentStopIndex >= _stops.length) return;

    final currentStudent = _stops[_currentStopIndex];

    setState(() {
      _isActionLoading = true;
    });

    try {
      // 1. Notify Parent
      await _routeRepository.notifyParentNearHouse(studentId: currentStudent.id);

      // 2. Start Timer
      _startWaitingTimer(currentStudent);

      // 3. IMMEDIATE Advance to next student route
      setState(() {
        _currentStopIndex++;
        _isActionLoading = false;
        _initMapData();
      });

      // Update map view
      final controller = await _controller.future;
      if (_currentStopIndex < _stops.length) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _stops[_currentStopIndex].location,
              zoom: 15,
            ),
          ),
        );
        controller.showMarkerInfoWindow(
          MarkerId('stop_$_currentStopIndex'),
        );
      } else {
        // Reached last student, go to school (if morning)
        final isMorning = _routeRepository.currentTripType == 'morning';
        if (isMorning) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              const CameraPosition(
                target: LatLng(23.6080, 58.4500),
                zoom: 15,
              ),
            ),
          );
          controller.showMarkerInfoWindow(const MarkerId('school_stop'));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التنبيه: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _startWaitingTimer(StudentStop student) {
    _waitingTimer?.cancel();
    setState(() {
      _waitingStudent = student;
      _secondsRemaining = 120;
    });

    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        // Timer finished - UI will show "Time's up"
      }
    });
  }

  Future<void> _advanceToNextStop() async {
    final isMorning = _routeRepository.currentTripType == 'morning';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    setState(() {
      _isActionLoading = true;
    });

    try {
      if (isMorning) {
        // --- MORNING TRIP FLOW ---
        if (_currentStopIndex < _stops.length) {
          // Phase 1: Boarding Students
          final currentStudentId = _stops[_currentStopIndex].id;
          await _routeRepository.markStudentBoarded(
            studentId: currentStudentId,
          );

          if (!mounted) return;
          setState(() {
            _currentStopIndex++;
            _isArrived = false;
            _isActionLoading = false;
            _initMapData();
          });

          final controller = await _controller.future;
          if (_currentStopIndex < _stops.length) {
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: _stops[_currentStopIndex].location,
                  zoom: 15,
                ),
              ),
            );
            controller.showMarkerInfoWindow(
              MarkerId('stop_$_currentStopIndex'),
            );
          } else {
            // Reached last student, go to school
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                const CameraPosition(
                  target: LatLng(23.6080, 58.4500),
                  zoom: 15,
                ),
              ),
            );
            controller.showMarkerInfoWindow(const MarkerId('school_stop'));
          }
        } else {
          // Phase 2: Reached School -> Show Confirmation -> Navigate to Safety Check
          setState(() {
            _isActionLoading = false;
          });

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isArabic ? 'تأكيد الوصول' : 'Confirm Arrival'),
              content: Text(
                isArabic
                    ? 'هل وصلت بالفعل إلى المدرسة؟'
                    : 'Have you actually arrived at the school?',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(isArabic ? 'نعم، وصلت' : 'Yes, I Arrived'),
                ),
              ],
            ),
          );

          if (confirmed == true && mounted) {
            // Navigate to EndTripScreen for QR/Video verification
            context.push(AppRoutes.driverEndTrip);
          }
        }
      } else {
        // --- AFTERNOON TRIP FLOW ---
        if (!_hasDepartedSchool) {
          // Phase 1: At School -> Board Students first
          if (!_isArrived) {
            // Reusing _isArrived to mean "Boarded students" for afternoon
            await _routeRepository.groupBoard(
              studentIds: _stops.map((s) => s.id).toList(),
            );
            if (!mounted) return;
            setState(() {
              _isArrived = true; // All boarded
              _isActionLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تسجيل ركوب جميع الطلاب بنجاح.'),
                backgroundColor: Colors.green,
              ),
            );
            return;
          }

          // Phase 2: Once boarded -> Depart School
          if (!mounted) return;
          setState(() {
            _hasDepartedSchool = true;
            _isArrived = false;
            _isActionLoading = false;
            _initMapData();
          });

          final controller = await _controller.future;
          if (_stops.isNotEmpty) {
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: _stops[0].location, zoom: 15),
              ),
            );
            controller.showMarkerInfoWindow(const MarkerId('stop_0'));
          }
        } else if (_currentStopIndex < _stops.length) {
          // Phase 2: Dropping off Students (Single Click)
          final currentStudentId = _stops[_currentStopIndex].id;
          await _routeRepository.markStudentDropped(
            studentId: currentStudentId,
          );

          if (!mounted) return;
          setState(() {
            _currentStopIndex++;
            _isArrived = false;
            _isActionLoading = false;
            _initMapData();
          });

          final controller = await _controller.future;
          if (_currentStopIndex < _stops.length) {
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: _stops[_currentStopIndex].location,
                  zoom: 15,
                ),
              ),
            );
            controller.showMarkerInfoWindow(
              MarkerId('stop_$_currentStopIndex'),
            );
          } else {
            // Phase 3: Dropped last student -> Show Confirmation -> Safety Check
            setState(() {
              _isActionLoading = false;
            });

            final onBoardCount = _routeRepository.getOnBoardCount(_stops);
            
            if (onBoardCount > 0) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(isArabic ? 'تنبيه: طلاب في الحافلة' : 'Warning: Students on Bus'),
                  content: Text(
                    isArabic
                        ? 'لا يمكنك إنهاء الرحلة وهناك $onBoardCount طلاب لم يتم تسجيل نزولهم.'
                        : 'You cannot end the trip while there are $onBoardCount students still on board.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(isArabic ? 'حسناً' : 'OK'),
                    ),
                  ],
                ),
              );
              return;
            }

            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(isArabic ? 'تأكيد إنهاء النزول' : 'Confirm Completion'),
                content: Text(
                  isArabic
                      ? 'هل انتهيت من إنزال كل الطلاب الموجودين في الحافلة؟'
                      : 'Have you finished dropping off all students from the bus?',
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(isArabic ? 'نعم، انتهيت' : 'Yes, Finished'),
                  ),
                ],
              ),
            );

            if (confirmed == true && mounted) {
              context.push(AppRoutes.driverEndTrip);
            }
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الإجراء: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isMorning = _routeRepository.currentTripType == 'morning';
    final currentStop = _currentStopIndex < _stops.length
        ? _stops[_currentStopIndex]
        : null;

    final isSchoolState =
        (isMorning && _currentStopIndex == _stops.length && !_isFinished) ||
        (!isMorning && !_hasDepartedSchool);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'خطأ: \$_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: _fetchRouteData,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : _stops.isEmpty
          ? const Center(child: Text('لا يوجد طلاب في هذه الرحلة'))
          : Stack(
              children: [
                // 1. Google Map Background
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _kInitialPosition,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    // Show the first stop's name immediately
                    Future.delayed(const Duration(milliseconds: 500), () {
                      controller.showMarkerInfoWindow(const MarkerId('stop_0'));
                    });
                  },
                ),

                // 2.5 Waiting Student Floating Card
                if (_waitingStudent != null)
                  Positioned(
                    top: 150,
                    right: 20,
                    child: _WaitingStudentCard(
                      isArabic: isArabic,
                      student: _waitingStudent!,
                      secondsRemaining: _secondsRemaining,
                      onDismiss: () => setState(() => _waitingStudent = null),
                    ),
                  ),

                // 2. Next Stop Card (Centered Adaptive Pill)
                if (currentStop != null && !isSchoolState)
                  Positioned(
                    top: 60,
                    left: 20,
                    right: 20,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: IntrinsicWidth(
                        child: _NextStopCard(
                          isArabic: isArabic,
                          stop: currentStop,
                        ),
                      ),
                    ),
                  ),

                if (isSchoolState)
                  Positioned(
                    top: 60,
                    left: 20,
                    right: 20,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: IntrinsicWidth(
                        child: GlassCard(
                          borderRadius: 24,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                PhosphorIconsFill.buildings,
                                color: Colors.amber,
                                size: 32,
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic
                                        ? 'الوجهة الحالية'
                                        : 'Current Stop',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.amber[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    isArabic ? 'المدرسة' : 'School',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. Bottom Action Panel
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Route Info Pill
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    PhosphorIconsFill.clock,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    LocationUtils.formatEtaEnglish(18.2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  const Icon(
                                    PhosphorIconsFill.path,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "18.2 km",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().slideY(begin: 1, end: 0, duration: 400.ms),
                        
                        // Absence Warning Card (Show if student is absent)
                        // Absence Warning Card (Show if student is absent)
                        if (currentStop != null && currentStop.isAbsent && !isSchoolState)
                          GlassCard(
                            margin: const EdgeInsets.only(top: 15),
                            padding: const EdgeInsets.all(16),
                            borderRadius: 24,
                            child: Stack(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        PhosphorIconsFill.warningCircle,
                                        color: Colors.red[400],
                                        size: 28,
                                      ),
                                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                     .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                isArabic ? 'بلاغ غياب' : 'Absence Reported',
                                                style: TextStyle(
                                                  color: Colors.red[400],
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isArabic ? 'هام' : 'IMPORTANT',
                                                  style: TextStyle(
                                                    color: Colors.red[300],
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isArabic
                                                ? 'الطالب ${currentStop.nameAr} مسجل كغائب اليوم.'
                                                : '${currentStop.nameEn} is marked absent today.',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            isArabic ? 'يمكنك تخطي هذه النقطة.' : 'You can safely skip this stop.',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.6),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.2, end: 0, duration: 400.ms),

                        const SizedBox(height: 20),

                        // Main Action Button (PremiumButton)
                        _isActionLoading
                            ? const Center(child: CircularProgressIndicator())
                            : PremiumButton(
                                height: 60,
                                borderRadius: 20,
                                text: _getActionButtonText(
                                  isArabic,
                                  isSchoolState,
                                  isMorning,
                                  currentStop,
                                ),
                                color: (!isMorning && _currentStopIndex == _stops.length - 1 && _routeRepository.getOnBoardCount(_stops) > 0)
                                    ? Colors.grey[700]
                                    : ((currentStop?.isAbsent == true && !isSchoolState)
                                        ? Colors.red[600]
                                        : null),
                                gradient: (!isMorning && _currentStopIndex == _stops.length - 1 && _routeRepository.getOnBoardCount(_stops) > 0)
                                    ? null
                                    : ((currentStop?.isAbsent == true && !isSchoolState)
                                        ? LinearGradient(
                                            colors: [Colors.red[600]!, Colors.orange[800]!],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          )
                                        : const LinearGradient(
                                            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )),
                                onTap: () {
                                  if (_isFinished) return;
                                  // If absent, skip directly
                                  if (currentStop?.isAbsent == true && !isSchoolState) {
                                    _advanceToNextStop();
                                    return;
                                  }
                                  if (isSchoolState) {
                                    _advanceToNextStop();
                                  } else {
                                    _handleNearHouse();
                                  }
                                },
                                icon: (currentStop?.isAbsent == true && !isSchoolState)
                                    ? PhosphorIconsBold.skipForward
                                    : (_isArrived || isSchoolState
                                        ? PhosphorIconsBold.arrowRight
                                        : PhosphorIconsBold.mapPin),
                              ).animate(
                                onPlay: (controller) {
                                  if (currentStop?.isAbsent == true && !isSchoolState) {
                                    controller.repeat(reverse: true);
                                  }
                                },
                              ).slideY(
                                begin: 1,
                                end: 0,
                                duration: 500.ms,
                              ).then().shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                      ],
                    ),
                  ),
                ),

                // 4. Top Bar (Back Button & Title) - MOVED TO END of Stack to be ON TOP
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomMenuButton(),
                          _TripTypeBadge(isArabic: isArabic, isMorning: isMorning),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  } // <--- Added closing brace for build()

  String _getActionButtonText(
    bool isArabic,
    bool isSchoolState,
    bool isMorning,
    StudentStop? currentStop,
  ) {
    if (_isFinished) {
      return isArabic ? 'الرحلة منتهية' : 'Trip Finished';
    }
    if (currentStop?.isAbsent == true && !isSchoolState) {
      return isArabic ? 'تخطي الطالب (غائب)' : 'Skip Student (Absent)';
    }
    if (isSchoolState) {
      if (isMorning) return isArabic ? '🏢 الوصول إلى المدرسة' : '🏢 Arrive at School';
      if (!_isArrived)
        return isArabic ? '👪 تسجيل ركوب الجميع' : '👪 Board All';
      return isArabic ? '🚀 مغادرة المدرسة' : '🚀 Depart School';
    }
    if (_isArrived) {
      if (!isMorning && _currentStopIndex == _stops.length - 1) {
        return isArabic ? '🏁 إنزال آخر طالب وإنهاء' : '🏁 Drop Last Student & End';
      }
      return isMorning
          ? (isArabic ? '✅ تم الركوب' : '✅ Boarded')
          : (isArabic ? '✅ تم النزول' : '✅ Dropped Off');
    }
    return isArabic ? '📍 بجوار المنزل' : '📍 Near House';
  }
}

class _TripTypeBadge extends StatelessWidget {
  final bool isArabic;
  final bool isMorning;

  const _TripTypeBadge({required this.isArabic, required this.isMorning});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMorning ? PhosphorIconsFill.sun : PhosphorIconsFill.moon,
            color: isMorning ? Colors.orange : Colors.indigo[300],
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isMorning
                ? (isArabic ? 'رحلة ذهاب' : 'Go Trip')
                : (isArabic ? 'رحلة عودة' : 'Return Trip'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingStudentCard extends StatelessWidget {
  final bool isArabic;
  final StudentStop student;
  final int secondsRemaining;
  final VoidCallback onDismiss;

  const _WaitingStudentCard({
    required this.isArabic,
    required this.student,
    required this.secondsRemaining,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr = "$minutes:${seconds.toString().padLeft(2, '0')}";
    final isTimeUp = secondsRemaining == 0;

    return GlassCard(
      width: 140,
      padding: const EdgeInsets.all(12),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(student.photoUrl),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? student.nameAr : student.nameEn,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isTimeUp ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsFill.clock,
                  size: 14,
                  color: isTimeUp ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isTimeUp ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isTimeUp)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                isArabic ? 'انتهى الوقت' : "Time's up",
                style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    ).animate().slideX(begin: 1, end: 0, duration: 400.ms);
  }
}

class _NextStopCard extends StatelessWidget {
  const _NextStopCard({required this.isArabic, required this.stop});

  final bool isArabic;
  final StudentStop stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Student Photo Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(stop.photoUrl),
              onBackgroundImageError: (exception, stackTrace) =>
                  const Icon(Icons.person),
            ),
          ),
          const SizedBox(width: 14),
          // Info List
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isArabic ? 'الوجهة التالية' : 'Next Stop',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (stop.isAbsent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          isArabic ? 'غياب محتمل' : 'Probable Absence',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic ? stop.nameAr : stop.nameEn,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
    .animate(key: ValueKey(stop.nameEn))
    .fadeIn()
    .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
