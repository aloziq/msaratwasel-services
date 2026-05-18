import '../../domain/entities/attendance_history_entity.dart';
import '../../../students/data/models/student_model.dart';

class AttendanceHistoryRecordModel extends AttendanceHistoryRecord {
  const AttendanceHistoryRecordModel({
    required super.date,
    required super.attendedStudents,
    required super.totalStudents,
    required super.presentCount,
    required super.absentCount,
    // required super.lateCount,
  });

  factory AttendanceHistoryRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryRecordModel(
      date: DateTime.parse(json['date'] as String),
      attendedStudents:
          (json['attendedStudents'] as List<dynamic>?)
              ?.map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalStudents: json['totalStudents'] as int? ?? 0,
      presentCount: json['presentCount'] as int? ?? 0,
      absentCount: json['absentCount'] as int? ?? 0,
      // lateCount: json['lateCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'attendedStudents': attendedStudents.map((e) {
        if (e is StudentModel) return e.toJson();
        return StudentModel(
          id: e.id,
          name: e.name,
          nameEn: e.nameEn,
          parentName: e.parentName,
          parentNameEn: e.parentNameEn,
          parentPhone: e.parentPhone,
          photoUrl: e.photoUrl,
          status: e.status,
        ).toJson();
      }).toList(),
      'totalStudents': totalStudents,
      'presentCount': presentCount,
      'absentCount': absentCount,
      // 'lateCount': lateCount,
    };
  }
}

class AttendanceHistoryModel extends AttendanceHistoryEntity {
  const AttendanceHistoryModel({
    required super.classId,
    required super.className,
    super.classNameEn,
    required super.dailyRecords,
  });

  factory AttendanceHistoryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryModel(
      classId: (json['classId'] ?? json['id'])?.toString() ?? '',
      className: json['className'] as String? ?? json['class_name'] as String? ?? json['name'] as String? ?? '',
      classNameEn: json['classNameEn'] as String? ?? json['class_name_en'] as String? ?? json['name_en'] as String?,
      dailyRecords:
          (json['dailyRecords'] as List<dynamic>?)
              ?.map(
                (e) => AttendanceHistoryRecordModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'classNameEn': classNameEn,
      'dailyRecords': dailyRecords.map((e) {
        if (e is AttendanceHistoryRecordModel) return e.toJson();
        return AttendanceHistoryRecordModel(
          date: e.date,
          attendedStudents: e.attendedStudents,
          totalStudents: e.totalStudents,
          presentCount: e.presentCount,
          absentCount: e.absentCount,
          // lateCount: e.lateCount,
        ).toJson();
      }).toList(),
    };
  }
}
