import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
// import 'package:msaratwasel_services/core/error/failure.dart'; // Removed unused import
import '../../domain/entities/classroom_entity.dart';
import '../../domain/repositories/teacher_repository.dart';

@lazySingleton
class GetTeacherClassroomsUseCase {
  final TeacherRepository repository;

  GetTeacherClassroomsUseCase(this.repository);

  Future<Either<String, List<ClassroomEntity>>> call() {
    return repository.getTeacherClassrooms();
  }
}
