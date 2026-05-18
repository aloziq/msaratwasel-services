import '../../domain/entities/classroom_entity.dart';

class ClassroomModel extends ClassroomEntity {
  const ClassroomModel({
    required super.id,
    required super.name,
    super.nameEn,
    required super.grade,
    required super.studentCount,
  });

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      id: json['id']?.toString() ?? '',
      name: json['name_ar'] as String? ?? json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String?,
      grade: json['grade'] as String? ?? '',
      studentCount:
          (json['student_count'] ?? json['studentCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'grade': grade,
      'studentCount': studentCount,
    };
  }
}
