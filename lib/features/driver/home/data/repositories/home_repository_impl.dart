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
      if (busIdStr != null && busIdStr.isNotEmpty) {
        final parsed = int.tryParse(busIdStr);
        if (parsed != null && parsed > 0) {
          _cachedBusId = parsed;
          return _cachedBusId;
        }
      }
    } catch (_) {}

    // Fallback to API check if preferences fail
    try {
      final response = await ApiClient.instance.get('auth/user');
      final data =
          response.data['data'] ?? response.data['user'] ?? response.data;
      
      // CRITICAL FIX: Only use bus_id or has_bus. NEVER fallback to user 'id'.
      final busId = data['bus_id'] ?? data['has_bus'];
      
      if (busId != null) {
        _cachedBusId = int.tryParse(busId.toString());
        
        // Update local storage too
        if (_cachedBusId != null) {
          final prefs = GetIt.instance<SharedPreferences>();
          await prefs.setString('USER_BUS_ID', _cachedBusId.toString());
        }
        
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
        final hasActiveTrip = busData['has_active_trip'] == true;
        final tripId = busData['trip_id']?.toString() ?? 'trip-$busId';

        return TripStatusModel(
          id: tripId,
          departureTime: busData['departure_time'] ?? '06:30 AM',
          totalStudents: data['total_count'] ?? 0,
          isStarted: tripStatus != 'idle',
          isCompleted: !hasActiveTrip,
        );
      }
      throw Exception('Failed to load trip status');
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('Failed to load status: $message');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<TripStatus>> getMyTrips() async {
    try {
      final response = await ApiClient.instance.get('driver/my-trips');
      if (response.statusCode == 200) {
        final data = response.data;
        final trips = data['trips'] as List<dynamic>? ?? [];
        return trips
            .map((trip) => TripStatusModel.fromJson(trip as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load trips');
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('Failed to load trips: $message');
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
      debugPrint(
        'HomeRepositoryImpl: start-trip response code: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to start trip');
      }
      debugPrint(
        'HomeRepositoryImpl: Trip started successfully for busId: $busId',
      );
    } on DioException catch (e) {
      debugPrint('HomeRepositoryImpl: DioException in startTrip: ${e.message}');
      debugPrint('HomeRepositoryImpl: Response data: ${e.response?.data}');
      final message =
          e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('Failed to start trip: $message');
    } catch (e) {
      debugPrint('HomeRepositoryImpl: Unexpected error in startTrip: $e');
      throw Exception('Failed to start trip: ${e.toString()}');
    }
  }

  @override
  Future<void> confirmTrip(String tripId) async {
    debugPrint('HomeRepositoryImpl: confirmTrip called with tripId: $tripId');
    try {
      final busId = await _getBusId();
      if (busId == null) throw Exception('No bus assigned');

      final response = await ApiClient.instance.post(
        'bus/$busId/confirm-trip',
        data: {'trip_id': tripId},
      );
      
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to confirm trip');
      }
      debugPrint('HomeRepositoryImpl: Trip confirmed successfully');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception('Failed to confirm trip: $message');
    } catch (e) {
      throw Exception('Failed to confirm trip: ${e.toString()}');
    }
  }
}
