import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import '../../domain/entities/student_entity.dart';
import '../models/student_model.dart';

abstract class StudentsRemoteDataSource {
  Future<List<StudentModel>> getStudentsByClass(String classId);
  Future<void> markAttendance(String studentId, AttendanceStatus status);
}

@LazySingleton(as: StudentsRemoteDataSource)
class StudentsRemoteDataSourceImpl implements StudentsRemoteDataSource {
  @override
  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('teacher/classes/$classId/students');

      debugPrint('[StudentsRemoteDS] ✅ Students fetched for class $classId: ${response.data}');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => StudentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[StudentsRemoteDS] ❌ Error fetching students for class $classId: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAttendance(String studentId, AttendanceStatus status) async {
    try {
      final dio = ApiClient.instance;
      await dio.put(
        'teacher/students/$studentId/attendance',
        data: {'status': status.name},
      );
      debugPrint('[StudentsRemoteDS] ✅ Marked attendance for student $studentId: ${status.name}');
    } catch (e) {
      debugPrint('[StudentsRemoteDS] ❌ Error marking attendance: $e');
      rethrow;
    }
  }
}
