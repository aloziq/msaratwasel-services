import 'package:dartz/dartz.dart';
import '../entities/report_entity.dart';
import '../repositories/reports_repository.dart';

class GetAttendanceStatsUseCase {
  final ReportsRepository repository;

  GetAttendanceStatsUseCase(this.repository);

  Future<Either<String, AttendanceStatsEntity>> call() {
    return repository.getAttendanceStats();
  }
}
