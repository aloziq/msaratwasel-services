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
      id: json['id'],
      name: json['name'],
      grade: json['grade'],
      studentCount: json['studentCount'],
    );
  }
}
