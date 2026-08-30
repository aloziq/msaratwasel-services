import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/network/api_client.dart';
import '../models/student_stop_model.dart';
import '../../domain/entities/student_stop.dart';
import '../../domain/repositories/route_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@LazySingleton(as: RouteRepository)
class RouteRepositoryImpl implements RouteRepository {
  final Dio _dio;

  RouteRepositoryImpl() : _dio = ApiClient.instance;

  String _currentTripType = 'morning';
  String _currentTripStatus = 'idle';
  LatLng? _schoolLocation;

  @override
  String get currentTripType => _currentTripType;

  @override
  String get currentTripStatus => _currentTripStatus;

  @override
  LatLng? get schoolLocation => _schoolLocation;

  // ✅ T-02: Route points now built from real student locations
  @override
  Future<List<LatLng>> getRoutePoints() async {
    return []; // Route line drawn from student stop locations in the screen
  }

  @override
  Future<List<StudentStop>> getTripStops() async {
    try {
      // 1. Get current user to find bus_id (use cached value if available)
      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        final busId = data['has_bus'] ?? data['bus_id'];
        if (busId != null) {
          _cachedBusId = int.tryParse(busId.toString());
        }
      }

      final busId = _cachedBusId;
      if (busId == null) {
        throw Exception('لا يوجد باص مخصص لهذا الحساب');
      }

      // 2. Fetch passengers
      final response = await _dio.get('bus/$busId/passengers');

      final busInfo = response.data['bus'] ?? {};
      final String rawTripType = busInfo['trip_type'] ?? 'morning';
      _currentTripType = (rawTripType == 'forth' || rawTripType == 'morning')
          ? 'morning'
          : 'afternoon';
      _currentTripStatus = busInfo['trip_status'] ?? 'idle';

      // Parse school coordinates
      final sLat =
          double.tryParse(busInfo['school_lat']?.toString() ?? '0.0') ?? 0.0;
      final sLng =
          double.tryParse(busInfo['school_lng']?.toString() ?? '0.0') ?? 0.0;
      if (sLat != 0.0 || sLng != 0.0) {
        _schoolLocation = LatLng(sLat, sLng);
        debugPrint('🏫 [REPO] School Location: ($sLat, $sLng)');
      }

      final List<dynamic> passengersJson = response.data['passengers'] ?? [];

      return passengersJson.map((json) {
        final rawStatus = json['status']?.toString() ?? '';
        final isMorning = _currentTripType == 'morning';
        final expectedDirection = isMorning ? 'to_school' : 'to_home';
        final lastEvent = json['lastEvent'];

        final isDroppedOff =
            (lastEvent != null &&
                lastEvent['type'] == 'alighting' &&
                lastEvent['direction'] == expectedDirection) ||
            (isMorning && (rawStatus == 'atSchool' || rawStatus == 'dropped')) ||
            (!isMorning && (rawStatus == 'atHome' || rawStatus == 'dropped'));

        final isOnBus = json['isOnBus'] == true || rawStatus == 'onBus' || rawStatus == 'boarded';
        final isWaiting = json['isWaiting'] == true || rawStatus == 'waiting';

        // In afternoon trips, 'waiting' means the student is still on the bus
        // (driver pressed "near house" but student hasn't gotten off yet)
        final effectivelyBoarded =
            (isOnBus || (!isMorning && isWaiting)) && !isDroppedOff;

        debugPrint(
          '👤 [REPO] Passenger: ${json['name']}, status: ${json['status']}, '
          'isWaiting: ${json['isWaiting']}, waitingSince: ${json['waitingSince']}, waitingElapsedSeconds: ${json['waitingElapsedSeconds']}',
        );

        return StudentStopModel(
          id: json['id'].toString(),
          nameAr: json['name'] ?? '',
          nameEn: json['name'] ?? '',
          parentAr: json['parentName'] ?? 'ولي الأمر',
          parentEn: json['parentName'] ?? 'Parent',
          parentUserId: json['parentUserId']?.toString(),
          location: _getStudentLocation(json),
          photoUrl:
              json['photoUrl'] ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(json['name'] ?? 'User')}&background=random',
          isBoarded: effectivelyBoarded,
          isDroppedOff: isDroppedOff,
          isAbsent: json['isAbsent'] == true || json['status'] == 'absent',
          isWaiting: isWaiting,
          waitingSince: json['waitingSince']?.toString(),
          waitingElapsedSeconds:
              int.tryParse(json['waitingElapsedSeconds']?.toString() ?? '0') ??
              0,
        );
      }).toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('فشل جلب قائمة الطلاب: $message');
    } catch (e) {
      throw Exception('فشل جلب قائمة الطلاب: ${e.toString()}');
    }
  }

  @override
  Future<void> markStudentBoarded({required String studentId}) async {
    try {
      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        _cachedBusId = data['bus_id'] ?? data['has_bus'];
      }

      await _dio.post(
        'bus/$_cachedBusId/mark-boarded',
        data: {'student_id': studentId},
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('فشل تسجيل ركوب الطالب: $message');
    } catch (e) {
      throw Exception('فشل تسجيل ركوب الطالب');
    }
  }

  @override
  Future<void> groupBoard({required List<String> studentIds}) async {
    try {
      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        _cachedBusId = data['bus_id'] ?? data['has_bus'];
      }

      await _dio.post(
        'bus/$_cachedBusId/group-board',
        data: {'student_ids': studentIds},
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('فشل تسجيل ركوب الطلاب: $message');
    } catch (e) {
      throw Exception('فشل تسجيل ركوب الطلاب');
    }
  }

  @override
  Future<void> markStudentDropped({required String studentId}) async {
    try {
      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        _cachedBusId = data['bus_id'] ?? data['has_bus'];
      }

      await _dio.post(
        'bus/$_cachedBusId/mark-dropped',
        data: {'student_id': studentId},
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('فشل تسجيل نزول الطالب: $message');
    } catch (e) {
      throw Exception('فشل تسجيل نزول الطالب');
    }
  }

  @override
  Future<void> markStudentAbsent({required String studentId}) async {
    try {
      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        _cachedBusId = data['bus_id'] ?? data['has_bus'];
      }

      await _dio.post(
        'bus/$_cachedBusId/mark-absent',
        data: {'student_id': studentId},
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('فشل تسجيل غياب الطالب: $message');
    } catch (e) {
      throw Exception('فشل تسجيل غياب الطالب');
    }
  }

  @override
  Future<void> notifyParentNearHouse({required String studentId}) async {
    try {
      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        _cachedBusId = data['bus_id'] ?? data['has_bus'];
      }

      await _dio.post(
        'bus/$_cachedBusId/notify-near-house',
        data: {'student_id': studentId},
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('فشل إرسال الإشعار لولي الأمر: $message');
    } catch (e) {
      throw Exception('فشل إرسال الإشعار لولي الأمر');
    }
  }

  @override
  Future<void> arriveAtSchool() async {
    try {
      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        _cachedBusId = data['bus_id'] ?? data['has_bus'];
      }

      await _dio.post('bus/$_cachedBusId/arrive');
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('فشل تحديث الوصول: $message');
    } catch (e) {
      throw Exception('فشل تحديث الوصول');
    }
  }

  @override
  int getOnBoardCount(List<StudentStop> stops) {
    return stops.where((s) => s.isBoarded && !s.isDroppedOff).length;
  }

  @override
  int getUnprocessedCount(List<StudentStop> stops) {
    final isMorning = _currentTripType == 'morning';
    return stops.where((s) {
      if (s.isAbsent) return false;
      if (isMorning) {
        // In morning, processed means Boarded (on bus) or Dropped Off (already at school)
        return !s.isBoarded && !s.isDroppedOff;
      } else {
        // In afternoon, processed means Dropped Off (at home)
        return !s.isDroppedOff;
      }
    }).length;
  }

  int? _cachedBusId;

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    double? accuracy,
    double? targetLat,
    double? targetLng,
  }) async {
    try {
      if (_cachedBusId == null) {
        try {
          final prefs = GetIt.I<SharedPreferences>();
          final busIdStr = prefs.getString('USER_BUS_ID');
          if (busIdStr != null) {
            _cachedBusId = int.tryParse(busIdStr);
          }
        } catch (_) {}
      }

      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        final busId = data['bus_id'] ?? data['has_bus'];
        if (busId != null) {
          _cachedBusId = int.tryParse(busId.toString());
        }
      }

      if (_cachedBusId != null) {
        final timestamp = DateTime.now().toIso8601String();

        debugPrint(
          '📡 [DRIVER] Broadcasting: Bus: $_cachedBusId, Lat: $latitude, Lng: $longitude, Heading: $heading',
        );

        await _dio.post(
          'bus/$_cachedBusId/location',
          data: {
            'bus_id': _cachedBusId,
            'latitude': latitude,
            'longitude': longitude,
            'heading': heading ?? 0.0,
            'speed': speed ?? 15.0, // Default to 15 km/h for simulated speed
            'accuracy': accuracy ?? 0.0,
            if (targetLat != null) 'target_lat': targetLat,
            if (targetLng != null) 'target_lng': targetLng,
            'timestamp': timestamp,
            'sequence_number': DateTime.now().millisecondsSinceEpoch,
          },
        );
        debugPrint('✅ [DRIVER] Broadcast Successful at $timestamp');
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ [DRIVER] Broadcast Failed (Network): ${e.message} - ${e.response?.data}',
      );
    } catch (e) {
      debugPrint('❌ [DRIVER] Broadcast Failed (General): ${e.toString()}');
    }
  }

  LatLng _getStudentLocation(Map<String, dynamic> json) {
    final isMorning = _currentTripType == 'morning';

    // 1. Try trip-specific coordinates first
    var lat = isMorning ? json['forth_latitude'] : json['back_latitude'];
    var lng = isMorning ? json['forth_longitude'] : json['back_longitude'];

    // 2. Fallback to general student coordinates if trip-specific are null/0
    if (_isInvalid(lat) || _isInvalid(lng)) {
      lat = json['latitude'];
      lng = json['longitude'];
    }

    final parsedLat = double.tryParse(lat?.toString() ?? '0.0') ?? 0.0;
    final parsedLng = double.tryParse(lng?.toString() ?? '0.0') ?? 0.0;

    if (parsedLat != 0.0 || parsedLng != 0.0) {
      debugPrint(
        '📍 [REPO] Found location for student: $parsedLat, $parsedLng',
      );
      return LatLng(parsedLat, parsedLng);
    }

    debugPrint(
      '⚠️ [REPO] No valid location for student: ${json['name']}, falling back to school/default',
    );
    // Final fallback to school location or Muscat if everything fails (to avoid Null Island)
    return _schoolLocation ?? const LatLng(23.6080, 58.4500);
  }

  bool _isInvalid(dynamic value) {
    if (value == null) return true;
    final d = double.tryParse(value.toString());
    return d == null || d == 0.0;
  }
}
