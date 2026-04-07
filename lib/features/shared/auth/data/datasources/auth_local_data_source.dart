import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<UserModel> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl(this.sharedPreferences);

  static const String _userIdKey = 'USER_ID';
  static const String _userNameKey = 'USER_NAME';
  static const String _userRoleKey = 'USER_ROLE';
  static const String _userTokenKey = 'USER_TOKEN';
  static const String _userAvatarKey = 'USER_AVATAR';
  static const String _userBusIdKey = 'USER_BUS_ID';
  static const String _userPhoneKey = 'USER_PHONE';
  static const String _userEmailKey = 'USER_EMAIL';
  static const String _userNationalIdKey = 'USER_NATIONAL_ID';
  static const String _userSchoolNameKey = 'USER_SCHOOL_NAME';
  static const String _userBusDetailsKey = 'USER_BUS_DETAILS';

  @override
  Future<UserModel> getCachedUser() async {
    final id = sharedPreferences.getString(_userIdKey);
    final name = sharedPreferences.getString(_userNameKey);
    final roleString = sharedPreferences.getString(_userRoleKey);
    final token = sharedPreferences.getString(_userTokenKey);
    final avatar = sharedPreferences.getString(_userAvatarKey);
    final busIdString = sharedPreferences.getString(_userBusIdKey);
    final busId = busIdString != null ? int.tryParse(busIdString) : null;
    final phone = sharedPreferences.getString(_userPhoneKey);
    final email = sharedPreferences.getString(_userEmailKey);
    final nationalId = sharedPreferences.getString(_userNationalIdKey);
    final schoolName = sharedPreferences.getString(_userSchoolNameKey);
    final busDetailsStr = sharedPreferences.getString(_userBusDetailsKey);
    Map<String, dynamic>? busDetails;
    if (busDetailsStr != null) {
      busDetails = jsonDecode(busDetailsStr);
    }

    if (id != null && name != null && roleString != null && token != null) {
      return UserModel(
        id: id,
        name: name,
        role: UserRole.fromString(roleString),
        token: token,
        avatar: avatar,
        busId: busId,
        phone: phone,
        email: email,
        nationalId: nationalId,
        schoolName: schoolName,
        busDetails: busDetails,
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
    
    if (user.avatar != null) {
      await sharedPreferences.setString(_userAvatarKey, user.avatar!);
    } else {
      await sharedPreferences.remove(_userAvatarKey);
    }
    
    if (user.busId != null) {
      await sharedPreferences.setString(_userBusIdKey, user.busId.toString());
    } else {
      await sharedPreferences.remove(_userBusIdKey);
    }

    if (user.phone != null) {
      await sharedPreferences.setString(_userPhoneKey, user.phone!);
    } else {
      await sharedPreferences.remove(_userPhoneKey);
    }

    if (user.email != null) {
      await sharedPreferences.setString(_userEmailKey, user.email!);
    } else {
      await sharedPreferences.remove(_userEmailKey);
    }

    if (user.nationalId != null) {
      await sharedPreferences.setString(_userNationalIdKey, user.nationalId!);
    } else {
      await sharedPreferences.remove(_userNationalIdKey);
    }

    if (user.schoolName != null) {
      await sharedPreferences.setString(_userSchoolNameKey, user.schoolName!);
    } else {
      await sharedPreferences.remove(_userSchoolNameKey);
    }

    if (user.busDetails != null) {
      await sharedPreferences.setString(_userBusDetailsKey, jsonEncode(user.busDetails));
    } else {
      await sharedPreferences.remove(_userBusDetailsKey);
    }
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_userIdKey);
    await sharedPreferences.remove(_userNameKey);
    await sharedPreferences.remove(_userRoleKey);
    await sharedPreferences.remove(_userTokenKey);
    await sharedPreferences.remove(_userAvatarKey);
    await sharedPreferences.remove(_userBusIdKey);
    await sharedPreferences.remove(_userSchoolNameKey);
    await sharedPreferences.remove(_userBusDetailsKey);
  }
}
