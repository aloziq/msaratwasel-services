import 'package:equatable/equatable.dart';
import '../../../students/domain/entities/student_entity.dart';

class AttendanceHistoryRecord extends Equatable {
  final DateTime date;
  final List<StudentEntity> attendedStudents;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;

  const AttendanceHistoryRecord({
    required this.date,
    required this.attendedStudents,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
  });

  double get attendanceRate =>
      totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0;

  @override
  List<Object?> get props => [
    date,
    attendedStudents,
    totalStudents,
    presentCount,
    absentCount,
    lateCount,
  ];
}

class AttendanceHistoryEntity extends Equatable {
  final String classId;
  final String className;
  final List<AttendanceHistoryRecord> dailyRecords;

  const AttendanceHistoryEntity({
    required this.classId,
    required this.className,
    required this.dailyRecords,
  });

  @override
  List<Object?> get props => [classId, className, dailyRecords];
}
