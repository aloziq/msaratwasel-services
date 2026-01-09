import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl(this.sharedPreferences);

  static const String _userIdKey = 'USER_ID';
  static const String _userNameKey = 'USER_NAME';
  static const String _userRoleKey = 'USER_ROLE';
  static const String _userTokenKey = 'USER_TOKEN';

  @override
  Future<UserModel> getCachedUser() async {
    final id = sharedPreferences.getString(_userIdKey);
    final name = sharedPreferences.getString(_userNameKey);
    final roleString = sharedPreferences.getString(_userRoleKey);
    final token = sharedPreferences.getString(_userTokenKey);

    if (id != null && name != null && roleString != null && token != null) {
      return UserModel(
        id: id,
        name: name,
        role: UserRole.fromString(roleString),
        token: token,
      );
    } else {
      throw Exception('No cached user found');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await sharedPreferences.setString(_userIdKey, user.id);
    await sharedPreferences.setString(_userNameKey, user.name);
    await sharedPreferences.setString(_userRoleKey, user.role.name);
    await sharedPreferences.setString(_userTokenKey, user.token);
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_userIdKey);
    await sharedPreferences.remove(_userNameKey);
    await sharedPreferences.remove(_userRoleKey);
    await sharedPreferences.remove(_userTokenKey);
  }
}
