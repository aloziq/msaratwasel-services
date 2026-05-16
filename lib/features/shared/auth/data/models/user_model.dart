import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.role,
    required super.token,
    super.avatar,
    super.busId,
    super.email,
    super.phone,
    super.nationalId,
    super.schoolName,
    super.busDetails,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString() ?? ''),
      token: json['token']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      busId: json['bus_id'] != null ? int.tryParse(json['bus_id'].toString()) : null,
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      nationalId: json['national_id']?.toString(),
      schoolName: json['school_name']?.toString(),
      busDetails: json['bus'] is Map<String, dynamic> ? json['bus'] : null,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      role: entity.role,
      token: entity.token,
      avatar: entity.avatar,
      busId: entity.busId,
      email: entity.email,
      phone: entity.phone,
      nationalId: entity.nationalId,
      schoolName: entity.schoolName,
      busDetails: entity.busDetails,
    );
  }

  @override
  UserModel copyWith({
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
    return UserModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'token': token,
      'avatar': avatar,
      'bus_id': busId,
      'email': email,
      'phone': phone,
      'national_id': nationalId,
      'school_name': schoolName,
      'bus': busDetails,
    };
  }
}
