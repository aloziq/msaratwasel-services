import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../datasources/attendance_history_remote_datasource.dart';
import '../../domain/entities/attendance_history_entity.dart';
import '../../domain/repositories/attendance_history_repository.dart';

@LazySingleton(as: AttendanceHistoryRepository)
class AttendanceHistoryRepositoryImpl implements AttendanceHistoryRepository {
  final AttendanceHistoryRemoteDataSource remoteDataSource;

  AttendanceHistoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<AttendanceHistoryEntity>>>
  getTeacherAttendanceHistory() async {
    try {
      final history = await remoteDataSource.getTeacherAttendanceHistory();
      return Right(history);
    } catch (e, stackTrace) {
      debugPrint(
        'AttendanceHistoryRepository.getTeacherAttendanceHistory failed: $e',
      );
      debugPrint('Stack trace: $stackTrace');
      return const Left('فشل تحميل سجل الحضور');
    }
  }
}
