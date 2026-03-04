import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../shared/auth/domain/entities/user_entity.dart';
import '../models/student_stop_model.dart';
import '../../domain/entities/student_stop.dart';
import '../../domain/repositories/route_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    // Note: We need the user's token and busId. 
    // In a real app, these would be injected or fetched from local storage.
    // For this implementation, we assume the token is appended by an interceptor.
    
    // To get the bus_id, ideally we pass it from the Auth bloc, but for now we'll
    // assume there's a way to get it, or we create a method that takes it.
    // Since the interface doesn't take busId, we'll fetch the user profile first 
    // to get the bus_id if we have to, or use a temporary hardcoded one if it fails,
    // but we will try to get it from the /auth/user endpoint.
    
    try {
      // 1. Get current user to find bus_id
      final userResponse = await _dio.get('/auth/user');
      final busId = userResponse.data['data']['has_bus'] ?? userResponse.data['data']['bus_id'] ?? userResponse.data['user']['bus_id'];
      
      if (busId == null) {
        throw Exception('لا يوجد باص مخصص لهذا الحساب');
      }

      // 2. Fetch passengers
      final response = await _dio.get('/bus/$busId/passengers');
      
      final List<dynamic> passengersJson = response.data['passengers'] ?? [];
      
      // Map passengers to StudentStop
      return passengersJson.map((json) {
        final isOnBus = json['is_on_bus'] == true;
        final lastEvent = json['last_event'];
        final isDroppedOff = lastEvent != null && lastEvent['type'] == 'alighting';
        
        return StudentStopModel(
          id: json['id'].toString(),
          nameAr: json['full_name'],
          nameEn: json['full_name'],
          parentAr: 'ولي الأمر', // Mocked if not provided by API
          parentEn: 'Parent',
          location: _generateMockLocationForStudent(json['id']), // API doesn't return lat/lng for student home yet
          photoUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(json['full_name'])}&background=random',
          isBoarded: isOnBus,
          isDroppedOff: isDroppedOff,
          isAbsent: false, // Default
        );
      }).toList();
    } catch (e) {
      throw Exception('فشل جلب قائمة الطلاب: ${e.toString()}');
    }
  }

  @override
  Future<void> boardStudent({required String studentId, required String direction}) async {
    try {
      final userResponse = await _dio.get('/auth/user');
      final busId = userResponse.data['data']['bus_id'] ?? userResponse.data['user']['bus_id'];
      
      await _dio.post('/bus/$busId/board', data: {
        'student_id': studentId,
        'direction': direction,
      });
    } catch (e) {
      throw Exception('فشل تسجيل রكوب الطالب');
    }
  }

  @override
  Future<void> alightStudent({required String studentId, required String direction}) async {
    try {
      final userResponse = await _dio.get('/auth/user');
      final busId = userResponse.data['data']['bus_id'] ?? userResponse.data['user']['bus_id'];
      
      await _dio.post('/bus/$busId/alight', data: {
        'student_id': studentId,
        'direction': direction,
      });
    } catch (e) {
      throw Exception('فشل تسجيل نزول الطالب');
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
