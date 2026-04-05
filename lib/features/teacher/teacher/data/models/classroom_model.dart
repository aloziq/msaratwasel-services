import '../../domain/entities/classroom_entity.dart';

class ClassroomModel extends ClassroomEntity {
  const ClassroomModel({
    required super.id,
    required super.name,
    required super.grade,
    required super.studentCount,
  });

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'studentCount': studentCount,
    };
  }
}
