import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/bus_position.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import '../../../../../core/services/reverb_service.dart';
import '../../../../../core/network/api_client.dart';
import '../../../core/data/repositories/assistant_repository_impl.dart';

abstract class BusTrackingState extends Equatable {
  const BusTrackingState();
  @override
  List<Object?> get props => [];
}

class BusTrackingInitial extends BusTrackingState {}

class BusTrackingLoading extends BusTrackingState {}

class BusTrackingLoaded extends BusTrackingState {
  final BusPosition? position;
  final List<StudentEntity> students;
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
      List<StudentEntity> students = [];
      String busId = '';
      
      tripResult.fold(
        (l) => emit(BusTrackingError(l)),
        (trip) {
          busId = GetIt.instance<SharedPreferences>().getString('USER_BUS_ID') ?? '';
          students = trip.students.map((e) => StudentEntity(
            id: e.id,
            name: e.name,
            parentName: e.parentName,
            parentPhone: e.parentPhone,
            status: _mapStatus(e.status.name),
          )).toList();
        }
      );

      if (busId.isEmpty) {
        if (state is BusTrackingLoading) {
          emit(const BusTrackingError('لم يتم العثور على حافلة'));
        }
        return;
      }

      // Emit loaded state with null position initially.
      // The tracking location remains null/empty until the first real backend/WebSocket update arrives.
      emit(BusTrackingLoaded(null, students));

      BusPosition? currentPosition;

      // Connect to Reverb
      _reverbService = ReverbService(
        dio: ApiClient.instance,
        onBusLocationUpdated: (data) {
          if (isClosed) return;
          final lat = double.tryParse(data['latitude']?.toString() ?? '') ?? currentPosition?.lat ?? 0.0;
          final lng = double.tryParse(data['longitude']?.toString() ?? '') ?? currentPosition?.lng ?? 0.0;
          final speedKmh = double.tryParse(data['speed_kmh']?.toString() ?? '') ?? currentPosition?.speedKmh ?? 0.0;
          final studentsOnBoard = int.tryParse(data['students_on_board']?.toString() ?? '') ?? currentPosition?.studentsOnBoard ?? 0;
          
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

  AttendanceStatus _mapStatus(String statusStr) {
    if (statusStr.contains('on_bus') || statusStr.contains('present')) {
      return AttendanceStatus.present;
    } else if (statusStr.contains('absent')) {
      return AttendanceStatus.absent;
    }
    return AttendanceStatus.present;
  }

  @override
  Future<void> close() {
    _reverbService?.dispose();
    return super.close();
  }
}
