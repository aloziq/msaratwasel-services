import 'package:equatable/equatable.dart';

enum BusStudentStatus {
  atHome,
  onBus,
  atSchool,
  absent,
  unknown;

  String get labelAr {
    switch (this) {
      case BusStudentStatus.atHome:
        return 'في المنزل';
      case BusStudentStatus.onBus:
        return 'في الحافلة';
      case BusStudentStatus.atSchool:
        return 'في المدرسة';
      case BusStudentStatus.absent:
        return 'غائب';
      case BusStudentStatus.unknown:
        return 'غير محدد';
    }
  }
}

class BusStudentEntity extends Equatable {
  final String id;
  final String name;
  final String grade;
  final String schoolId;
  final String parentName;
  final String parentPhone;
  final String? photoUrl;
  final BusStudentStatus status;
  final String? behavioralNote;

  const BusStudentEntity({
    required this.id,
    required this.name,
    required this.grade,
    required this.schoolId,
    required this.parentName,
    required this.parentPhone,
    this.photoUrl,
    this.status = BusStudentStatus.unknown,
    this.behavioralNote,
  });

  BusStudentEntity copyWith({
    String? id,
    String? name,
    String? grade,
    String? schoolId,
    String? parentName,
    String? parentPhone,
    String? photoUrl,
    BusStudentStatus? status,
    String? behavioralNote,
  }) {
    return BusStudentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      schoolId: schoolId ?? this.schoolId,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      behavioralNote: behavioralNote ?? this.behavioralNote,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    grade,
    schoolId,
    parentName,
    parentPhone,
    photoUrl,
    status,
    behavioralNote,
  ];
}
