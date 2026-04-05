import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import '../models/attendance_history_model.dart';

abstract class AttendanceHistoryRemoteDataSource {
  Future<List<AttendanceHistoryModel>> getTeacherAttendanceHistory();
}

@LazySingleton(as: AttendanceHistoryRemoteDataSource)
class AttendanceHistoryRemoteDataSourceImpl
    implements AttendanceHistoryRemoteDataSource {
  @override
  Future<List<AttendanceHistoryModel>> getTeacherAttendanceHistory() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('teacher/attendance-history');

      debugPrint(
        '[AttendanceHistoryRemoteDS] ✅ History fetched: ${response.data}',
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) => AttendanceHistoryModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('[AttendanceHistoryRemoteDS] ❌ Error fetching history: $e');
      rethrow;
    }
  }
}
