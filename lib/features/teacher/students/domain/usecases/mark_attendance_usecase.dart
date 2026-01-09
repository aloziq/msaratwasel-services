import 'package:dartz/dartz.dart';
import '../entities/student_entity.dart';
import '../repositories/students_repository.dart';

class MarkAttendanceUseCase {
  final StudentsRepository repository;

  MarkAttendanceUseCase(this.repository);

  Future<Either<String, void>> call(String studentId, AttendanceStatus status) {
    return repository.markAttendance(studentId, status);
  }
}
