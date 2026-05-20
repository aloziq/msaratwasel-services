import '../../domain/entities/bus_student_entity.dart';

class BusStudentModel extends BusStudentEntity {
  const BusStudentModel({
    required super.id,
    required super.studentCode,
    required super.name,
    super.nameEn,
    required super.grade,
    required super.schoolId,
    required super.parentName,
    required super.parentPhone,
    super.parentUserId,
    super.photoUrl,
    super.status = BusStudentStatus.unknown,
    super.behavioralNote,
    super.waitingSince,
    super.waitingElapsedSeconds = 0,
  });

  factory BusStudentModel.fromJson(Map<String, dynamic> json) {
    return BusStudentModel(
      id: json['id']?.toString() ?? '',
      studentCode: json['studentCode']?.toString() ?? json['student_code']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name_ar'] as String? ?? json['name']?.toString() ?? '',
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String?,
      grade: json['grade']?.toString() ?? 'غير محدد',
      schoolId: json['classroom']?['school_id']?.toString() ?? json['schoolId']?.toString() ?? '',
      parentName: json['parentName']?.toString() ?? 'غير محدد',
      parentPhone: json['parentPhone']?.toString() ?? 'غير محدد',
      parentUserId: json['parentUserId']?.toString(),
      photoUrl: json['photoUrl'] as String?,
      status: BusStudentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BusStudentStatus.unknown,
      ),
      behavioralNote: json['behavioralNote'] as String?,
      waitingSince: json['waitingSince'] != null 
          ? DateTime.tryParse(json['waitingSince'].toString()) 
          : null,
      waitingElapsedSeconds: int.tryParse(json['waitingElapsedSeconds']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_code': studentCode,
      'name': name,
      'nameEn': nameEn,
      'grade': grade,
      'schoolId': schoolId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'parentUserId': parentUserId,
      'photoUrl': photoUrl,
      'status': status.name,
      'behavioralNote': behavioralNote,
      'waitingSince': waitingSince?.toIso8601String(),
      'waitingElapsedSeconds': waitingElapsedSeconds,
    };
  }
}
