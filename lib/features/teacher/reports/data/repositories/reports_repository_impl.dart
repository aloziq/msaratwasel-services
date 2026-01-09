import 'package:dartz/dartz.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  @override
  Future<Either<String, AttendanceStatsEntity>> getAttendanceStats() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      final now = DateTime.now();
      final weeklyTrend = List.generate(7, (index) {
        return ReportEntity(
          date: now.subtract(Duration(days: 6 - index)),
          attendancePercentage:
              70.0 + (index * 4.0) + (index % 2 == 0 ? 5.0 : -5.0),
        );
      });

      return Right(
        AttendanceStatsEntity(
          totalStudents: 120,
          presentToday: 105,
          absentToday: 15,
          averageAttendance: 88.5,
          weeklyTrend: weeklyTrend,
        ),
      );
    } catch (e) {
      return Left(e.toString());
    }
  }
}
