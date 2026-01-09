import 'package:equatable/equatable.dart';

class ReportEntity extends Equatable {
  final DateTime date;
  final double attendancePercentage;

  const ReportEntity({required this.date, required this.attendancePercentage});

  @override
  List<Object?> get props => [date, attendancePercentage];
}

class AttendanceStatsEntity extends Equatable {
  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final double averageAttendance;
  final List<ReportEntity> weeklyTrend;

  const AttendanceStatsEntity({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.averageAttendance,
    required this.weeklyTrend,
  });

  @override
  List<Object?> get props => [
    totalStudents,
    presentToday,
    absentToday,
    averageAttendance,
    weeklyTrend,
  ];
}
