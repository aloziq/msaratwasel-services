import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
// import 'package:msaratwasel_services/core/error/failure.dart'; // Removed unused import
import '../../domain/repositories/students_repository.dart';
import '../entities/student_entity.dart';

@lazySingleton
class MarkAttendanceUseCase {
  final StudentsRepository repository;

  MarkAttendanceUseCase(this.repository);

  Future<Either<String, void>> call(String studentId, AttendanceStatus status) {
    return repository.markAttendance(studentId, status);
  }
}
