import 'package:equatable/equatable.dart';

enum UserRole {
  driver,
  assistant,
  fieldSupervisor,
  teacher;

  const UserRole();

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'assistant':
      case 'bus_assistant':
        return UserRole.assistant;
      case 'field_supervisor':
      case 'fieldsupervisor':
        return UserRole.fieldSupervisor;
      case 'teacher':
        return UserRole.teacher;
      default:
        return UserRole.driver;
    }
  }
}

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String? nameEn;
  final UserRole role;
  final String token;
  final String? avatar;
  final int? busId;
  final String? email;
  final String? phone;
  final String? nationalId;
  final String? schoolName;
  final Map<String, dynamic>? busDetails;

  const UserEntity({
    required this.id,
    required this.name,
    this.nameEn,
    required this.role,
    required this.token,
    this.avatar,
    this.busId,
    this.email,
    this.phone,
    this.nationalId,
    this.schoolName,
    this.busDetails,
  });

  String getLocalizedName(String languageCode) {
    if (languageCode.toLowerCase() == 'en') {
      return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : name;
    }
    return name;
  }

  UserEntity copyWith({
    String? id,
    String? name,
    String? nameEn,
    UserRole? role,
    String? token,
    String? avatar,
    int? busId,
    String? email,
    String? phone,
    String? nationalId,
    String? schoolName,
    Map<String, dynamic>? busDetails,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      role: role ?? this.role,
      token: token ?? this.token,
      avatar: avatar ?? this.avatar,
      busId: busId ?? this.busId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      schoolName: schoolName ?? this.schoolName,
      busDetails: busDetails ?? this.busDetails,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, nameEn, role, token, avatar, busId, email, phone, nationalId, schoolName, busDetails];
}
