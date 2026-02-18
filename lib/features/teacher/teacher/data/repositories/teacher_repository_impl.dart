import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/classroom_entity.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_local_datasource.dart';

@LazySingleton(as: TeacherRepository)
class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherLocalDataSource dataSource;

  TeacherRepositoryImpl(this.dataSource);

  @override
  Future<Either<String, ClassroomEntity>> getTeacherClassroom() async {
    try {
      final result = await dataSource.getTeacherClassroom();
      return Right(result);
    } catch (e, stackTrace) {
      debugPrint('TeacherRepository.getTeacherClassroom failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Left('Failed to load classroom');
    }
  }

  @override
  Future<Either<String, List<ClassroomEntity>>> getTeacherClassrooms() async {
    try {
      final result = await dataSource.getTeacherClassrooms();
      return Right(result);
    } catch (e, stackTrace) {
      debugPrint('TeacherRepository.getTeacherClassrooms failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Left('Failed to load classrooms');
    }
  }

  @override
  Future<Either<String, void>> submitDailyReport(String classId) async {
    // Mock submission
    await Future.delayed(const Duration(seconds: 1));
    return const Right(null);
  }
}
