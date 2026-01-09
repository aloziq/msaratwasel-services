import 'package:equatable/equatable.dart';

class ClassroomEntity extends Equatable {
  final String id;
  final String name;
  final String grade;
  final int studentCount;

  const ClassroomEntity({
    required this.id,
    required this.name,
    required this.grade,
    required this.studentCount,
  });

  @override
  List<Object?> get props => [id, name, grade, studentCount];
}
