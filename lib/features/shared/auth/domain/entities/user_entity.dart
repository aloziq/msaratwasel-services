import 'package:equatable/equatable.dart';

enum UserRole {
  driver,
  busAssistant,
  fieldSupervisor,
  teacher;

  const UserRole();

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'supervisor':
        return UserRole.busAssistant; // supervisor في Laravel → مشرف/مشرفة الحافلة
      case 'field_supervisor':
      case 'fieldsupervisor':
        return UserRole.fieldSupervisor; // field_supervisor في Laravel → المشرف الميداني
      case 'teacher':
        return UserRole.teacher;
      case 'busassistant':
        return UserRole.busAssistant;
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

  const UserEntity({
    required this.id,
    required this.name,
    required this.role,
    required this.token,
    this.avatar,
    this.busId,
  });

  @override
  List<Object?> get props => [id, name, role, token, avatar, busId];
}
