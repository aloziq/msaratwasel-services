import 'package:equatable/equatable.dart';

enum UserRole {
  driver('سائق'),
  busAssistant('مساعد الباص'),
  fieldSupervisor('مشرف ميداني'),
  teacher('معلم');

  final String displayName;
  const UserRole(this.displayName);

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => UserRole.driver,
    );
  }
}

class UserEntity extends Equatable {
  final String id;
  final String name;
  final UserRole role;
  final String token;

  const UserEntity({
    required this.id,
    required this.name,
    required this.role,
    required this.token,
  });

  @override
  List<Object?> get props => [id, name, role, token];
}
