import '../../domain/entities/bus_student_entity.dart';

class BusStudentModel extends BusStudentEntity {
  const BusStudentModel({
    required super.id,
    required super.studentCode,
    required super.name,
    required super.grade,
    required super.schoolId,
    required super.parentName,
    required super.parentPhone,
    super.parentUserId,
    super.photoUrl,
    super.status = BusStudentStatus.unknown,
    super.behavioralNote,
  });

  factory BusStudentModel.fromJson(Map<String, dynamic> json) {
    return BusStudentModel(
      id: json['id'] as String,
      studentCode: json['student_code'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      grade: json['grade'] as String,
      schoolId: (json['schoolId'] ?? json['school_id'] ?? json['classroom']?['school_id'])?.toString() ?? '',
      parentName: json['parentName'] as String,
      parentPhone: json['parentPhone'] as String,
      parentUserId: json['parentUserId']?.toString(),
      photoUrl: json['photoUrl'] as String?,
      status: BusStudentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BusStudentStatus.unknown,
      ),
      behavioralNote: json['behavioralNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_code': studentCode,
      'name': name,
      'grade': grade,
      'schoolId': schoolId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'parentUserId': parentUserId,
      'photoUrl': photoUrl,
      'status': status.name,
      'behavioralNote': behavioralNote,
    };
  }
}
