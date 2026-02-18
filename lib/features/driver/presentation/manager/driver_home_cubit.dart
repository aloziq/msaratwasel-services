import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/driver_entities.dart';
import '../../domain/repositories/driver_repository.dart';

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
  final DriverRepository _repository;

  DriverHomeCubit(this._repository) : super(DriverHomeInitial());

  Future<void> loadDashboard() async {
    emit(DriverHomeLoading());
    try {
      final status = await _repository.getCurrentTripStatus();
      emit(DriverHomeLoaded(status));
    } catch (e) {
      emit(DriverHomeError(e.toString()));
    }
  }

  Future<void> startTrip(String tripId) async {
    if (state is DriverHomeLoaded) {
      // Optimistic update or reload
      try {
        await _repository.startTrip(tripId);
        loadDashboard(); // Refresh
      } catch (e) {
        emit(DriverHomeError(e.toString()));
      }
    }
  }
}
