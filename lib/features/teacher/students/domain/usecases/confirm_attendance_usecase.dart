import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../repositories/students_repository.dart';

@lazySingleton
class ConfirmAttendanceUseCase {
  final StudentsRepository repository;

  ConfirmAttendanceUseCase(this.repository);

  Future<Either<String, void>> call(String classId) {
    return repository.confirmAttendance(classId);
  }
}
