import '../../domain/entities/report_entity.dart';

class ReportModel extends ReportEntity {
  const ReportModel({required super.date, required super.attendancePercentage});

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      date: DateTime.parse(json['date'] as String),
      attendancePercentage: (json['attendancePercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'attendancePercentage': attendancePercentage,
    };
  }
}

class StudentReportModel extends StudentReportEntity {
  const StudentReportModel({
    required super.name,
    required super.presentCount,
    required super.absentCount,
  });

  factory StudentReportModel.fromJson(Map<String, dynamic> json) {
    return StudentReportModel(
      name: json['name'] as String,
      presentCount: json['presentCount'] as int? ?? 0,
      absentCount: json['absentCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'presentCount': presentCount,
      'absentCount': absentCount,
    };
  }
}

class AttendanceStatsModel extends AttendanceStatsEntity {
  const AttendanceStatsModel({
    required super.totalStudents,
    required super.presentToday,
    required super.absentToday,
    required super.averageAttendance,
    required super.weeklyTrend,
    required super.studentReports,
  });

  factory AttendanceStatsModel.fromJson(Map<String, dynamic> json) {
    return AttendanceStatsModel(
      totalStudents: json['totalStudents'] as int? ?? 0,
      presentToday: json['presentToday'] as int? ?? 0,
      absentToday: json['absentToday'] as int? ?? 0,
      averageAttendance: (json['averageAttendance'] as num?)?.toDouble() ?? 0.0,
      weeklyTrend:
          (json['weeklyTrend'] as List<dynamic>?)
              ?.map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      studentReports:
          (json['studentReports'] as List<dynamic>?)
              ?.map(
                (e) => StudentReportModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStudents': totalStudents,
      'presentToday': presentToday,
      'absentToday': absentToday,
      'averageAttendance': averageAttendance,
      'weeklyTrend': weeklyTrend.map((e) {
        if (e is ReportModel) return e.toJson();
        return ReportModel(
          date: e.date,
          attendancePercentage: e.attendancePercentage,
        ).toJson();
      }).toList(),
      'studentReports': studentReports.map((e) {
        if (e is StudentReportModel) return e.toJson();
        return StudentReportModel(
          name: e.name,
          presentCount: e.presentCount,
          absentCount: e.absentCount,
        ).toJson();
      }).toList(),
    };
  }
}
