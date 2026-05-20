import '../../domain/entities/student_entity.dart';

class StudentModel extends StudentEntity {
  const StudentModel({
    required super.id,
    required super.name,
    super.nameEn,
    required super.parentName,
    super.parentNameEn,
    required super.parentPhone,
    super.photoUrl,
    super.parentPhotoUrl,
    super.status = AttendanceStatus.unknown,
    super.isLocked = false,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id']?.toString() ?? '',
      name:
          json['name_ar'] as String? ?? json['name'] as String? ?? 'غير معروف',
      nameEn:
          json['name_en'] as String? ?? json['nameEn'] as String?,
      parentName:
          json['parent_name'] as String? ?? json['parentName'] as String? ?? '',
      parentNameEn:
          json['parent_name_en'] as String? ?? json['parentNameEn'] as String?,
      parentPhone:
          json['parent_phone'] as String? ??
          json['parentPhone'] as String? ??
          '',
      photoUrl: json['image_url'] as String? ?? json['photoUrl'] as String?,
      parentPhotoUrl: json['parentPhotoUrl'] as String?,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.unknown,
      ),
      isLocked: json['isLocked'] as bool? ?? json['is_locked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'parentName': parentName,
      'parentNameEn': parentNameEn,
      'parentPhone': parentPhone,
      'photoUrl': photoUrl,
      'parentPhotoUrl': parentPhotoUrl,
      'status': status.name,
    };
  }
}
