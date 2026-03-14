import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/trip_status_model.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  int? _cachedBusId;

  Future<int?> _getBusId() async {
    if (_cachedBusId != null) return _cachedBusId;
    
    try {
      final prefs = GetIt.instance<SharedPreferences>();
      final busIdStr = prefs.getString('USER_BUS_ID');
      if (busIdStr != null) {
        _cachedBusId = int.tryParse(busIdStr);
        return _cachedBusId;
      }
    } catch (_) {}

    // Fallback to API check if preferences fail
    try {
      final response = await ApiClient.instance.get('auth/user');
      final data = response.data['data'] ?? response.data['user'] ?? response.data;
      final busId = data['bus_id'] ?? data['has_bus'] ?? data['id'];
      if (busId != null) {
        _cachedBusId = int.tryParse(busId.toString());
        return _cachedBusId;
      }
    } catch (_) {}
    
    return null;
  }

  @override
  Future<TripStatus> getCurrentTripStatus() async {
    try {
      final busId = await _getBusId();
      if (busId == null) throw Exception('No bus assigned');

      final response = await ApiClient.instance.get('bus/$busId/passengers');
      if (response.statusCode == 200) {
        final data = response.data;
        final busData = data['bus'];
        
        // Map based on trip_status from backend
        final tripStatus = busData['trip_status'] ?? 'idle';
        
        return TripStatusModel(
          id: 'trip-$busId',
          departureTime: busData['departure_time'] ?? '06:30 AM',
          totalStudents: data['total_count'] ?? 0,
          isStarted: tripStatus != 'idle',
        );
      }
      throw Exception('Failed to load trip status');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('Failed to load status: $message');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> startTrip(String tripId) async {
    debugPrint('HomeRepositoryImpl: startTrip called with tripId: $tripId');
    try {
      final busId = await _getBusId();
      debugPrint('HomeRepositoryImpl: starting trip for busId: $busId');
      if (busId == null) throw Exception('No bus assigned');

      final response = await ApiClient.instance.post('bus/$busId/start-trip');
      debugPrint('HomeRepositoryImpl: start-trip response code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to start trip');
      }
      debugPrint('HomeRepositoryImpl: Trip started successfully for busId: $busId');
    } on DioException catch (e) {
      debugPrint('HomeRepositoryImpl: DioException in startTrip: ${e.message}');
      debugPrint('HomeRepositoryImpl: Response data: ${e.response?.data}');
      final message = e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('Failed to start trip: $message');
    } catch (e) {
      debugPrint('HomeRepositoryImpl: Unexpected error in startTrip: $e');
      throw Exception('Failed to start trip: ${e.toString()}');
    }
  }
}
