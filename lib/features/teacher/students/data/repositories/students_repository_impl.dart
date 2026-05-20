import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/students_repository.dart';
import '../datasources/students_remote_datasource.dart';

@LazySingleton(as: StudentsRepository)
class StudentsRepositoryImpl implements StudentsRepository {
  final StudentsRemoteDataSource remoteDataSource;

  StudentsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<StudentEntity>>> getStudentsByClass(
    String classId,
  ) async {
    try {
      final students = await remoteDataSource.getStudentsByClass(classId);
      return Right(students);
    } catch (e, stackTrace) {
      debugPrint('StudentsRepository.getStudentsByClass failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Left('فشل تحميل قائمة الطلاب');
    }
  }

  @override
  Future<Either<String, void>> markAttendance(
    String studentId,
    AttendanceStatus status, {
    bool viaQr = false,
  }) async {
    try {
      await remoteDataSource.markAttendance(studentId, status, viaQr: viaQr);
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('StudentsRepository.markAttendance failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Left('فشل تسجيل الحضور');
    }
  }

  @override
  Future<Either<String, void>> confirmAttendance(
    String classId,
  ) async {
    try {
      await remoteDataSource.confirmAttendance(classId);
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('StudentsRepository.confirmAttendance failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Left('فشل تأكيد وإرسال التقرير');
    }
  }
}
