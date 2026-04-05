import '../../domain/entities/student_entity.dart';

class StudentModel extends StudentEntity {
  const StudentModel({
    required super.id,
    required super.name,
    required super.parentName,
    required super.parentPhone,
    super.photoUrl,
    super.status = AttendanceStatus.unknown,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'غير معروف',
      parentName: json['parentName'] as String? ?? '',
      parentPhone: json['parentPhone'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.unknown,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'photoUrl': photoUrl,
      'status': status.name,
    };
  }
}
