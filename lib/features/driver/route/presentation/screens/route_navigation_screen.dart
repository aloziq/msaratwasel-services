import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_directions_api/google_directions_api.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:msaratwasel_services/core/presentation/widgets/custom_menu_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/glass_card.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_button.dart';
import '../../domain/repositories/route_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/services/reverb_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/app_config.dart';

import '../../domain/entities/student_stop.dart';

class RouteNavigationScreen extends StatefulWidget {
  const RouteNavigationScreen({super.key});

  @override
  State<RouteNavigationScreen> createState() => _RouteNavigationScreenState();
}

class _RouteNavigationScreenState extends State<RouteNavigationScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // Improved fallback initial position (more central to Ibb/Yemen)
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(13.9307, 43.7773), 
    zoom: 14,
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
  bool _isSyncingStops = false;
  bool _followMe = true; // Automatically follow the bus
  bool _isFirstLock = true; // Track first GPS lock to center camera
  bool _isProgrammaticMove = false; // Distinguish between manual and automatic camera moves
  bool _hasDepartedSchool = false; // Only used for afternoon trip
  bool _hasNotified = false; // Whether parent has been notified for the current stop
  bool _isMovingToStop = false; // Whether the driver has started moving to the current stop
  bool _isFinished = false; // When the trip phase logic finishes

  // Waiting Timer Logic
  Timer? _waitingTimer;
  int _secondsRemaining = 120;
  StudentStop? _waitingStudent;

  ReverbService? _reverbService;
  StreamSubscription<Position>? _gpsSubscription;
  Timer? _statusPollingTimer;
  Timer? _locationTimer;
  LatLng? _currentPosition;
  List<LatLng> _activeRoutePoints = []; // Road-following points
  String _remainingTime = '--';
  String _remainingDistance = '--';
  bool _isGpsDisabled = false;
  Timer? _gpsCheckTimer;

  @override
  void initState() {
    super.initState();
    gmaps.DirectionsService.init("AIzaSyA2ZcFQqhauhU3l-Rj36fbRYomIO7L-ahs");
    _fetchRouteData();
    _startRealGPS();
    _initReverb();
    _startStatusPolling();
    _startGpsCheckTimer();
  }

  void _startGpsCheckTimer() {
    _gpsCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final enabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final hasPermission = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      
      final disabled = !enabled || !hasPermission;
      if (disabled != _isGpsDisabled) {
        if (mounted) {
          setState(() {
            _isGpsDisabled = disabled;
          });
        }
      }
    });
  }



  void _startStatusPolling() {
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _fetchRouteData(silent: true);
      }
    });
  }

  Future<void> _initReverb() async {
    final busId = GetIt.instance<SharedPreferences>().getString('USER_BUS_ID') ?? '';
    if (busId.isNotEmpty) {
      final prefs = GetIt.instance<SharedPreferences>();
      final userIdStr = prefs.getString('USER_ID') ?? '';
      final userId = int.tryParse(userIdStr) ?? 0;
      
      _reverbService = ReverbService(
        userId: userId,
        dio: ApiClient.instance,
        onMessageReceived: (data) {
          debugPrint("REVERB: Student location updated, refreshing route data...");
          _fetchRouteData(silent: true);
        }
      );
      _reverbService!.connect();
      _reverbService!.subscribe('private-bus.$busId');
    }
  }

  Future<void> _startRealGPS() async {
    // 1. Check Service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('GPS: Location services are disabled.');
      return;
    }

    // 2. Request Permissions using permission_handler
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      debugPrint('GPS: Location permissions are permanently denied');
      openAppSettings();
      return;
    }

    if (!status.isGranted) {
      debugPrint('GPS: Location permission not granted');
      return;
    }

    // Also check for background location if possible
    await Permission.locationAlways.request();

    debugPrint('GPS: Location permissions granted. Starting stream...');

    // 3. Check if service is enabled before getting initial position
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('GPS: Location services are disabled.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تفعيل خدمة الموقع (GPS)')),
        );
      }
      
      /* 
      // Smart Mock: If GPS is off in debug mode, use school location as starting point to show the blue line
      if (kDebugMode && _currentPosition == null) {
        debugPrint('🛠️ [GPS] Using School Location as Mock Position for Debugging');
        if (mounted) {
          setState(() {
            _currentPosition = _routeRepository.schoolLocation ?? const LatLng(13.9407, 43.7873);
          });
          _fetchRoadFollowingRoute();
        }
      }
      */
      return;
    }

    // 4. Get initial position immediately and center map
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        final initialLatLng = LatLng(initialPosition.latitude, initialPosition.longitude);
        setState(() {
          _currentPosition = initialLatLng;
        });
        
        // Initial camera animation to bus
        final controller = await _controller.future;
        _isProgrammaticMove = true;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: initialLatLng, zoom: 16),
          ),
        );
        _isFirstLock = false;
        
        _sortPendingStopsByDistance();
        _fetchRoadFollowingRoute();
      }
    } catch (e) {
      debugPrint('GPS: Error getting initial position: $e');
    }

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      
      final newPos = LatLng(position.latitude, position.longitude);
      
      // Only trigger updates if moved > 15m or current position was null
      double distance = 0;
      if (_currentPosition != null) {
        distance = Geolocator.distanceBetween(
          _currentPosition!.latitude, 
          _currentPosition!.longitude, 
          newPos.latitude, 
          newPos.longitude
        );
      }

      setState(() {
        _currentPosition = newPos;
      });

      // Automatically track camera if enabled and moved significantly
      if ((_followMe && distance > 5) || _isFirstLock) {
        _controller.future.then((controller) {
          _isProgrammaticMove = true;
          controller.animateCamera(
            CameraUpdate.newLatLng(newPos),
          );
        });
        if (_isFirstLock) _isFirstLock = false;
      }

      _routeRepository.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        accuracy: position.accuracy,
        heading: position.heading,
      );

      if (distance > 15 || _activeRoutePoints.isEmpty) {
        _fetchRoadFollowingRoute();
      } else {
        _updatePolylines();
      }
    });
  }

  DateTime? _lastRouteFetchTime;
  LatLng? _lastFetchTarget;

  Future<void> _fetchRoadFollowingRoute() async {
    final target = _currentTarget;
    if (_currentPosition == null) {
      debugPrint("⚠️ [Navigation] Cannot fetch route: Position is NULL");
      return;
    }
    if (target == null) {
      debugPrint("⚠️ [Navigation] Cannot fetch route: Target is NULL");
      return;
    }

    // Check for invalid targets (like 0,0) early
    if (target.latitude == 0 && target.longitude == 0) {
      debugPrint("DEBUG: Target is 0,0 - skipping Directions API");
      _updatePolylines();
      return;
    }

    // Throttle: Don't fetch more than once every 10 seconds unless target changed
    final now = DateTime.now();
    if (_lastRouteFetchTime != null && 
        now.difference(_lastRouteFetchTime!).inSeconds < 10 && 
        _lastFetchTarget == target) {
      _updatePolylines();
      return;
    }

    final originStr = "${_currentPosition!.longitude},${_currentPosition!.latitude}";
    final destStr = "${target.longitude},${target.latitude}";

    debugPrint("🚀 [Navigation] Requesting OSRM Directions: $originStr -> $destStr");

    try {
      final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/$originStr;$destStr?overview=full&geometries=polyline",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("DEBUG: OSRM API Status: ${data['code']}");
        
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final points = PolylinePoints.decodePolyline(route['geometry']);
          
          debugPrint("✅ [Navigation] OSRM route decoded: ${points.length} points");

          if (mounted) {
            setState(() {
              _activeRoutePoints = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
              final distInKm = (route['distance'] as num) / 1000;
              final durInMin = (route['duration'] as num) / 60;
              _remainingDistance = '${distInKm.toStringAsFixed(1)} كم';
              _remainingTime = '${durInMin.ceil()} دقيقة';
              _lastRouteFetchTime = now;
              _lastFetchTarget = target;
            });
            _updatePolylines();
          }
          return; // Success
        }
      }
      
      // Fallback if OSRM fails
      debugPrint("❌ [Navigation] OSRM failed. Using straight line fallback.");
      if (mounted) {
        setState(() {
          _activeRoutePoints = []; // Use straight dotted line
          _lastRouteFetchTime = now;
          _lastFetchTarget = target;
        });
        _updatePolylines();
      }
    } catch (e) {
      debugPrint("❌ [Navigation] Directions Exception/Timeout: $e");
      _updatePolylines();
    }
  }

  Future<void> _fetchRouteData({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      debugPrint('📡 [Navigation] Fetching route data from repository...');
      final stops = await _routeRepository.getTripStops();
      debugPrint('✅ [Navigation] Fetched ${stops.length} stops.');

      if (!mounted) return;

      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final tripStatus = _routeRepository.currentTripStatus;
      if (tripStatus != 'in_progress' &&
          tripStatus != 'awaiting_confirmation' &&
          tripStatus != 'awaiting_video') {
        debugPrint('⚠️ [Navigation] Trip status is $tripStatus.');
        
        // We don't automatically push to EndTrip if the trip is already completely finished.
        // It will just show the snackbar below and close the navigation screen.
        
        // Don't pop if we're already navigating away
        if (_isFinished) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic 
              ? '✅ لا توجد رحلة نشطة حالياً. تم إغلاق صفحة الملاحة.' 
              : '✅ No active trip. Navigation screen closed.'
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.driverHome);
        }
        return;
      }

      final isMorning = _routeRepository.currentTripType == 'morning';
      int initialIndex = 0;

      if (isMorning) {
        initialIndex = stops.indexWhere((s) => !s.isBoarded && !s.isAbsent);
      } else {
        initialIndex = stops.indexWhere((s) => !s.isDroppedOff && !s.isAbsent);
        // Auto-detect if school departure already happened:
        // If any student is boarded (still on bus) OR already dropped off at home,
        // the bus has clearly already left the school.
        if (!_hasDepartedSchool && stops.any((s) => s.isBoarded || s.isDroppedOff)) {
          _hasDepartedSchool = true;
        }
      }

      final previousStopIndex = _currentStopIndex;

      setState(() {
        _stops = stops;
        _currentStopIndex = initialIndex == -1 ? stops.length : initialIndex;
        _isLoading = false;
        _activeRoutePoints = []; 
        _initMapData();
      });

      // If all students are resolved in afternoon trip, go to end trip
      if (!isMorning && _hasDepartedSchool && _currentStopIndex >= _stops.length && !_isFinished) {
        _isFinished = true;
        _statusPollingTimer?.cancel();
        if (mounted) context.push(AppRoutes.driverEndTrip);
        return;
      }

      // Auto-advance: if the current student changed (e.g. marked boarded from supervisor screen),
      // reset navigation state so the UI smoothly transitions to the new target.
      if (silent && previousStopIndex != _currentStopIndex && _currentStopIndex < _stops.length) {
        debugPrint('🔄 [Navigation] Auto-advancing from stop $previousStopIndex to $_currentStopIndex');
        setState(() {
          _hasNotified = false;
          _isMovingToStop = false;
          _isArrived = false;
        });
      }

      _sortPendingStopsByDistance();

      // Restore active timer state if the student is currently waiting in morning trip
      if (isMorning && _currentStopIndex < _stops.length) {
        final currentStop = _stops[_currentStopIndex];
        debugPrint(
          '⏱️ [SCREEN] currentStop: ${currentStop.nameAr}, isWaiting: ${currentStop.isWaiting}, '
          'waitingElapsedSeconds: ${currentStop.waitingElapsedSeconds}',
        );
        if (currentStop.isWaiting) {
          _hasNotified = true;
          _isMovingToStop = true;
          if (_waitingStudent?.id != currentStop.id || _waitingTimer == null || !_waitingTimer!.isActive) {
            final elapsed = currentStop.waitingElapsedSeconds;
            debugPrint('⏱️ [SCREEN] Restoring timer for student ${currentStop.nameAr} with elapsed: $elapsed');
            _restoreWaitingTimer(currentStop, elapsed);
          }
        }
      }
      
      // Log coordinates for debugging
      if (_stops.isNotEmpty && _currentStopIndex < _stops.length) {
        final target = _stops[_currentStopIndex].location;
        debugPrint('📍 [Navigation] Current Target Stop: ${target.latitude}, ${target.longitude}');
      } else {
        debugPrint('📍 [Navigation] Target: School (${_routeRepository.schoolLocation?.latitude}, ${_routeRepository.schoolLocation?.longitude})');
      }

      _fetchRoadFollowingRoute();
    } catch (e) {
      debugPrint('❌ [Navigation] Error fetching route data: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _sortPendingStopsByDistance() {
    if (_currentPosition == null || _stops.isEmpty) return;

    final isMorning = _routeRepository.currentTripType == 'morning';
    
    List<StudentStop> processed = [];
    List<StudentStop> pending = [];
    
    for (var stop in _stops) {
      bool isResolved = isMorning 
        ? (stop.isBoarded || stop.isAbsent)
        : (stop.isDroppedOff || stop.isAbsent);
        
      if (isResolved) {
        processed.add(stop);
      } else {
        pending.add(stop);
      }
    }
    
    // Sort pending by distance from current location, prioritizing waiting students
    pending.sort((a, b) {
      if (a.isWaiting && !b.isWaiting) return -1;
      if (!a.isWaiting && b.isWaiting) return 1;

      double distA = Geolocator.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude,
        a.location.latitude, a.location.longitude
      );
      double distB = Geolocator.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude,
        b.location.latitude, b.location.longitude
      );
      return distA.compareTo(distB);
    });
    
    setState(() {
      _stops = [...processed, ...pending];
      _currentStopIndex = processed.length;
      _initMapData();
    });
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    _gpsSubscription?.cancel();
    _reverbService?.dispose();
    _locationTimer?.cancel();
    _waitingTimer?.cancel();
    _gpsCheckTimer?.cancel();
    super.dispose();
  }

  LatLng? get _currentTarget {
    if (_routeRepository.currentTripType == 'morning') {
      if (_currentStopIndex < _stops.length) {
        return _stops[_currentStopIndex].location;
      }
      return _routeRepository.schoolLocation;
    } else {
      if (!_hasDepartedSchool) return _routeRepository.schoolLocation;
      if (_currentStopIndex < _stops.length) {
        return _stops[_currentStopIndex].location;
      }
      return null;
    }
  }

  void _initMapData() {
    _markers = _stops.asMap().entries.where((entry) => entry.key >= _currentStopIndex).map((entry) {
      final index = entry.key;
      final stop = entry.value;
      final isNext = index == _currentStopIndex;

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

    final isMorning = _routeRepository.currentTripType == 'morning';
    final showSchool = isMorning || (!isMorning && !_hasDepartedSchool);

    if (showSchool) {
      _markers.add(
        Marker(
          markerId: const MarkerId('school_stop'),
          position: _routeRepository.schoolLocation ?? const LatLng(23.6080, 58.4500),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: const InfoWindow(title: 'المدرسة', snippet: 'الوجهة'),
        ),
      );
    }
    _updatePolylines();
  }

  void _updatePolylines() {
    final target = _currentTarget;
    if (_currentPosition == null) {
      debugPrint('⚠️ [Navigation] Cannot draw polyline: Current Position is NULL (Wait for GPS lock)');
      return;
    }

    Set<Polyline> newPolylines = {};

    // Active road-following path
    if (_activeRoutePoints.isNotEmpty) {
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: _activeRoutePoints,
          color: Colors.blue[700]!,
          width: 7,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    } else if (target != null) {
      // Fallback to straight line if road points not yet fetched
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: [LatLng(_currentPosition!.latitude, _currentPosition!.longitude), target],
          color: Colors.blue.withValues(alpha: 0.8),
          width: 6,
          jointType: JointType.round,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dotted line for fallback
        ),
      );
    }

    setState(() {
      _polylines = newPolylines;
    });

    if (_polylines.isNotEmpty) {
      debugPrint('DEBUG: Polyline points count: ${_polylines.first.points.length}');
    } else {
      debugPrint('DEBUG: Polyline set is EMPTY');
    }
  }

  Future<void> _handleNearHouse() async {
    if (_currentStopIndex >= _stops.length) return;

    final currentStudent = _stops[_currentStopIndex];
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    setState(() {
      _isActionLoading = true;
    });

    try {
      // 1. Notify Parent
      await _routeRepository.notifyParentNearHouse(studentId: currentStudent.id);

      // 2. Start Timer (only in morning trip)
      final isMorning = _routeRepository.currentTripType == 'morning';
      if (isMorning) {
        _startWaitingTimer(currentStudent);
      }

      // 3. Mark as notified to change button to "Next Destination"
      setState(() {
        _hasNotified = true;
        _isActionLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isActionLoading = false;
      });

      // Show user-friendly error message
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      if (errorMsg.contains('Too Many Attempts') || errorMsg.contains('429')) {
        errorMsg = isArabic
            ? 'تم إرسال التنبيه مسبقاً. يرجى الانتظار قليلاً قبل المحاولة مرة أخرى.'
            : 'Notification already sent. Please wait a moment before trying again.';
      } else if (errorMsg.contains('فشل إرسال الإشعار')) {
        errorMsg = isArabic
            ? 'تعذر إرسال التنبيه لولي الأمر. تحقق من الاتصال وحاول مجدداً.'
            : 'Could not notify the parent. Check your connection and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(PhosphorIconsFill.warningCircle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg, style: const TextStyle(fontSize: 13))),
            ],
          ),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          duration: const Duration(seconds: 4),
        ),
      );

      // Even if notification fails, allow driver to continue (mark as notified)
      setState(() {
        _hasNotified = true;
      });
    }
  }

  void _startWaitingTimer(StudentStop student) {
    _waitingTimer?.cancel();
    setState(() {
      _waitingStudent = student;
      _secondsRemaining = 120;
    });

    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });
    });
  }

  void _restoreWaitingTimer(StudentStop student, int elapsedSeconds) {
    _waitingTimer?.cancel();
    setState(() {
      _waitingStudent = student;
      _secondsRemaining = 120 - elapsedSeconds;
    });

    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });
    });
  }

  Future<void> _advanceToNextStop() async {
    _waitingTimer?.cancel();
    _waitingTimer = null;
    _waitingStudent = null;
    final isMorning = _routeRepository.currentTripType == 'morning';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔄 [ADVANCE] ▶ _advanceToNextStop() called');
    debugPrint('🔄 [ADVANCE] Trip type: ${isMorning ? "MORNING" : "AFTERNOON"}');
    debugPrint('🔄 [ADVANCE] _currentStopIndex: $_currentStopIndex / ${_stops.length}');
    debugPrint('🔄 [ADVANCE] _hasNotified: $_hasNotified, _hasDepartedSchool: $_hasDepartedSchool');

    // Validation: Prevent skipping a student whose status is undetermined.
    // First, refresh data to get latest status from server
    if (_currentStopIndex < _stops.length) {
      debugPrint('🔄 [ADVANCE] Refreshing data before validation...');
      await _fetchRouteData(silent: true);
      debugPrint('🔄 [ADVANCE] After refresh: _currentStopIndex: $_currentStopIndex / ${_stops.length}');
    }

    if (_currentStopIndex < _stops.length) {
      final currentStudent = _stops[_currentStopIndex];
      bool isResolved = false;

      debugPrint('🔄 [ADVANCE] Current student: ${currentStudent.nameAr} (id: ${currentStudent.id})');
      debugPrint('🔄 [ADVANCE]   isBoarded: ${currentStudent.isBoarded}');
      debugPrint('🔄 [ADVANCE]   isDroppedOff: ${currentStudent.isDroppedOff}');
      debugPrint('🔄 [ADVANCE]   isAbsent: ${currentStudent.isAbsent}');

      if (isMorning) {
        // In morning: boarded, absent, or waiting (parent notified, driver can proceed)
        // The supervisor handles marking boarding separately.
        isResolved = currentStudent.isBoarded || currentStudent.isAbsent;
        debugPrint('🔄 [ADVANCE] Morning validation: isBoarded=${currentStudent.isBoarded} || isAbsent=${currentStudent.isAbsent} → isResolved=$isResolved');

        // If the driver already notified the parent (student is 'waiting'),
        // they can advance — the boarding will be confirmed by supervisor.
        if (!isResolved && _hasNotified) {
          isResolved = true;
          debugPrint('🔄 [ADVANCE] ✅ Allowing advance because _hasNotified=true');
        }
      } else {
        // In afternoon, they start at school, so we skip validation if they haven't departed school yet.
        if (!_hasDepartedSchool) {
          isResolved = true;
          debugPrint('🔄 [ADVANCE] Afternoon: not departed school yet, skipping validation');
        } else {
          // In afternoon: boarded (still on bus or waiting) means we can drop them off.
          // droppedOff or absent means already resolved.
          isResolved = currentStudent.isDroppedOff || currentStudent.isAbsent || currentStudent.isBoarded;
          debugPrint('🔄 [ADVANCE] Afternoon validation: droppedOff=${currentStudent.isDroppedOff} || absent=${currentStudent.isAbsent} || boarded=${currentStudent.isBoarded} → isResolved=$isResolved');
        }
      }

      debugPrint('🔄 [ADVANCE] Final isResolved: $isResolved');

      if (!isResolved) {
        debugPrint('❌ [ADVANCE] BLOCKED! Student not resolved. Showing error snackbar.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  PhosphorIconsFill.warningCircle,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isArabic 
                      ? 'لا يمكن الانتقال! يرجى تحديد حالة الطالب (${currentStudent.nameAr}) أولاً من صفحة "طلابي" أو من المشرفة.' 
                      : 'Cannot advance! Please determine status for ${currentStudent.nameEn} first from "My Students" or the supervisor.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: isArabic ? 'تحديث' : 'Refresh',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await _fetchRouteData(silent: true);
                } catch (_) {}
              },
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isActionLoading = true;
    });

    try {
      if (isMorning) {
        if (_currentStopIndex < _stops.length) {
          debugPrint('✅ [ADVANCE] Morning: Advancing to next stop. Sorting and routing...');
          setState(() {
            _hasNotified = false;
            _isMovingToStop = false;
            _activeRoutePoints = [];
            _isArrived = false;
            _isActionLoading = false;
          });
          _sortPendingStopsByDistance();
          _fetchRoadFollowingRoute();
        } else {
          setState(() { _isActionLoading = false; });
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isArabic ? 'تأكيد الوصول' : 'Confirm Arrival'),
              content: Text(isArabic ? 'هل وصلت بالفعل إلى المدرسة؟' : 'Have you actually arrived at the school?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(isArabic ? 'نعم، وصلت' : 'Yes, I Arrived'),
                ),
              ],
            ),
          );
          if (confirmed == true && mounted) context.push(AppRoutes.driverEndTrip);
        }
      } else {
        if (!_hasDepartedSchool) {
          setState(() {
            _hasDepartedSchool = true;
            _activeRoutePoints = [];
            _isActionLoading = false;
          });
          _sortPendingStopsByDistance();
          _fetchRoadFollowingRoute();
        } else if (_currentStopIndex < _stops.length) {
          // Mark the current student as dropped off before advancing
          final studentToDrop = _stops[_currentStopIndex];
          if (!studentToDrop.isDroppedOff && !studentToDrop.isAbsent) {
            try {
              await _routeRepository.markStudentDropped(studentId: studentToDrop.id);
              debugPrint('✅ [Navigation] Auto-marked student ${studentToDrop.nameAr} as dropped off');
            } catch (e) {
              debugPrint('⚠️ [Navigation] Failed to mark student dropped: $e');
            }
          }
          setState(() {
            _hasNotified = false;
            _isMovingToStop = false;
            _activeRoutePoints = [];
            _isActionLoading = false;
          });
          await _fetchRouteData(silent: true);
          // Check if all students are now dropped off — if so, end the trip
          if (_currentStopIndex >= _stops.length && !_isFinished) {
            _isFinished = true;
            _statusPollingTimer?.cancel();
            if (mounted) context.push(AppRoutes.driverEndTrip);
            return;
          }
          _sortPendingStopsByDistance();
          _fetchRoadFollowingRoute();
        } else {
          _isFinished = true;
          _statusPollingTimer?.cancel();
          context.push(AppRoutes.driverEndTrip);
        }
      }
    } catch (e) {
      setState(() { _isActionLoading = false; });
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
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'خطأ: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: _fetchRouteData,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : (_routeRepository.currentTripStatus != 'in_progress' &&
             _routeRepository.currentTripStatus != 'awaiting_confirmation' &&
             _routeRepository.currentTripStatus != 'awaiting_video')
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassCard(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIconsBold.bus,
                          size: 48,
                          color: Colors.blue[400],
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                       .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1200.ms),
                      const SizedBox(height: 24),
                      Text(
                        isArabic ? 'لا توجد رحلة نشطة' : 'No Active Trip',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic 
                            ? 'لا توجد رحلة قيد التشغيل في الوقت الحالي. يرجى بدء الرحلة من الشاشة الرئيسية أولاً.'
                            : 'There is no active trip at the moment. Please start a trip from the home screen first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      PremiumButton(
                        height: 55,
                        borderRadius: 18,
                        text: isArabic ? 'العودة للرئيسية' : 'Back to Home',
                        icon: PhosphorIconsBold.house,
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.driverHome);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _fetchRouteData(),
                        icon: Icon(PhosphorIconsBold.arrowsClockwise, size: 18, color: Colors.blue[400]),
                        label: Text(
                          isArabic ? 'تحديث الحالة' : 'Refresh Status',
                          style: TextStyle(color: Colors.blue[400], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  myLocationButtonEnabled: false, // Using custom button
                  zoomControlsEnabled: false,
                  onCameraMove: (position) {
                    // If user moves camera manually, disable followMe
                  },
                  onCameraMoveStarted: () {
                    // If the move was NOT programmatic, it's manual -> disable followMe
                    if (!_isProgrammaticMove && _followMe) {
                      setState(() {
                        _followMe = false;
                      });
                    }
                  },
                  onCameraIdle: () {
                    // Reset programmatic flag when camera stops moving
                    _isProgrammaticMove = false;
                  },
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    // Show the first stop's name immediately
                    Future.delayed(const Duration(milliseconds: 500), () {
                      controller.showMarkerInfoWindow(const MarkerId('stop_0'));
                    });
                  },
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
                          secondsRemaining: (_waitingStudent?.id == currentStop.id) ? _secondsRemaining : null,
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

                // 2.5 Follow Me / Recenter Button
                Positioned(
                  right: 20,
                  bottom: 240, // Adjusted to be above the bottom panel
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'qr_scanner',
                        mini: true,
                        backgroundColor: const Color(0xFF10B981), // Emerald/Green for smart scanner
                        foregroundColor: Colors.white,
                        onPressed: () {
                          context.push(
                            AppRoutes.qrScan,
                            extra: {'isTripMode': true},
                          );
                        },
                        child: const Icon(
                          PhosphorIconsBold.qrCode,
                        ),
                      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'recenter',
                        mini: true,
                        backgroundColor: _followMe ? Colors.blue[700] : Colors.white,
                        foregroundColor: _followMe ? Colors.white : Colors.blue[700],
                        onPressed: () async {
                          setState(() {
                            _followMe = !_followMe;
                          });
                          if (_followMe && _currentPosition != null) {
                            final controller = await _controller.future;
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(_currentPosition!, 16),
                            );
                          }
                        },
                        child: Icon(
                          _followMe 
                              ? PhosphorIconsBold.navigationArrow 
                              : PhosphorIconsBold.crosshair,
                        ),
                      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                    ],
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
                                    _remainingTime,
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
                                  Text(
                                    _remainingDistance,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().slideY(begin: 1, end: 0, duration: 400.ms),
                        
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
                                                ? 'الطالب  مسجل كغائب اليوم.'
                                                : ' is marked absent today.',
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
                                            begin: AlignmentDirectional.centerStart,
                                            end: AlignmentDirectional.centerEnd,
                                          )
                                        : const LinearGradient(
                                            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                                            begin: AlignmentDirectional.topStart,
                                            end: AlignmentDirectional.bottomEnd,
                                          )),
                                icon: (currentStop?.isAbsent == true && !isSchoolState)
                                    ? PhosphorIconsBold.skipForward
                                    : (_hasNotified || isSchoolState || !_isMovingToStop
                                        ? PhosphorIconsBold.arrowRight
                                        : PhosphorIconsBold.mapPin),
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
                                    if (_hasNotified) {
                                      _advanceToNextStop();
                                    } else if (!_isMovingToStop) {
                                      setState(() { _isMovingToStop = true; });
                                    } else {
                                      _handleNearHouse();
                                    }
                                  }
                                },
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
          if (_isGpsDisabled)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withOpacity(0.65),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.gps_off_rounded,
                              size: 54,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isArabic ? 'تتبع الرحلة متوقف!' : 'Trip Tracking Paused!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isArabic
                                ? 'لقد قمت بإيقاف تشغيل خدمة الموقع (GPS). لسلامة الطلاب ومتابعة الرحلة، لا يمكنك إكمال الرحلة أو القيام بأي إجراء حتى تقوم بتفعيل خدمة الموقع مرة أخرى.'
                                : 'You have disabled GPS/Location services. For student safety and trip progress, you cannot continue or perform any actions until location services are enabled again.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.settings, size: 20),
                            label: Text(
                              isArabic ? 'تفعيل خدمة الموقع (GPS)' : 'Enable Location (GPS)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              await Geolocator.openLocationSettings();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getActionButtonText(
    bool isArabic,
    bool isSchoolState,
    bool isMorning,
    StudentStop? currentStop,
  ) {
    if (_isFinished) return isArabic ? 'الرحلة منتهية' : 'Trip Finished';
    if (currentStop?.isAbsent == true && !isSchoolState) {
      return isArabic ? 'تخطي الطالب (غائب)' : 'Skip Student (Absent)';
    }
    if (isSchoolState) {
      if (isMorning) return isArabic ? '🏫 الوصول إلى المدرسة' : '🏫 Arrive at School';
      return isArabic ? '🚀 مغادرة المدرسة' : '🚀 Depart School';
    }

    if (_hasNotified) {
      final baseText = isArabic ? 'الانتقال للوجهة التالية' : 'Next Destination';
      if (_waitingStudent?.id == currentStop?.id && _waitingTimer?.isActive == true) {
        if (_secondsRemaining > 0) {
          final minutes = _secondsRemaining ~/ 60;
          final seconds = _secondsRemaining % 60;
          final timerText = '(${minutes}:${seconds.toString().padLeft(2, '0')})';
          return '$baseText $timerText';
        } else {
          final extraSeconds = _secondsRemaining.abs();
          final minutes = extraSeconds ~/ 60;
          final seconds = extraSeconds % 60;
          final timerText = '(+${minutes}:${seconds.toString().padLeft(2, '0')})';
          return '$baseText $timerText';
        }
      }
      return baseText;
    }
    
    if (!_isMovingToStop) {
      return isArabic ? 'الانتقال للوجهة التالية' : 'Next Destination';
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


class _NextStopCard extends StatelessWidget {
  const _NextStopCard({required this.isArabic, required this.stop, this.secondsRemaining});

  final bool isArabic;
  final StudentStop stop;
  final int? secondsRemaining;

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
              backgroundImage: NetworkImage(stop.photoUrl ?? ''),
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
          if (secondsRemaining != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (secondsRemaining! <= 0)
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (secondsRemaining! <= 0)
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsFill.timer,
                    size: 18,
                    color: (secondsRemaining! <= 0) ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondsRemaining! > 0 ? "${(secondsRemaining! ~/ 60)}:${(secondsRemaining! % 60).toString().padLeft(2, '0')}" : "+${(secondsRemaining!.abs() ~/ 60)}:${(secondsRemaining!.abs() % 60).toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: (secondsRemaining! <= 0) ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    )
    .animate(key: ValueKey(stop.nameEn))
    .fadeIn()
    .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
