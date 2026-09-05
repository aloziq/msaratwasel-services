import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_services/config/app_config.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/services/reverb_service.dart';
import 'package:msaratwasel_services/features/driver/route/domain/entities/student_stop.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:msaratwasel_services/core/utils/location_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class SupervisorTrackingState {}

class SupervisorTrackingInitial extends SupervisorTrackingState {}

class SupervisorTrackingLoading extends SupervisorTrackingState {}

class SupervisorTrackingLoaded extends SupervisorTrackingState {
  final List<StudentStop> stops;
  final LatLng? busPosition;
  final LatLng? schoolPosition;
  final LatLng? targetPosition;
  final String tripType;
  final double speed;
  final double heading;
  final String busNumber;
  final List<LatLng> polylinePoints;
  final bool hasActiveTrip;

  SupervisorTrackingLoaded({
    required this.stops,
    this.busPosition,
    this.schoolPosition,
    this.targetPosition,
    required this.tripType,
    this.speed = 0,
    this.heading = 0,
    required this.busNumber,
    this.polylinePoints = const [],
    this.hasActiveTrip = true,
  });

  SupervisorTrackingLoaded copyWith({
    List<StudentStop>? stops,
    LatLng? busPosition,
    LatLng? schoolPosition,
    LatLng? targetPosition,
    String? tripType,
    double? speed,
    double? heading,
    String? busNumber,
    List<LatLng>? polylinePoints,
    bool? hasActiveTrip,
  }) {
    return SupervisorTrackingLoaded(
      stops: stops ?? this.stops,
      busPosition: busPosition ?? this.busPosition,
      schoolPosition: schoolPosition ?? this.schoolPosition,
      targetPosition: targetPosition ?? this.targetPosition,
      tripType: tripType ?? this.tripType,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      busNumber: busNumber ?? this.busNumber,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      hasActiveTrip: hasActiveTrip ?? this.hasActiveTrip,
    );
  }
}

class SupervisorTrackingError extends SupervisorTrackingState {
  final String message;
  SupervisorTrackingError(this.message);
}

class SupervisorTrackingCubit extends Cubit<SupervisorTrackingState> {
  final int busId;
  ReverbService? _reverbService;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _connectivitySubscription;
  Timer? _pollingTimer;

  DateTime? _lastRouteFetchTime;
  LatLng? _lastFetchBusPosition;
  LatLng? _lastTargetPosition;

  SupervisorTrackingCubit({required this.busId}) : super(SupervisorTrackingInitial());

  Future<void> init({bool silent = false}) async {
    if (_connectivitySubscription == null) {
      _initConnectivityListener();
    }
    if (!silent) {
      emit(SupervisorTrackingLoading());
    }
    try {
      final dio = ApiClient.instance;
      
      // 1. Fetch passengers (student houses)
      final response = await dio.get('bus/$busId/passengers');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load bus details');
      }

      final busInfo = response.data['bus'] ?? {};
      final String rawTripType = busInfo['trip_type'] ?? 'morning';
      final String tripType = (rawTripType == 'forth' || rawTripType == 'morning') ? 'morning' : 'afternoon';
      final String busNumber = busInfo['bus_number'] ?? '#$busId';
      final bool hasActiveTrip = busInfo['has_active_trip'] == true;
      
      final List passengersJson = response.data['passengers'] ?? [];
      final stops = passengersJson.map((json) {
        final rawStatus = json['status']?.toString() ?? '';
        final lastEvent = json['lastEvent'];
        final isMorning = tripType == 'morning';
        final expectedDirection = isMorning ? 'to_school' : 'to_home';
        final isDroppedOff = (lastEvent != null &&
            lastEvent['type'] == 'alighting' &&
            lastEvent['direction'] == expectedDirection) ||
            (isMorning && (rawStatus == 'atSchool' || rawStatus == 'dropped')) ||
            (!isMorning && (rawStatus == 'atHome' || rawStatus == 'dropped'));
            
        final isOnBus = (json['isOnBus'] == true || rawStatus == 'onBus' || rawStatus == 'boarded') && !isDroppedOff;
            
        final isAbsent = json['isAbsent'] == true || rawStatus == 'absent';

        // Student location logic based on trip type
        var lat = isMorning ? json['forth_latitude'] : json['back_latitude'];
        var lng = isMorning ? json['forth_longitude'] : json['back_longitude'];

        // Fallback
        if (lat == null || lat == 0.0) {
          lat = json['latitude'] ?? 0.0;
          lng = json['longitude'] ?? 0.0;
        }

        return StudentStop(
          id: json['id'].toString(),
          nameAr: json['name'] ?? '',
          nameEn: json['name'] ?? '',
          parentAr: json['parentName'] ?? '',
          parentEn: json['parentName'] ?? '',
          location: LatLng(
            double.tryParse(lat?.toString() ?? '') ?? 0.0,
            double.tryParse(lng?.toString() ?? '') ?? 0.0,
          ),
          parentUserId: json['parentUserId']?.toString(),
          isAbsent: isAbsent,
          isBoarded: isOnBus,
          isDroppedOff: isDroppedOff,
          photoUrl: json['photoUrl'],
        );
      }).toList();
      
      LatLng? schoolPos;
      if (busInfo['school_lat'] != null && busInfo['school_lng'] != null) {
        schoolPos = LatLng(
          double.parse(busInfo['school_lat'].toString()),
          double.parse(busInfo['school_lng'].toString()),
        );
      }

      // 2. Fetch current bus location
      final locResponse = await dio.get('bus/$busId/location');
      LatLng? currentBusPos;
      LatLng? targetPos;
      double speed = 0;
      double heading = 0;
      
      if (locResponse.statusCode == 200) {
        final locData = locResponse.data; // Data is at root
        if (locData['latitude'] != null && locData['latitude'] != 0 && locData['latitude'] != "0") {
          currentBusPos = LatLng(
            double.parse(locData['latitude'].toString()),
            double.parse(locData['longitude'].toString()),
          );
          speed = double.tryParse(locData['speed_kmh']?.toString() ?? '0') ?? 0;
          heading = double.tryParse(locData['heading']?.toString() ?? '0') ?? 0;
        }
        if (locData['target_lat'] != null && locData['target_lng'] != null) {
          final tLat = double.tryParse(locData['target_lat'].toString());
          final tLng = double.tryParse(locData['target_lng'].toString());
          if (tLat != null && tLng != null && tLat != 0.0 && tLng != 0.0) {
            targetPos = LatLng(tLat, tLng);
          }
        }
      }

      // If bus location is missing, use school location as fallback to avoid "the sea"
      currentBusPos ??= schoolPos;

      emit(SupervisorTrackingLoaded(
        stops: stops,
        busPosition: currentBusPos,
        schoolPosition: schoolPos,
        targetPosition: targetPos,
        tripType: tripType,
        speed: speed,
        heading: heading,
        busNumber: busNumber,
        hasActiveTrip: hasActiveTrip,
      ));

      // 3. Calculate initial route
      _calculateRoute();

      // 4. Connect to Reverb for real-time updates
      _initReverb();
      
      // 5. Start background periodic polling as fallback
      _startPolling();
      
    } catch (e) {
      String errMsg = 'تأكد من اتصالك بالإنترنت';
      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          errMsg = e.response!.data['message'] ?? e.response!.data['error'] ?? 'حدث خطأ أثناء تحميل البيانات';
        } else {
          errMsg = 'فشل الاتصال بالخادم (رمز الخطأ: ${e.response?.statusCode ?? 'غير معروف'})';
        }
      } else {
        errMsg = e.toString();
      }
      if (!silent) {
        emit(SupervisorTrackingError(errMsg));
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // تم التعديل للاعتماد على التحديث الدوري المتباعد كأمان إضافي فقط لتجنب الضغط على السيرفر
    _pollingTimer = Timer.periodic(const Duration(seconds: AppConfig.statusPollingIntervalSeconds), (timer) {
      if (!isClosed) {
        init(silent: true);
      }
    });
  }

  void _initConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // Support both List<ConnectivityResult> (v6.0+) and single ConnectivityResult (v5.0-)
      final List<ConnectivityResult> resultsList = results is List<ConnectivityResult>
          ? results
          : [results as ConnectivityResult];

      final hasConnection = resultsList.any((result) => result != ConnectivityResult.none);

      if (hasConnection && state is SupervisorTrackingError) {
        init(silent: false);
      }
    });
  }

  void _initReverb() {
    final prefs = GetIt.instance<SharedPreferences>();
    final userIdStr = prefs.getString('USER_ID') ?? '';
    final userId = int.tryParse(userIdStr) ?? 0;

    _reverbService = ReverbService(
      userId: userId,
      dio: ApiClient.instance,
      onMessageReceived: (data) {
        // Extract the actual payload from the wrapper 'data' field if it exists
        final eventData = data.containsKey('data') && data['data'] is Map
            ? data['data'] as Map
            : data;

        if (eventData.containsKey('latitude') && eventData.containsKey('longitude')) {
          if (state is SupervisorTrackingLoaded) {
            final loaded = state as SupervisorTrackingLoaded;
            final lat = double.tryParse(eventData['latitude']?.toString() ?? '');
            final lng = double.tryParse(eventData['longitude']?.toString() ?? '');
            final speed = double.tryParse(eventData['speed_kmh']?.toString() ?? '0') ?? 0;
            final heading = double.tryParse(eventData['heading']?.toString() ?? '0') ?? 0;
            final targetLat = double.tryParse(eventData['target_lat']?.toString() ?? '');
            final targetLng = double.tryParse(eventData['target_lng']?.toString() ?? '');

            if (lat != null && lng != null) {
              final newPos = LatLng(lat, lng);
              LatLng? newTargetPos;
              if (targetLat != null && targetLng != null && targetLat != 0.0 && targetLng != 0.0) {
                newTargetPos = LatLng(targetLat, targetLng);
              }
              emit(loaded.copyWith(
                busPosition: newPos,
                targetPosition: newTargetPos,
                speed: speed,
                heading: heading,
              ));
              
              // Recalculate route if moved significantly or if no points exist
              _calculateRoute();
            }
          }
        } else {
          // Refresh full data silently if student status changes
          init(silent: true);
        }
      }
    );
    _reverbService!.connect();
    _reverbService!.subscribe('private-bus.$busId');
  }

  Future<void> _calculateRoute() async {
    if (state is! SupervisorTrackingLoaded) return;
    final loaded = state as SupervisorTrackingLoaded;
    
    final origin = loaded.busPosition;
    final stops = loaded.stops;
    final school = loaded.schoolPosition;
    
    if (origin == null) return;

    // Determine target based on backend if available, otherwise fall back to client-side logic
    LatLng? target = loaded.targetPosition;
    if (target == null || (target.latitude == 0.0 && target.longitude == 0.0)) {
      if (loaded.tripType == 'morning') {
        try {
          final nextStop = stops.firstWhere(
            (s) => !s.isBoarded && !s.isAbsent && s.location.latitude != 0.0 && s.location.longitude != 0.0
          );
          target = nextStop.location;
        } catch (_) {
          // All students boarded or absent, go to school
          target = school;
        }
      } else {
        try {
          final nextStop = stops.firstWhere(
            (s) => !s.isDroppedOff && !s.isAbsent && s.location.latitude != 0.0 && s.location.longitude != 0.0
          );
          target = nextStop.location;
        } catch (_) {
          // All students dropped off, target is null (trip finished) or school if needed
          target = null;
        }
      }
    }

    if (target == null || (target.latitude == 0 && target.longitude == 0)) return;

    final now = DateTime.now();

    // Check if target changed
    final bool targetChanged = _lastTargetPosition == null ||
        (_lastTargetPosition!.latitude - target.latitude).abs() > 0.0001 ||
        (_lastTargetPosition!.longitude - target.longitude).abs() > 0.0001;

    // Check distance moved since last route fetch
    double distanceMoved = 0.0;
    if (_lastFetchBusPosition != null) {
      distanceMoved = LocationUtils.calculateDistance(
        origin.latitude,
        origin.longitude,
        _lastFetchBusPosition!.latitude,
        _lastFetchBusPosition!.longitude,
      );
    }

    // Only request Google Directions API if destination changed, or bus has moved > 80m and 25s elapsed
    final bool shouldFetch = _lastRouteFetchTime == null ||
        targetChanged ||
        (distanceMoved > 80.0 && now.difference(_lastRouteFetchTime!).inSeconds > 25);

    if (!shouldFetch) {
      return;
    }

    _lastRouteFetchTime = now;
    _lastFetchBusPosition = origin;
    _lastTargetPosition = target;

    try {
      final dio = Dio(); // Use fresh Dio for external API
      final url = "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${target.latitude},${target.longitude}&key=${AppConfig.googleMapsApiKey}";
      
      final response = await dio.get(url);
      print("🚦 [Route] Status: ${response.data['status']}");
      
      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final route = response.data['routes'][0];
        final points = _decodePolyline(route['overview_polyline']['points']);
        if (!isClosed) {
          emit(loaded.copyWith(polylinePoints: points));
        }
      } else {
        print("🚦 [Route] Error details: ${response.data['error_message'] ?? 'No message'}");
      }
    } catch (e) {
      // Fallback: straight line
      if (!isClosed) {
        emit(loaded.copyWith(polylinePoints: [origin, target]));
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _connectivitySubscription?.cancel();
    _reverbService?.dispose();
    _locationSubscription?.cancel();
    return super.close();
  }
}
