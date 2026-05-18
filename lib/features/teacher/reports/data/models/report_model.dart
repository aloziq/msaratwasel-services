import '../../domain/entities/report_entity.dart';

class ReportModel extends ReportEntity {
  const ReportModel({required super.date, required super.attendancePercentage});

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      date: json['date'] != null 
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
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
    super.nameEn,
    super.civilId,
    required super.presentCount,
    required super.absentCount,
    super.photoUrl,
  });

  factory StudentReportModel.fromJson(Map<String, dynamic> json) {
    return StudentReportModel(
      name: json['name_ar'] as String? ?? json['name'] as String? ?? 'غير معروف',
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String?,
      civilId: json['civil_id']?.toString() ?? json['civilId']?.toString(),
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      photoUrl: json['photoUrl']?.toString() ?? json['photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameEn': nameEn,
      'civil_id': civilId,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'photo_url': photoUrl,
    };
  }
}

class AttendanceStatsModel extends AttendanceStatsEntity {
  const AttendanceStatsModel({
    required super.totalStudents,
    required super.presentToday,
    required super.absentToday,
    required super.unmarkedToday,
    required super.averageAttendance,
    required super.weeklyTrend,
    required super.studentReports,
  });

  factory AttendanceStatsModel.fromJson(Map<String, dynamic> json) {
    final total = json['totalStudents'] as int? ?? 0;
    final present = json['presentToday'] as int? ?? 0;
    final absent = json['absentToday'] as int? ?? 0;
    // Calculate unmarked if not provided explicitly by backend
    final unmarked = json['unmarkedToday'] as int? ?? (total - present - absent);

    return AttendanceStatsModel(
      totalStudents: total,
      presentToday: present,
      absentToday: absent,
      unmarkedToday: unmarked,
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
      'unmarkedToday': unmarkedToday,
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
          nameEn: e.nameEn,
          civilId: e.civilId,
          presentCount: e.presentCount,
          absentCount: e.absentCount,
        ).toJson();
      }).toList(),
    };
  }
}
