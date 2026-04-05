import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import '../models/report_model.dart';

abstract class ReportsRemoteDataSource {
  Future<AttendanceStatsModel> getAttendanceStats();
}

@LazySingleton(as: ReportsRemoteDataSource)
class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  @override
  Future<AttendanceStatsModel> getAttendanceStats() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('teacher/reports/stats');

      debugPrint(
        '[ReportsRemoteDS] ✅ Stats fetched: ${response.data}',
      );

      final data = response.data as Map<String, dynamic>;
      return AttendanceStatsModel.fromJson(data);
    } catch (e) {
      debugPrint('[ReportsRemoteDS] ❌ Error fetching report stats: $e. Falling back to local calculation...');
      
      try {
        final dio = ApiClient.instance;
        // 1. Fetch classrooms
        final classesRes = await dio.get('teacher/classes');
        final classesData = classesRes.data as List<dynamic>;
        
        int totalStudents = 0;
        int presentToday = 0;
        int absentToday = 0;

        final List<StudentReportModel> studentReports = [];

        for (var clsJson in classesData) {
          final classId = clsJson['id'].toString();
          
          try {
            // Fetch students for each class
            final stdRes = await dio.get('teacher/classes/$classId/students');
            final stdData = stdRes.data as List<dynamic>;
            
            totalStudents += stdData.length;
            
            for (var studentJson in stdData) {
              final name = studentJson['name']?.toString() ?? 'غير معروف';
              final civilId = studentJson['civil_id']?.toString() ?? studentJson['civilId']?.toString();
              final status = studentJson['status']?.toString().toLowerCase();
              
              int pCount = 0;
              int aCount = 0;
              if (status == 'present' || status == 'حاضر') {
                presentToday++;
                pCount = 1;
              }
              if (status == 'absent' || status == 'غائب') {
                absentToday++;
                aCount = 1;
              }

              studentReports.add(StudentReportModel(
                name: name,
                civilId: civilId,
                presentCount: pCount,
                absentCount: aCount,
              ));
            }
          } catch(err) {
            debugPrint('[ReportsRemoteDS] Warning: Could not fetch students for class $classId: $err');
          }
        }
        
        double avg = totalStudents > 0 ? (presentToday / totalStudents) * 100 : 0.0;
        
        return AttendanceStatsModel(
          totalStudents: totalStudents,
          presentToday: presentToday,
          absentToday: absentToday,
          unmarkedToday: totalStudents - presentToday - absentToday,
          averageAttendance: avg,
          weeklyTrend: [],
          studentReports: studentReports,
        );
      } catch (fallbackError) {
        debugPrint('[ReportsRemoteDS] ❌ Local fallback calculation also failed: $fallbackError');
        rethrow;
      }
    }
  }
}
