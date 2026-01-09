import 'package:dartz/dartz.dart';
import '../entities/attendance_history_entity.dart';

abstract class AttendanceHistoryRepository {
  Future<Either<String, List<AttendanceHistoryEntity>>>
  getTeacherAttendanceHistory();
}
