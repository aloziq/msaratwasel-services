import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
// import 'package:msaratwasel_services/core/error/failure.dart'; // Removed unused import
import '../../domain/entities/classroom_entity.dart';
import '../../domain/repositories/teacher_repository.dart';

@lazySingleton
class GetTeacherClassroomUseCase {
  final TeacherRepository repository;

  GetTeacherClassroomUseCase(this.repository);

  Future<Either<String, ClassroomEntity>> call() {
    return repository.getTeacherClassroom();
  }
}
