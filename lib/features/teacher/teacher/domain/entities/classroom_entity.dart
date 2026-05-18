import 'package:equatable/equatable.dart';

class ClassroomEntity extends Equatable {
  final String id;
  final String name;
  final String? nameEn;
  final String grade;
  final int studentCount;

  const ClassroomEntity({
    required this.id,
    required this.name,
    this.nameEn,
    required this.grade,
    required this.studentCount,
  });

  String getLocalizedName(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : name;
    }
    return name;
  }

  @override
  List<Object?> get props => [id, name, nameEn, grade, studentCount];
}
