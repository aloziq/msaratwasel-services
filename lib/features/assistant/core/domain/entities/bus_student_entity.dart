import 'package:equatable/equatable.dart';

enum BusStudentStatus {
  atHome,
  onBus,
  atSchool,
  absent,
  waiting,
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
      case BusStudentStatus.waiting:
        return 'انتظار';
      case BusStudentStatus.unknown:
        return 'غير محدد';
    }
  }
}

class BusStudentEntity extends Equatable {
  final String id;
  final String studentCode;
  final String name;
  final String grade;
  final String schoolId;
  final String parentName;
  final String parentPhone;
  final String? parentUserId;
  final String? photoUrl;
  final BusStudentStatus status;
  final String? behavioralNote;
  final DateTime? waitingSince;

  const BusStudentEntity({
    required this.id,
    required this.studentCode,
    required this.name,
    required this.grade,
    required this.schoolId,
    required this.parentName,
    required this.parentPhone,
    this.parentUserId,
    this.photoUrl,
    this.status = BusStudentStatus.unknown,
    this.behavioralNote,
    this.waitingSince,
  });

  BusStudentEntity copyWith({
    String? id,
    String? studentCode,
    String? name,
    String? grade,
    String? schoolId,
    String? parentName,
    String? parentPhone,
    String? parentUserId,
    String? photoUrl,
    BusStudentStatus? status,
    String? behavioralNote,
    DateTime? waitingSince,
  }) {
    return BusStudentEntity(
      id: id ?? this.id,
      studentCode: studentCode ?? this.studentCode,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      schoolId: schoolId ?? this.schoolId,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentUserId: parentUserId ?? this.parentUserId,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      behavioralNote: behavioralNote ?? this.behavioralNote,
      waitingSince: waitingSince ?? this.waitingSince,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentCode,
    name,
    grade,
    schoolId,
    parentName,
    parentPhone,
    parentUserId,
    photoUrl,
    status,
    behavioralNote,
    waitingSince,
  ];
}
