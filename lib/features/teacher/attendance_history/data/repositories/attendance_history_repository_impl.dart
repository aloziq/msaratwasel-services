import 'package:dartz/dartz.dart';
import '../../domain/entities/attendance_history_entity.dart';
import '../../domain/repositories/attendance_history_repository.dart';
import '../../../students/domain/entities/student_entity.dart';

class AttendanceHistoryRepositoryImpl implements AttendanceHistoryRepository {
  @override
  Future<Either<String, List<AttendanceHistoryEntity>>>
  getTeacherAttendanceHistory() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final mockHistory = [
        AttendanceHistoryEntity(
          classId: '1',
          className: 'الصف الأول - أ',
          dailyRecords: _generateMockRecords(),
        ),
        AttendanceHistoryEntity(
          classId: '2',
          className: 'الصف الثاني - ب',
          dailyRecords: _generateMockRecords(),
        ),
      ];
      return Right(mockHistory);
    } catch (e) {
      return Left(e.toString());
    }
  }

  List<AttendanceHistoryRecord> _generateMockRecords() {
    final now = DateTime.now();
    return List.generate(10, (index) {
      final date = now.subtract(Duration(days: index));
      return AttendanceHistoryRecord(
        date: date,
        attendedStudents: _generateMockStudents(),
        totalStudents: 25,
        presentCount: 20,
        absentCount: 3,
        lateCount: 2,
      );
    });
  }

  List<StudentEntity> _generateMockStudents() {
    return [
      const StudentEntity(
        id: '1',
        name: 'أحمد محمد',
        parentName: 'محمد علي',
        parentPhone: '0501234567',
        status: AttendanceStatus.present,
      ),
      const StudentEntity(
        id: '2',
        name: 'سارة أحمد',
        parentName: 'أحمد محمود',
        parentPhone: '0507654321',
        status: AttendanceStatus.present,
      ),
    ];
  }
}
