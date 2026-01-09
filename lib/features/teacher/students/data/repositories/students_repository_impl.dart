import 'package:dartz/dartz.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/students_repository.dart';

class StudentsRepositoryImpl implements StudentsRepository {
  // Mock Data
  final List<StudentEntity> _students = [
    const StudentEntity(
      id: 's1',
      name: 'أحمد محمد',
      parentName: 'محمد علي',
      parentPhone: '99999999',
      status: AttendanceStatus.unknown,
    ),
    const StudentEntity(
      id: 's2',
      name: 'فاطمة علي',
      parentName: 'علي حسن',
      parentPhone: '98888888',
      status: AttendanceStatus.unknown,
    ),
    const StudentEntity(
      id: 's3',
      name: 'يوسف ابراهيم',
      parentName: 'ابراهيم خليل',
      parentPhone: '97777777',
      status: AttendanceStatus.unknown,
    ),
  ];

  @override
  Future<Either<String, List<StudentEntity>>> getStudentsByClass(
    String classId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return Right(_students);
  }

  @override
  Future<Either<String, void>> markAttendance(
    String studentId,
    AttendanceStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Right(null);
  }
}
