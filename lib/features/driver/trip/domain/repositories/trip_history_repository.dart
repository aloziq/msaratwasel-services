import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/features/driver/trip/data/models/trip_history_model.dart';
import 'package:msaratwasel_services/features/driver/trip/data/datasources/trip_history_remote_datasource.dart';
import 'package:dartz/dartz.dart';

abstract class TripHistoryRepository {
  Future<Either<Failure, TripHistoryResponse>> getTripsHistory({
    String? startDate,
    String? endDate,
    String? status,
    int? page,
  });
}

class TripHistoryRepositoryImpl implements TripHistoryRepository {
  final TripHistoryRemoteDataSource _remoteDataSource;

  TripHistoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, TripHistoryResponse>> getTripsHistory({
    String? startDate,
    String? endDate,
    String? status,
    int? page,
  }) async {
    try {
      final response = await _remoteDataSource.getTripsHistory(
        startDate: startDate,
        endDate: endDate,
        status: status,
        page: page,
      );
      return Right(response);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
