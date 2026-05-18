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
  final String? nameEn;
  final String? civilId;
  final int presentCount;
  final int absentCount;
  final String? photoUrl;

  const StudentReportEntity({
    required this.name,
    this.nameEn,
    this.civilId,
    required this.presentCount,
    required this.absentCount,
    this.photoUrl,
  });

  String getLocalizedName(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : name;
    }
    return name;
  }

  @override
  List<Object?> get props => [name, nameEn, civilId, presentCount, absentCount, photoUrl];
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
