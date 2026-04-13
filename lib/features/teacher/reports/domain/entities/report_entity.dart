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
  final String? civilId;
  final int presentCount;
  final int absentCount;
  final String? photoUrl;

  const StudentReportEntity({
    required this.name,
    this.civilId,
    required this.presentCount,
    required this.absentCount,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [name, civilId, presentCount, absentCount, photoUrl];
}

class AttendanceStatsEntity extends Equatable {
  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final int unmarkedToday;
  final double averageAttendance;
  final List<ReportEntity> weeklyTrend;
  final List<StudentReportEntity> studentReports;

  const AttendanceStatsEntity({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.unmarkedToday,
    required this.averageAttendance,
    required this.weeklyTrend,
    required this.studentReports,
  });

  @override
  List<Object?> get props => [
    totalStudents,
    presentToday,
    absentToday,
    unmarkedToday,
    averageAttendance,
    weeklyTrend,
    studentReports,
  ];
}
