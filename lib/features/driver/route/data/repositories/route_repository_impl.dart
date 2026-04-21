import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../shared/auth/domain/entities/user_entity.dart';
import '../models/student_stop_model.dart';
import '../../domain/entities/student_stop.dart';
import '../../domain/repositories/route_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../mappers/student_mapper.dart';

@LazySingleton(as: RouteRepository)
class RouteRepositoryImpl implements RouteRepository {
  final Dio _dio;

  RouteRepositoryImpl() : _dio = ApiClient.instance;

  // We need to keep a mock route for the map lines, but fetch stops from API
  @override
  Future<List<LatLng>> getRoutePoints() async {
    return [
      const LatLng(23.6264, 58.2618),
      const LatLng(23.6245, 58.2625),
      const LatLng(23.6190, 58.2690),
      const LatLng(23.6000, 58.3500),
      const LatLng(23.5900, 58.4000),
      const LatLng(23.6000, 58.4300),
      const LatLng(23.6080, 58.4500),
    ];
  }

  @override
  Future<List<StudentStop>> getTripStops() async {
    try {
      // 1. Get current user to find bus_id
      final userResponse = await _dio.get('auth/user');
      final data = userResponse.data['data'] ?? userResponse.data['user'];
      final busId = data['has_bus'] ?? data['bus_id'];

      if (busId == null) {
        throw Exception('لا يوجد باص مخصص لهذا الحساب');
      }

      // 2. Fetch passengers
      final response = await _dio.get('bus/$busId/passengers');

      final List<dynamic> passengersJson = response.data['passengers'] ?? [];

      return passengersJson.map((json) {
        final isOnBus = json['isOnBus'] == true;
        final lastEvent = json['lastEvent'];
        final isDroppedOff =
            lastEvent != null && lastEvent['type'] == 'alighting';

        return StudentStopModel(
          id: json['id'].toString(),
          nameAr: json['name'] ?? '',
          nameEn: json['name'] ?? '',
          parentAr: json['parentName'] ?? 'ولي الأمر',
          parentEn: json['parentName'] ?? 'Parent',
          parentUserId: json['parentUserId']?.toString(),
          location: _generateMockLocationForStudent(
            int.tryParse(json['id'].toString()) ?? 0,
          ),
          photoUrl:
              json['photoUrl'] ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(json['name'] ?? 'User')}&background=random',
          isBoarded: isOnBus,
          isDroppedOff: isDroppedOff,
          isAbsent: StudentMapper.mapIsAbsent(json),
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
  Future<void> boardStudent({
    required String studentId,
    required String direction,
  }) async {
    try {
      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        _cachedBusId = data['bus_id'] ?? data['has_bus'];
      }

      await _dio.post(
        'bus/$_cachedBusId/board',
        data: {'student_id': studentId, 'direction': direction},
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
  Future<void> alightStudent({
    required String studentId,
    required String direction,
  }) async {
    try {
      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        _cachedBusId = data['bus_id'] ?? data['has_bus'];
      }

      await _dio.post(
        'bus/$_cachedBusId/alight',
        data: {'student_id': studentId, 'direction': direction},
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('فشل تسجيل نزول الطالب: $message');
    } catch (e) {
      throw Exception('فشل تسجيل نزول الطالب');
    }
  }

  int? _cachedBusId;

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (_cachedBusId == null) {
        final userResponse = await _dio.get('auth/user');
        final data = userResponse.data['data'] ?? userResponse.data['user'];
        _cachedBusId = data['bus_id'] ?? data['has_bus'];
      }

      if (_cachedBusId != null) {
        await _dio.post(
          'bus/$_cachedBusId/location',
          data: {'latitude': latitude, 'longitude': longitude},
        );
      }
    } on DioException catch (e) {
      // Quietly log location update failures to avoid spamming the user
      debugPrint('Location update failed (Dio): ${e.message}');
    } catch (e) {
      debugPrint('Location update failed: ${e.toString()}');
    }
  }

  // Helper to give them map locations since the API doesn't return student geolocations
  LatLng _generateMockLocationForStudent(int studentId) {
    final mockLocations = [
      const LatLng(23.6000, 58.3500),
      const LatLng(23.5900, 58.4000),
      const LatLng(23.6000, 58.4300),
      const LatLng(23.6080, 58.4500),
    ];
    return mockLocations[studentId % mockLocations.length];
  }
}
