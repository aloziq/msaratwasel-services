import 'package:equatable/equatable.dart';

class ReportEntity extends Equatable {
  final DateTime date;
  final double attendancePercentage;

  const ReportEntity({required this.date, required this.attendancePercentage});

  @override
  List<Object?> get props => [date, attendancePercentage];
}

class StudentReportEntity extends Equatable {
  final String name;
  final int presentCount;
  final int absentCount;

  const StudentReportEntity({
    required this.name,
    required this.presentCount,
    required this.absentCount,
  });

  @override
  List<Object?> get props => [name, presentCount, absentCount];
}

class AttendanceStatsEntity extends Equatable {
  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final double averageAttendance;
  final List<ReportEntity> weeklyTrend;
  final List<StudentReportEntity> studentReports;

  const AttendanceStatsEntity({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.averageAttendance,
    required this.weeklyTrend,
    required this.studentReports,
  });

  @override
  List<Object?> get props => [
    totalStudents,
    presentToday,
    absentToday,
    averageAttendance,
    weeklyTrend,
    studentReports,
  ];
}
