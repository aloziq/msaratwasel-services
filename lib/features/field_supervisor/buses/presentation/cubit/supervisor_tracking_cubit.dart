import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/services/reverb_service.dart';
import 'package:msaratwasel_services/features/driver/route/domain/entities/student_stop.dart';
import 'package:msaratwasel_services/features/driver/route/data/models/student_stop_model.dart';
import 'dart:async';

abstract class SupervisorTrackingState {}

class SupervisorTrackingInitial extends SupervisorTrackingState {}

class SupervisorTrackingLoading extends SupervisorTrackingState {}

class SupervisorTrackingLoaded extends SupervisorTrackingState {
  final List<StudentStop> stops;
  final LatLng? busPosition;
  final LatLng? schoolPosition;
  final String tripType;
  final double speed;
  final double heading;
  final String busNumber;
  final List<LatLng> polylinePoints;

  SupervisorTrackingLoaded({
    required this.stops,
    this.busPosition,
    this.schoolPosition,
    required this.tripType,
    this.speed = 0,
    this.heading = 0,
    required this.busNumber,
    this.polylinePoints = const [],
  });

  SupervisorTrackingLoaded copyWith({
    List<StudentStop>? stops,
    LatLng? busPosition,
    LatLng? schoolPosition,
    String? tripType,
    double? speed,
    double? heading,
    String? busNumber,
    List<LatLng>? polylinePoints,
  }) {
    return SupervisorTrackingLoaded(
      stops: stops ?? this.stops,
      busPosition: busPosition ?? this.busPosition,
      schoolPosition: schoolPosition ?? this.schoolPosition,
      tripType: tripType ?? this.tripType,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      busNumber: busNumber ?? this.busNumber,
      polylinePoints: polylinePoints ?? this.polylinePoints,
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
  
  // Google Maps API Key from the driver app context
  static const String _apiKey = "AIzaSyA2ZcFQqhauhU3l-Rj36fbRYomIO7L-ahs";

  SupervisorTrackingCubit({required this.busId}) : super(SupervisorTrackingInitial());

  Future<void> init() async {
    emit(SupervisorTrackingLoading());
    try {
      final dio = ApiClient.instance;
      
      // 1. Fetch passengers (student houses)
      final response = await dio.get('bus/$busId/passengers');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load bus details');
      }

      final busInfo = response.data['bus'] ?? {};
      final String tripType = busInfo['trip_type'] ?? 'morning';
      final String busNumber = busInfo['bus_number'] ?? '#$busId';
      
      final List passengersJson = response.data['passengers'] ?? [];
      final stops = passengersJson.map((json) {
        final isOnBus = json['isOnBus'] == true;
        final lastEvent = json['lastEvent'];
        final isDroppedOff = lastEvent != null && lastEvent['type'] == 'alighting';
        final isAbsent = json['isAbsent'] == true || json['status'] == 'absent';

        // Student location logic based on trip type
        final isMorning = tripType == 'morning';
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
      }

      // If bus location is missing, use school location as fallback to avoid "the sea"
      currentBusPos ??= schoolPos;

      emit(SupervisorTrackingLoaded(
        stops: stops,
        busPosition: currentBusPos,
        schoolPosition: schoolPos,
        tripType: tripType,
        speed: speed,
        heading: heading,
        busNumber: busNumber,
      ));

      // 3. Calculate initial route
      _calculateRoute();

      // 4. Connect to Reverb for real-time updates
      _initReverb();
      
    } catch (e) {
      emit(SupervisorTrackingError(e.toString()));
    }
  }

  void _initReverb() {
    _reverbService = ReverbService(
      dio: ApiClient.instance,
      onBusLocationUpdated: (data) {
        if (state is SupervisorTrackingLoaded) {
          final loaded = state as SupervisorTrackingLoaded;
          final lat = double.tryParse(data['latitude']?.toString() ?? '');
          final lng = double.tryParse(data['longitude']?.toString() ?? '');
          final speed = double.tryParse(data['speed_kmh']?.toString() ?? '0') ?? 0;
          final heading = double.tryParse(data['heading']?.toString() ?? '0') ?? 0;

          if (lat != null && lng != null) {
            final newPos = LatLng(lat, lng);
            emit(loaded.copyWith(
              busPosition: newPos,
              speed: speed,
              heading: heading,
            ));
            
            // Recalculate route if moved significantly or if no points exist
            _calculateRoute();
          }
        }
      },
      onStudentLocationUpdated: (_) {
        // Refresh full data if student status changes
        init();
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

    // Determine target based on trip type and progress
    LatLng? target;
    if (loaded.tripType == 'morning') {
      try {
        final nextStop = stops.firstWhere((s) => !s.isBoarded && !s.isAbsent);
        target = nextStop.location;
      } catch (_) {
        // All students boarded or absent, go to school
        target = school;
      }
    } else {
      try {
        final nextStop = stops.firstWhere((s) => !s.isDroppedOff && !s.isAbsent);
        target = nextStop.location;
      } catch (_) {
        // All students dropped off, target is null (trip finished) or school if needed
        target = null;
      }
    }

    if (target == null || (target.latitude == 0 && target.longitude == 0)) return;

    try {
      final dio = Dio(); // Use fresh Dio for external API
      final url = "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${target.latitude},${target.longitude}&key=$_apiKey";
      
      final response = await dio.get(url);
      print("🚦 [Route] Status: ${response.data['status']}");
      
      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final route = response.data['routes'][0];
        final points = _decodePolyline(route['overview_polyline']['points']);
        print("🚦 [Route] Success: Found ${points.length} points");
        
        emit(loaded.copyWith(polylinePoints: points));
      } else {
        print("🚦 [Route] Error details: ${response.data['error_message'] ?? 'No message'}");
      }
    } catch (e) {
      // Fallback: straight line
      emit(loaded.copyWith(polylinePoints: [origin, target]));
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
    _reverbService?.dispose();
    _locationSubscription?.cancel();
    return super.close();
  }
}
