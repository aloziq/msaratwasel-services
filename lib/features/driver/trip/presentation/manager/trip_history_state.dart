part of 'trip_history_cubit.dart';

abstract class TripHistoryState extends Equatable {
  const TripHistoryState();

  @override
  List<Object?> get props => [];
}

class TripHistoryInitial extends TripHistoryState {}

class TripHistoryLoading extends TripHistoryState {}

class TripHistoryLoaded extends TripHistoryState {
  final TripHistoryResponse response;

  const TripHistoryLoaded(this.response);

  @override
  List<Object?> get props => [response];
}

class TripHistoryError extends TripHistoryState {
  final String message;

  const TripHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
