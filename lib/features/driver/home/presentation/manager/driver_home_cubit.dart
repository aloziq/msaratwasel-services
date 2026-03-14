import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/repositories/home_repository.dart';

// States
abstract class DriverHomeState extends Equatable {
  const DriverHomeState();
  @override
  List<Object?> get props => [];
}

class DriverHomeInitial extends DriverHomeState {}

class DriverHomeLoading extends DriverHomeState {}

class DriverHomeLoaded extends DriverHomeState {
  final TripStatus tripStatus;
  const DriverHomeLoaded(this.tripStatus);
  @override
  List<Object?> get props => [tripStatus];
}

class DriverHomeError extends DriverHomeState {
  final String message;
  const DriverHomeError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
@injectable
class DriverHomeCubit extends Cubit<DriverHomeState> {
  final HomeRepository _repository;

  DriverHomeCubit(this._repository) : super(DriverHomeInitial());

  Future<void> loadDashboard() async {
    debugPrint('DriverHomeCubit: loadDashboard called');
    emit(DriverHomeLoading());
    try {
      final status = await _repository.getCurrentTripStatus();
      debugPrint('DriverHomeCubit: status loaded: isStarted=${status.isStarted}');
      emit(DriverHomeLoaded(status));
    } catch (e) {
      debugPrint('DriverHomeCubit: loadDashboard error: $e');
      emit(DriverHomeError(e.toString()));
    }
  }

  Future<void> startTrip(String tripId) async {
    debugPrint('DriverHomeCubit: startTrip called with tripId: $tripId');
    if (state is DriverHomeLoaded) {
      try {
        debugPrint('DriverHomeCubit: calling repository.startTrip');
        await _repository.startTrip(tripId);
        debugPrint('DriverHomeCubit: repository.startTrip success, reloading dashboard');
        await loadDashboard(); 
        debugPrint('DriverHomeCubit: after reload dashboard, state is: $state');
      } catch (e) {
        debugPrint('DriverHomeCubit: startTrip catch block error: $e');
        emit(DriverHomeError(e.toString()));
      }
    } else {
      debugPrint('DriverHomeCubit: startTrip ignored because state is ${state.runtimeType}');
    }
  }
}
