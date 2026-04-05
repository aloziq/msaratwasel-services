import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/classroom_entity.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_datasource.dart';

@LazySingleton(as: TeacherRepository)
class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherRemoteDataSource remoteDataSource;

  TeacherRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, ClassroomEntity>> getTeacherClassroom() async {
    try {
      final results = await remoteDataSource.getTeacherClassrooms();
      if (results.isEmpty) {
        return const Left('لا توجد فصول مسجلة لهذا المعلم');
      }
      return Right(results.first);
    } catch (e, stackTrace) {
      debugPrint('TeacherRepository.getTeacherClassroom failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Left('فشل تحميل بيانات الفصل');
    }
  }

  @override
  Future<Either<String, List<ClassroomEntity>>> getTeacherClassrooms() async {
    try {
      final result = await remoteDataSource.getTeacherClassrooms();
      return Right(result);
    } catch (e, stackTrace) {
      debugPrint('TeacherRepository.getTeacherClassrooms failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Left('فشل تحميل قائمة الفصول');
    }
  }

  @override
  Future<Either<String, void>> submitDailyReport(String classId) async {
    // TODO: connect to real API when endpoint is ready
    await Future.delayed(const Duration(seconds: 1));
    return const Right(null);
  }
}
