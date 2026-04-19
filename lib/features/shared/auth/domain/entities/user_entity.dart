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

  UserEntity copyWith({
    String? id,
    String? name,
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
      [id, name, role, token, avatar, busId, email, phone, nationalId, schoolName, busDetails];
}
