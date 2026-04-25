import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/features/driver/trip/data/models/trip_history_model.dart';
import 'package:msaratwasel_services/features/driver/trip/domain/repositories/trip_history_repository.dart';

part 'trip_history_state.dart';

class TripHistoryCubit extends Cubit<TripHistoryState> {
  final TripHistoryRepository _repository;

  TripHistoryCubit(this._repository) : super(TripHistoryInitial());

  Future<void> loadTrips({
    String? startDate,
    String? endDate,
    String? status,
    int page = 1,
  }) async {
    emit(TripHistoryLoading());

    final result = await _repository.getTripsHistory(
      startDate: startDate,
      endDate: endDate,
      status: status,
      page: page,
    );

    result.fold(
      (Failure failure) =>
          emit(TripHistoryError(failure.message ?? 'Unknown error')),
      (TripHistoryResponse response) => emit(TripHistoryLoaded(response)),
    );
  }

  Future<void> filterTrips({
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    await loadTrips(startDate: startDate, endDate: endDate, status: status);
  }
}
