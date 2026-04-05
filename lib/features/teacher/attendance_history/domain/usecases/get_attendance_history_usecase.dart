import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/attendance_history_entity.dart';
import '../repositories/attendance_history_repository.dart';

@lazySingleton
class GetAttendanceHistoryUseCase {
  final AttendanceHistoryRepository repository;

  GetAttendanceHistoryUseCase(this.repository);

  Future<Either<String, List<AttendanceHistoryEntity>>> call() {
    return repository.getTeacherAttendanceHistory();
  }
}
