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
import 'package:connectivity_plus/connectivity_plus.dart';

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
  StreamSubscription? _connectivitySubscription;
  List<Map<String, dynamic>> _navigationSteps = [];
  int _consecutiveOffRouteUpdates = 0;

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
  Set<Polyline> _polylines = {};
  bool _isArrived = false;
  bool _isActionLoading = false;
  bool _isSyncingStops = false;
  bool _followMe = true; // Automatically follow the bus
  bool _isRouteOverview = false; // Toggle for in-map route overview
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
  DateTime? _lastUpdateLocationTime;
  Timer? _statusPollingTimer;
  Timer? _locationTimer;
  int _simStep = 0;
  LatLng? _currentPosition;
  List<LatLng> _activeRoutePoints = []; // Road-following points
  final Map<String, List<LatLng>> _cachedRoutesToTarget = {}; // Cache for routes
  double? _remainingDistanceKm;
  int? _remainingTimeMin;

  String get _remainingTime {
    if (_remainingTimeMin == null) return '--';
    final isArabic = mounted ? (Localizations.localeOf(context).languageCode == 'ar') : true;
    return '$_remainingTimeMin ${isArabic ? 'دقيقة' : 'min'}';
  }

  String get _remainingDistance {
    if (_remainingDistanceKm == null) return '--';
    final isArabic = mounted ? (Localizations.localeOf(context).languageCode == 'ar') : true;
    return '${_remainingDistanceKm!.toStringAsFixed(1)} ${isArabic ? 'كم' : 'km'}';
  }

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
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final List<ConnectivityResult> resultsList = results is List<ConnectivityResult>
          ? results
          : [results as ConnectivityResult];

      final hasConnection = resultsList.any((result) => result != ConnectivityResult.none);

      if (hasConnection && _error != null) {
        debugPrint('🌐 [Navigation] Connection restored, auto-retrying fetchRouteData...');
        _fetchRouteData(silent: false);
      }
    });
  }

  Future<void> _showRouteOverview() async {
    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء الانتظار حتى يتم تحديد موقعك (GPS)...'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _followMe = false;
    });

    final controller = await _controller.future;

    List<LatLng> points = [];
    points.add(_currentPosition!);
    
    if (_activeRoutePoints.isNotEmpty) {
      points.addAll(_activeRoutePoints);
    } else {
      final target = _currentTarget;
      if (target != null) {
        points.add(target);
      }
    }

    if (points.length < 2) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _isProgrammaticMove = true;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
    );
  }

  String _cleanHtmlInstruction(String htmlStr) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    String cleanStr = htmlStr.replaceAll(exp, ' ');
    cleanStr = cleanStr.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleanStr;
  }

  bool _checkIfOffRoute(LatLng currentPos) {
    if (_activeRoutePoints.isEmpty) return false;

    double minDistance = double.infinity;

    for (final point in _activeRoutePoints) {
      final double distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    debugPrint('🛣️ [Navigation] Distance to route path: ${minDistance.toStringAsFixed(1)}m');
    return minDistance > 65.0;
  }

  // Unified navigation + student card
  Widget _buildInstructionCard(bool isArabic, ThemeData theme, StudentStop? currentStop) {
    if (_navigationSteps.isEmpty && currentStop == null) return const SizedBox.shrink();
    
    IconData turnIcon = PhosphorIconsBold.arrowUp;
    String distanceText = '';
    String mainAction = isArabic ? 'استمر' : 'Keep straight';
    String streetName = isArabic ? 'جاري حساب الطريق...' : 'Calculating route...';
    
    if (_navigationSteps.isNotEmpty) {
      final nextStep = _navigationSteps.first;
      final rawInstruction = nextStep['html_instructions'] ?? '';
      final cleanInstruction = _cleanHtmlInstruction(rawInstruction);
      distanceText = nextStep['distance']?['text'] ?? '';
      final lowercaseInstruction = cleanInstruction.toLowerCase();
      
      if (lowercaseInstruction.contains('يمي') || lowercaseInstruction.contains('right')) {
        turnIcon = PhosphorIconsBold.arrowRight;
      } else if (lowercaseInstruction.contains('يسار') || lowercaseInstruction.contains('left')) {
        turnIcon = PhosphorIconsBold.arrowLeft;
      } else if (lowercaseInstruction.contains('دوار') || lowercaseInstruction.contains('roundabout')) {
        turnIcon = PhosphorIconsBold.arrowsClockwise;
      } else if (lowercaseInstruction.contains('يو تيرن') || lowercaseInstruction.contains('u-turn')) {
        turnIcon = PhosphorIconsBold.arrowUUpLeft;
      }
      
      // Action & street parsing
      if (!isArabic) {
        if (lowercaseInstruction.contains('turn right')) {
          mainAction = 'Turn Right';
        } else if (lowercaseInstruction.contains('turn left')) {
          mainAction = 'Turn Left';
        } else if (lowercaseInstruction.contains('roundabout')) {
          mainAction = 'Roundabout';
        } else if (lowercaseInstruction.contains('u-turn')) {
          mainAction = 'U-Turn';
        } else if (lowercaseInstruction.contains('keep straight') || lowercaseInstruction.contains('continue')) {
          mainAction = 'Keep Straight';
        }
        
        final ontoIndex = lowercaseInstruction.indexOf('onto ');
        if (ontoIndex != -1) {
          streetName = cleanInstruction.substring(ontoIndex + 5).trim();
        } else {
          final towardIndex = lowercaseInstruction.indexOf('toward ');
          if (towardIndex != -1) {
            streetName = cleanInstruction.substring(towardIndex + 7).trim();
          } else {
            streetName = cleanInstruction;
          }
        }
      } else {
        if (lowercaseInstruction.contains('يمي') || lowercaseInstruction.contains('اليمين')) {
          mainAction = 'اتجه يميناً';
        } else if (lowercaseInstruction.contains('يسار') || lowercaseInstruction.contains('اليسار')) {
          mainAction = 'اتجه يساراً';
        } else if (lowercaseInstruction.contains('دوار')) {
          mainAction = 'اسلك الدوار';
        } else if (lowercaseInstruction.contains('الخلف') || lowercaseInstruction.contains('دوران')) {
          mainAction = 'دوران للخلف';
        } else if (lowercaseInstruction.contains('مستقيم') || lowercaseInstruction.contains('استمر')) {
          mainAction = 'استمر في المسار';
        }
        
        final indexInto = cleanInstruction.indexOf('نحو ');
        if (indexInto != -1) {
          streetName = cleanInstruction.substring(indexInto + 4).trim();
        } else {
          final indexIn = cleanInstruction.indexOf('في ');
          if (indexIn != -1) {
            streetName = cleanInstruction.substring(indexIn + 3).trim();
          } else {
            final indexStreet = cleanInstruction.indexOf('شارع');
            if (indexStreet != -1) {
              streetName = cleanInstruction.substring(indexStreet).trim();
            } else {
              streetName = cleanInstruction;
            }
          }
        }
      }
    }
    
    final isRtl = isArabic;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D3321).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF198754).withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Row 1: Navigation direction ──
              if (_navigationSteps.isNotEmpty)
                Row(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    // Direction icon circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(turnIcon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    // Distance + action label + street
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                            children: [
                              if (distanceText.isNotEmpty) ...[
                                Text(
                                  distanceText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF198754).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  mainAction,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (streetName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              streetName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Compact time/distance pill
                    if (_remainingTimeMin != null || _remainingDistanceKm != null)
                      Container(
                        margin: EdgeInsets.only(
                          left: isRtl ? 0 : 8,
                          right: isRtl ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_remainingTimeMin != null)
                              Text(
                                '$_remainingTimeMin${isArabic ? 'د' : 'm'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.orange,
                                ),
                              ),
                            if (_remainingDistanceKm != null)
                              Text(
                                '${_remainingDistanceKm!.toStringAsFixed(1)}${isArabic ? 'كم' : 'km'}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),

              // ── Divider + Row 2: Student info (only when currentStop exists) ──
              if (currentStop != null) ...[
                if (_navigationSteps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                Row(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    // Student avatar with amber ring
                    Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                      ),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundImage: currentStop.photoUrl != null && currentStop.photoUrl!.isNotEmpty
                            ? NetworkImage(currentStop.photoUrl!)
                            : null,
                        backgroundColor: Colors.grey[800],
                        child: currentStop.photoUrl == null || currentStop.photoUrl!.isEmpty
                            ? const Icon(Icons.person, size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isArabic ? 'الوجهة التالية' : 'Next Stop',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.amber[400],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isArabic ? currentStop.nameAr : currentStop.nameEn,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Waiting countdown timer
                    if (_waitingStudent?.id == currentStop.id && _waitingTimer?.isActive == true)
                      Builder(builder: (context) {
                        final bool timeUp = _secondsRemaining <= 0;
                        final Color timerColor = timeUp ? Colors.redAccent : Colors.greenAccent;
                        return Container(
                          margin: EdgeInsets.only(
                            left: isRtl ? 0 : 6,
                            right: isRtl ? 6 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: timerColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: timerColor.withValues(alpha: 0.4), width: 1),
                          ),
                          child: Text(
                            _secondsRemaining > 0
                                ? '${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}'
                                : '+${(_secondsRemaining.abs() ~/ 60)}:${(_secondsRemaining.abs() % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: timerColor,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedProgressBar(bool isArabic, ThemeData theme) {
    if (_stops.isEmpty) return const SizedBox.shrink();
    
    List<Widget> children = [];
    
    for (int i = 0; i < _stops.length; i++) {
      final stop = _stops[i];
      final isCompleted = i < _currentStopIndex;
      final isActive = i == _currentStopIndex;
      
      // 1. Draw the Milestone Node
      Widget node;
      if (isCompleted) {
        // Glowing Emerald Checkmark
        node = Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981), // Emerald
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            ),
          ),
        );
      } else if (isActive) {
        // Glowing electric blue node with pulsing halo
        node = Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8), // Electric Blue
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 1000.ms);
      } else {
        // Semi-transparent upcoming white/gray dot
        node = Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
        );
      }
      
      children.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            node,
            const SizedBox(height: 4),
            Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isActive 
                  ? const Color(0xFF1A73E8) 
                  : (isCompleted ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      );
      
      // 2. Draw Connector Line if not the last node
      if (i < _stops.length - 1) {
        final nextIsCompletedOrActive = i < _currentStopIndex;
        final connectorColor = nextIsCompletedOrActive 
          ? const Color(0xFF10B981) // Completed track is green
          : Colors.white.withValues(alpha: 0.15); // Upcoming track is grey
          
        children.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: connectorColor,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: nextIsCompletedOrActive ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 4,
                    )
                  ] : null,
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic 
                    ? 'المحطة $_currentStopIndex من ${_stops.length}' 
                    : 'Stop $_currentStopIndex of ${_stops.length}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${((_stops.isEmpty ? 0.0 : (_currentStopIndex / _stops.length)) * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ],
      ),
    );
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
        distanceFilter: AppConfig.locationDistanceFilter,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      
      _simStep++;
      final double simulatedLat = AppConfig.enableLocationSimulation
          ? position.latitude + (_simStep * 0.00015)
          : position.latitude;
      final double simulatedLng = AppConfig.enableLocationSimulation
          ? position.longitude + (_simStep * 0.00008)
          : position.longitude;
      final newPos = LatLng(simulatedLat, simulatedLng);
      
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
          final double bearing = (position.heading > 0 && position.heading.isFinite) ? position.heading : 0.0;
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newPos,
                zoom: 17.0,
                bearing: bearing,
                tilt: 35.0,
              ),
            ),
          );
        });
        if (_isFirstLock) _isFirstLock = false;
      }

      // Throttle server uploads: send updates at most once every configured seconds to drastically conserve battery and data!
      final now = DateTime.now();
      if (_lastUpdateLocationTime == null || 
          now.difference(_lastUpdateLocationTime!).inSeconds >= AppConfig.locationUploadThrottleSeconds) {
        _lastUpdateLocationTime = now;
        _routeRepository.updateLocation(
          latitude: simulatedLat,
          longitude: simulatedLng,
          speed: position.speed,
          accuracy: position.accuracy,
          heading: position.heading,
          targetLat: _currentTarget?.latitude,
          targetLng: _currentTarget?.longitude,
        );
      }

      bool isOff = _checkIfOffRoute(newPos);
      if (isOff) {
        _consecutiveOffRouteUpdates++;
        if (_consecutiveOffRouteUpdates >= 2) {
          debugPrint('🚨 [Navigation] Off-Route detected! Recalculating route...');
          _consecutiveOffRouteUpdates = 0;
          _lastRouteFetchTime = null;
          _fetchRoadFollowingRoute();
        }
      } else {
        _consecutiveOffRouteUpdates = 0;
        if (distance > 15 || _activeRoutePoints.isEmpty) {
          _fetchRoadFollowingRoute();
        } else {
          _updatePolylines();
        }
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

    final originStr = "${_currentPosition!.latitude},${_currentPosition!.longitude}";
    final destStr = "${target.latitude},${target.longitude}";
    final cacheKey = destStr;

    // Fast transition: If we have a cached route to this destination, show it immediately 
    // while we fetch the updated one in the background.
    if (_activeRoutePoints.isEmpty && _cachedRoutesToTarget.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _activeRoutePoints = _cachedRoutesToTarget[cacheKey]!;
        });
        _updatePolylines();
      }
    }

    debugPrint("🚀 [Navigation] Requesting Google Directions: $originStr -> $destStr");

    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destStr&key=${AppConfig.googleMapsApiKey}&mode=driving",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("DEBUG: Google Directions API Status: ${data['status']}");
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final points = PolylinePoints.decodePolyline(
            route['overview_polyline']['points'],
          );
          
          debugPrint("✅ [Navigation] Google route decoded: ${points.length} points");

          if (mounted) {
            setState(() {
              _activeRoutePoints = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
              // Save to cache for instant loading next time
              _cachedRoutesToTarget[cacheKey] = _activeRoutePoints;
              
              if (leg['steps'] != null) {
                _navigationSteps = List<Map<String, dynamic>>.from(leg['steps']);
              } else {
                _navigationSteps = [];
              }
              
              final distInKm = (leg['distance']['value'] as num) / 1000;
              final durInMin = (leg['duration']['value'] as num) / 60;
              _remainingDistanceKm = distInKm;
              _remainingTimeMin = durInMin.ceil();
              _lastRouteFetchTime = now;
              _lastFetchTarget = target;
            });
            _updatePolylines();
          }
          return; // Success
        }
      }
      
      // Fallback if Google fails
      debugPrint("❌ [Navigation] Google Directions failed. Using straight line fallback.");
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
      if (mounted) {
        setState(() {
          _activeRoutePoints = []; // Clear old route points so fallback dotted line to target is drawn
        });
        _updatePolylines();
      }
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
        _error = null; // Clear error upon successful connection recovery!
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
    _connectivitySubscription?.cancel();
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
    _updatePolylines();
  }

  Set<Marker> _buildMarkers(bool isArabic) {
    final markers = _stops.asMap().entries.where((entry) => entry.key >= _currentStopIndex).map((entry) {
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
          title: isArabic ? stop.nameAr : stop.nameEn,
          snippet: isNext 
              ? (isArabic ? 'الوجهة الحالية' : 'Current Destination') 
              : '${isArabic ? 'محطة' : 'Station'} ${index + 1}',
        ),
      );
    }).toSet();

    final isMorning = _routeRepository.currentTripType == 'morning';
    final showSchool = isMorning || (!isMorning && !_hasDepartedSchool);

    if (showSchool) {
      markers.add(
        Marker(
          markerId: const MarkerId('school_stop'),
          position: _routeRepository.schoolLocation ?? const LatLng(23.6080, 58.4500),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: isArabic ? 'المدرسة' : 'School',
            snippet: isArabic ? 'الوجهة' : 'Destination',
          ),
        ),
      );
    }
    return markers;
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
          color: const Color(0xFF1A73E8), // Vibrant blue matching parent app
          width: 6,
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
          color: const Color(0xFF1A73E8), // Vibrant blue matching parent app
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
                setState(() {
                  _hasNotified = false;
                  _isMovingToStop = false;
                  _isArrived = false;
                  _isActionLoading = false;
                });
                _sortPendingStopsByDistance();
                _fetchRoadFollowingRoute();
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
            _isArrived = false;
            _isActionLoading = false;
            // DO NOT clear _activeRoutePoints here to prevent flickering. 
            // It will be replaced by the cached route or new route instantly.
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
            _isActionLoading = false;
            // Kept active points to prevent flickering while fetching
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsBold.wifiSlash,
                      size: 48,
                      color: Colors.red.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic ? 'حدث خطأ في الاتصال بالإنترنت' : 'Internet Connection Error',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'سيتم تحديث البيانات تلقائياً عند استعادة الاتصال...'
                          : 'Reconnecting automatically when internet is restored...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF1D1D1F).withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
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
                  ],
                ),
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
                  markers: _buildMarkers(isArabic),
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


                // ── Zone 2: Unified Navigation + Student Card (below top bar) ──
                if (!isSchoolState && !_isRouteOverview)
                  Positioned(
                    top: 96,
                    left: 16,
                    right: 64, // leave room for FABs on the right
                    child: _buildInstructionCard(isArabic, theme, currentStop)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.2, end: 0, duration: 300.ms),
                  ),

                if (isSchoolState && !_isRouteOverview)
                  Positioned(
                    top: 96,
                    left: 16,
                    right: 64,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber[900]!.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsFill.buildings, color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isArabic ? 'الوجهة الحالية' : 'Current Stop',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isArabic ? 'المدرسة' : 'School',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
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

                // ── Route Overview "Return" banner (shown when overview mode is active) ──
                if (_isRouteOverview)
                  Positioned(
                    top: 96,
                    left: 40,
                    right: 40,
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          _isRouteOverview = false;
                          _followMe = true;
                        });
                        if (_currentPosition != null) {
                          final controller = await _controller.future;
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(_currentPosition!, 16),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.blue[700]!.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(PhosphorIconsBold.navigationArrow, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic ? 'العودة للملاحة' : 'Back to Navigation',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.3, end: 0, duration: 250.ms),
                  ),

                // ── Zone 3: Right Side FABs ──
                Positioned(
                  right: 12,
                  top: 96,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MapFab(
                        heroTag: 'route_overview',
                        bgColor: _isRouteOverview ? Colors.blue[700]! : Colors.white,
                        fgColor: _isRouteOverview ? Colors.white : Colors.blue[700]!,
                        icon: _isRouteOverview
                            ? PhosphorIconsBold.navigationArrow
                            : PhosphorIconsBold.mapTrifold,
                        onPressed: () async {
                          if (_isRouteOverview) {
                            // Return to navigation
                            setState(() {
                              _isRouteOverview = false;
                              _followMe = true;
                            });
                            if (_currentPosition != null) {
                              final controller = await _controller.future;
                              controller.animateCamera(
                                CameraUpdate.newLatLngZoom(_currentPosition!, 16),
                              );
                            }
                          } else {
                            // Enter overview mode
                            setState(() => _isRouteOverview = true);
                            _showRouteOverview();
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      if (!_isRouteOverview)
                        _MapFab(
                          heroTag: 'recenter',
                          bgColor: _followMe ? Colors.blue[700]! : Colors.white,
                          fgColor: _followMe ? Colors.white : Colors.blue[700]!,
                          icon: _followMe
                              ? PhosphorIconsBold.navigationArrow
                              : PhosphorIconsBold.crosshair,
                          onPressed: () async {
                            setState(() { _followMe = !_followMe; });
                            if (_followMe && _currentPosition != null) {
                              final controller = await _controller.future;
                              controller.animateCamera(
                                CameraUpdate.newLatLngZoom(_currentPosition!, 16),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),


                // ── Zone 4: Bottom Panel (progress + action button) ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.92),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Drag handle
                              Container(
                                width: 36,
                                height: 3,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              // ── Segmented progress bar ──
                              if (!isSchoolState && _stops.isNotEmpty)
                                _buildSegmentedProgressBar(isArabic, theme)
                                    .animate()
                                    .fadeIn(delay: 150.ms),

                              // ── Absence inline banner ──
                              if (currentStop != null && currentStop.isAbsent && !isSchoolState) ...
                                [
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.redAccent.withValues(alpha: 0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          PhosphorIconsFill.warningCircle,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ).animate(
                                          onPlay: (c) => c.repeat(reverse: true),
                                        ).scale(
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.2, 1.2),
                                          duration: 700.ms,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            isArabic
                                                ? '${currentStop.nameAr} غائب اليوم — يمكنك التخطي'
                                                : '${currentStop.nameEn} is absent — you can skip',
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                              const SizedBox(height: 12),

                              // ── Main action button ──
                              _isActionLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : PremiumButton(
                                      height: 56,
                                      borderRadius: 16,
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
                                    ).slideY(begin: 0.3, end: 0, duration: 350.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Zone 1 (on top): Top bar — SafeArea spacing guaranteed ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
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

/// Compact mini FAB used in the right-side button column on the map.
class _MapFab extends StatelessWidget {
  final String heroTag;
  final Color bgColor;
  final Color fgColor;
  final IconData icon;
  final VoidCallback onPressed;

  const _MapFab({
    required this.heroTag,
    required this.bgColor,
    required this.icon,
    required this.onPressed,
    this.fgColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 2,
      onPressed: onPressed,
      child: Icon(icon, size: 20),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0B192C).withValues(alpha: 0.85),
                const Color(0xFF1E3E62).withValues(alpha: 0.65),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Student Photo Avatar with breathing animation
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(stop.photoUrl ?? ''),
                  onBackgroundImageError: (exception, stackTrace) =>
                      const Icon(Icons.person),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms, curve: Curves.easeInOut)
               .shimmer(color: Colors.white.withValues(alpha: 0.2), duration: 2500.ms),
              const SizedBox(width: 14),
              // Info List
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // LED status pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD230).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFD230).withValues(alpha: 0.4),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD230).withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            isArabic ? 'الوجهة التالية' : 'Next Stop',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber[400],
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (stop.isAbsent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              isArabic ? 'غياب محتمل' : 'Probable Absence',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic ? stop.nameAr : stop.nameEn,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (secondsRemaining != null) ...[
                const SizedBox(width: 12),
                // Monospace stopwatch-style digital countdown timer
                Builder(
                  builder: (context) {
                    final bool timeUp = secondsRemaining! <= 0;
                    final Color timerColor = timeUp ? Colors.redAccent : const Color(0xFF10B981);
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: timerColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: timerColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: timerColor.withValues(alpha: 0.15),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsFill.timer,
                            size: 20,
                            color: timerColor,
                          ).animate(onPlay: (controller) {
                            if (timeUp) controller.repeat(reverse: true);
                          }).scale(
                            begin: const Offset(1, 1),
                            end: timeUp ? const Offset(1.2, 1.2) : const Offset(1.05, 1.05),
                            duration: 800.ms,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            secondsRemaining! > 0 
                              ? "${(secondsRemaining! ~/ 60)}:${(secondsRemaining! % 60).toString().padLeft(2, '0')}" 
                              : "+${(secondsRemaining!.abs() ~/ 60)}:${(secondsRemaining!.abs() % 60).toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: timerColor,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ],
            ],
          ),
        ),
      ),
    )
    .animate(key: ValueKey(stop.nameEn))
    .fadeIn()
    .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
