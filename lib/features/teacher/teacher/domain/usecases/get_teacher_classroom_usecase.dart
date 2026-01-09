import 'package:dartz/dartz.dart';
import '../entities/classroom_entity.dart';
import '../repositories/teacher_repository.dart';

class GetTeacherClassroomUseCase {
  final TeacherRepository repository;

  GetTeacherClassroomUseCase(this.repository);

  Future<Either<String, ClassroomEntity>> call() {
    return repository.getTeacherClassroom();
  }
}
