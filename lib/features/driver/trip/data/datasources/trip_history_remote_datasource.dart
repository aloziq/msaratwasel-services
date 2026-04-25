import 'package:dio/dio.dart';
import 'package:msaratwasel_services/features/driver/trip/data/models/trip_history_model.dart';

abstract class TripHistoryRemoteDataSource {
  Future<TripHistoryResponse> getTripsHistory({
    String? startDate,
    String? endDate,
    String? status,
    int? page,
  });
}

class TripHistoryRemoteDataSourceImpl implements TripHistoryRemoteDataSource {
  final Dio _dio;

  TripHistoryRemoteDataSourceImpl(this._dio);

  @override
  Future<TripHistoryResponse> getTripsHistory({
    String? startDate,
    String? endDate,
    String? status,
    int? page,
  }) async {
    try {
      final response = await _dio.get(
        'driver/trips-history',
        queryParameters: {
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (status != null) 'status': status,
          if (page != null) 'page': page,
        },
      );

      return TripHistoryResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
