part of 'bus_trip_cubit.dart';

abstract class BusTripState extends Equatable {
  const BusTripState();

  @override
  List<Object?> get props => [];
}

class BusTripInitial extends BusTripState {}

class BusTripLoading extends BusTripState {}

class BusTripLoaded extends BusTripState {
  final BusTripEntity trip;

  const BusTripLoaded(this.trip);

  @override
  List<Object?> get props => [trip];
}

class BusTripError extends BusTripState {
  final String message;

  const BusTripError(this.message);

  @override
  List<Object?> get props => [message];
}
