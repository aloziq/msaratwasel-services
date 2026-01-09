import 'package:dartz/dartz.dart';
import '../entities/student_entity.dart';
import '../repositories/students_repository.dart';

class GetStudentsUseCase {
  final StudentsRepository repository;

  GetStudentsUseCase(this.repository);

  Future<Either<String, List<StudentEntity>>> call(String classId) {
    return repository.getStudentsByClass(classId);
  }
}
