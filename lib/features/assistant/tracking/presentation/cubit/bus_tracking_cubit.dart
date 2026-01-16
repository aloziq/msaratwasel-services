import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/bus_position.dart';

abstract class BusTrackingState extends Equatable {
  const BusTrackingState();
  @override
  List<Object?> get props => [];
}

class BusTrackingInitial extends BusTrackingState {}

class BusTrackingLoading extends BusTrackingState {}

class BusTrackingLoaded extends BusTrackingState {
  final BusPosition position;
  const BusTrackingLoaded(this.position);
  @override
  List<Object?> get props => [position];
}

class BusTrackingError extends BusTrackingState {
  final String message;
  const BusTrackingError(this.message);
  @override
  List<Object?> get props => [message];
}

class BusTrackingCubit extends Cubit<BusTrackingState> {
  BusTrackingCubit() : super(BusTrackingInitial());

  void startTracking() {
    emit(BusTrackingLoading());
    // In a real app, this would subscribe to a stream from Firebase/Socket.
    // For now, we'll emit a mock position.
    emit(
      BusTrackingLoaded(
        BusPosition(
          busId: 'B-45',
          lat: 24.7136, // Riyadh
          lng: 46.6753,
          speedKmh: 45.0,
          distanceKm: 12.5,
          etaMinutes: 15,
          state: BusState.enRoute,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }
}
