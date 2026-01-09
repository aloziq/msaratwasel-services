import 'package:dartz/dartz.dart';
import '../entities/report_entity.dart';

abstract class ReportsRepository {
  Future<Either<String, AttendanceStatsEntity>> getAttendanceStats();
}
