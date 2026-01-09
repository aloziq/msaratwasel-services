import 'package:dartz/dartz.dart';
import '../entities/student_entity.dart';

abstract class StudentsRepository {
  Future<Either<String, List<StudentEntity>>> getStudentsByClass(
    String classId,
  );
  Future<Either<String, void>> markAttendance(
    String studentId,
    AttendanceStatus status,
  );
}
