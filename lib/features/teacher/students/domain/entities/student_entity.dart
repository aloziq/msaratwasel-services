import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, absent, late, excused, unknown }

class StudentEntity extends Equatable {
  final String id;
  final String name;
  final String? nameEn;
  final String parentName;
  final String? parentNameEn;
  final String parentPhone;
  final String? photoUrl;
  final String? parentPhotoUrl;
  final AttendanceStatus status;
  final bool isLocked;

  const StudentEntity({
    required this.id,
    required this.name,
    this.nameEn,
    required this.parentName,
    this.parentNameEn,
    required this.parentPhone,
    this.photoUrl,
    this.parentPhotoUrl,
    this.status = AttendanceStatus.unknown,
    this.isLocked = false,
  });

  String getLocalizedName(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : name;
    }
    return name;
  }

  String getLocalizedParentName(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      return (parentNameEn != null && parentNameEn!.trim().isNotEmpty) ? parentNameEn! : parentName;
    }
    return parentName;
  }

  StudentEntity copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? parentName,
    String? parentNameEn,
    String? parentPhone,
    String? photoUrl,
    String? parentPhotoUrl,
    AttendanceStatus? status,
    bool? isLocked,
  }) {
    return StudentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      parentName: parentName ?? this.parentName,
      parentNameEn: parentNameEn ?? this.parentNameEn,
      parentPhone: parentPhone ?? this.parentPhone,
      photoUrl: photoUrl ?? this.photoUrl,
      parentPhotoUrl: parentPhotoUrl ?? this.parentPhotoUrl,
      status: status ?? this.status,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    nameEn,
    parentName,
    parentNameEn,
    parentPhone,
    photoUrl,
    parentPhotoUrl,
    status,
    isLocked,
  ];
}
