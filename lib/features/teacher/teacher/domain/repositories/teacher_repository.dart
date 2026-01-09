import 'package:dartz/dartz.dart';
import '../entities/classroom_entity.dart';

abstract class TeacherRepository {
  Future<Either<String, ClassroomEntity>> getTeacherClassroom();
  Future<Either<String, List<ClassroomEntity>>> getTeacherClassrooms();
  Future<Either<String, void>> submitDailyReport(String classId);
}
