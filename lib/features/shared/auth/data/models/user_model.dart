import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.role,
    required super.token,
    super.avatar,
    super.busId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      role: UserRole.fromString(json['role']),
      token: json['token'],
      avatar: json['avatar'],
      busId: json['bus_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'token': token,
      'avatar': avatar,
      'bus_id': busId,
    };
  }
}
