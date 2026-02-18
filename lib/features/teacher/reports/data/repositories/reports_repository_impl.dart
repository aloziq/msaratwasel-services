import 'package:flutter/foundation.dart';
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

      final studentReports = List.generate(30, (index) {
        final present = 40 + (index % 10);
        final absent = index % 5;
        return StudentReportEntity(
          name: 'Student ${index + 1}',
          presentCount: present,
          absentCount: absent,
        );
      });

      return Right(
        AttendanceStatsEntity(
          totalStudents: 120,
          presentToday: 105,
          absentToday: 15,
          averageAttendance: 88.5,
          weeklyTrend: weeklyTrend,
          studentReports: studentReports,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('ReportsRepository.getAttendanceStats failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return Left(e.toString());
    }
  }
}
