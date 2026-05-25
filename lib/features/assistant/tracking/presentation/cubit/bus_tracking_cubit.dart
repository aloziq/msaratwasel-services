import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/bus_position.dart';
import '../../../../../core/services/reverb_service.dart';
import '../../../../../core/network/api_client.dart';
import '../../../core/data/repositories/assistant_repository_impl.dart';
import '../../../core/domain/entities/bus_student_entity.dart';

abstract class BusTrackingState extends Equatable {
  const BusTrackingState();
  @override
  List<Object?> get props => [];
}

class BusTrackingInitial extends BusTrackingState {}

class BusTrackingLoading extends BusTrackingState {}

class BusTrackingLoaded extends BusTrackingState {
  final BusPosition? position;
  final List<BusStudentEntity> students;
  const BusTrackingLoaded(this.position, this.students);
  @override
  List<Object?> get props => [position, students];
}

class BusTrackingError extends BusTrackingState {
  final String message;
  const BusTrackingError(this.message);
  @override
  List<Object?> get props => [message];
}

class BusTrackingCubit extends Cubit<BusTrackingState> {
  ReverbService? _reverbService;
  final AssistantRepositoryImpl _repository = AssistantRepositoryImpl();

  BusTrackingCubit() : super(BusTrackingInitial());

  Future<void> startTracking() async {
    emit(BusTrackingLoading());

    try {
      final tripResult = await _repository.getActiveTrip();
      List<BusStudentEntity> students = [];
      String busId = '';
      
      tripResult.fold(
        (l) => emit(BusTrackingError(l)),
        (trip) {
          busId = GetIt.instance<SharedPreferences>().getString('USER_BUS_ID') ?? '';
          // Use BusStudentEntity directly — preserves GPS coordinates
          students = List<BusStudentEntity>.from(trip.students);
        }
      );

      if (busId.isEmpty) {
        if (state is BusTrackingLoading) {
          emit(const BusTrackingError('لم يتم العثور على حافلة'));
        }
        return;
      }

      // Fetch the current bus location from the API
      BusPosition? currentPosition;
      try {
        final locationResponse = await ApiClient.instance.get('/bus/$busId/location');
        final locData = locationResponse.data;
        
        // Handle different response structures
        final locationData = locData is Map && locData.containsKey('data') 
            ? locData['data'] 
            : locData;
        
        if (locationData != null && locationData is Map) {
          final lat = double.tryParse(locationData['latitude']?.toString() ?? '') ?? 0.0;
          final lng = double.tryParse(locationData['longitude']?.toString() ?? '') ?? 0.0;
          
          if (lat != 0.0 || lng != 0.0) {
            currentPosition = BusPosition(
              busId: busId,
              lat: lat,
              lng: lng,
              speedKmh: double.tryParse(locationData['speed_kmh']?.toString() ?? '') ?? 0.0,
              distanceKm: 0.0,
              etaMinutes: 0,
              studentsOnBoard: int.tryParse(locationData['students_on_board']?.toString() ?? '') ?? 0,
              state: BusState.enRoute,
              updatedAt: DateTime.now(),
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not fetch initial bus location: $e');
        // Non-fatal: we'll continue and wait for WebSocket updates
      }

      // Emit loaded state (position may be null if API didn't return a location)
      emit(BusTrackingLoaded(currentPosition, students));

      // Get user ID safely as it is stored as a String in SharedPreferences
      final prefs = GetIt.instance<SharedPreferences>();
      final userIdStr = prefs.getString('USER_ID') ?? '';
      final userId = int.tryParse(userIdStr) ?? 0;
      
      _reverbService = ReverbService(
        userId: userId,
        dio: ApiClient.instance,
        onMessageReceived: (data) {
          if (isClosed) return;
          // Extract the actual payload from the wrapper 'data' field if it exists
          final eventData = data.containsKey('data') && data['data'] is Map
              ? data['data'] as Map
              : data;

          final lat = double.tryParse(eventData['latitude']?.toString() ?? '') ?? currentPosition?.lat ?? 0.0;
          final lng = double.tryParse(eventData['longitude']?.toString() ?? '') ?? currentPosition?.lng ?? 0.0;
          final speedKmh = double.tryParse(eventData['speed_kmh']?.toString() ?? '') ?? currentPosition?.speedKmh ?? 0.0;
          final studentsOnBoard = int.tryParse(eventData['students_on_board']?.toString() ?? '') ?? currentPosition?.studentsOnBoard ?? 0;
          
          currentPosition = BusPosition(
            busId: busId,
            lat: lat,
            lng: lng,
            speedKmh: speedKmh,
            distanceKm: currentPosition?.distanceKm ?? 0.0,
            etaMinutes: currentPosition?.etaMinutes ?? 0,
            studentsOnBoard: studentsOnBoard,
            state: BusState.enRoute,
            updatedAt: DateTime.now(),
          );
          
          if (state is BusTrackingLoaded) {
            emit(BusTrackingLoaded(currentPosition, (state as BusTrackingLoaded).students));
          }
        },
      );

      _reverbService!.connect();
      _reverbService!.subscribe('private-bus.$busId');

    } catch (e) {
      emit(BusTrackingError('حدث خطأ: $e'));
    }
  }

  void updateStudents(List<BusStudentEntity> newStudents) {
    if (state is BusTrackingLoaded) {
      final currentState = state as BusTrackingLoaded;
      emit(BusTrackingLoaded(currentState.position, newStudents));
    }
  }

  @override
  Future<void> close() {
    _reverbService?.dispose();
    return super.close();
  }
}
