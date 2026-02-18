import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
// import 'package:msaratwasel_services/core/error/failure.dart'; // Removed unused import
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/students_repository.dart';

@lazySingleton
class GetStudentsUseCase {
  final StudentsRepository repository;

  GetStudentsUseCase(this.repository);

  Future<Either<String, List<StudentEntity>>> call(String classId) {
    return repository.getStudentsByClass(classId);
  }
}
