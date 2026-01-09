import 'package:dartz/dartz.dart';
import '../entities/classroom_entity.dart';
import '../repositories/teacher_repository.dart';

class GetTeacherClassroomsUseCase {
  final TeacherRepository repository;

  GetTeacherClassroomsUseCase(this.repository);

  Future<Either<String, List<ClassroomEntity>>> call() {
    return repository.getTeacherClassrooms();
  }
}
