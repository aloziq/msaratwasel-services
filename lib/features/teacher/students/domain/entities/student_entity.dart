import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, absent, late, excused, unknown }

class StudentEntity extends Equatable {
  final String id;
  final String name;
  final String parentName;
  final String parentPhone;
  final String? photoUrl;
  final AttendanceStatus status;

  const StudentEntity({
    required this.id,
    required this.name,
    required this.parentName,
    required this.parentPhone,
    this.photoUrl,
    this.status = AttendanceStatus.unknown,
  });

  StudentEntity copyWith({
    String? id,
    String? name,
    String? parentName,
    String? parentPhone,
    String? photoUrl,
    AttendanceStatus? status,
  }) {
    return StudentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    parentName,
    parentPhone,
    photoUrl,
    status,
  ];
}
