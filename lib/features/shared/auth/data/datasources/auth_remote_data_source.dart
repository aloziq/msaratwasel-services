import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String id,
    required String password,
    required UserRole role,
  });

  Future<void> resetPassword({required String id});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> login({
    required String id,
    required String password,
    required UserRole role,
  }) async {
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));

    // Role-based credential mapping
    final Map<UserRole, String> roleToId = {
      UserRole.teacher: '1',
      UserRole.busAssistant: '2',
      UserRole.driver: '3',
      UserRole.fieldSupervisor: '4',
    };

    final expectedId = roleToId[role];

    if (id == expectedId && password == '123456') {
      return UserModel(
        id: id,
        name: '${role.displayName} $id',
        role: role,
        token: 'mock_token_${role.name}_$id',
      );
    } else if (password != '123456') {
      throw Exception('كلمة المرور غير صحيحة');
    } else if (id != expectedId) {
      // Check if ID belongs to another role to provide better error message
      final otherRole = roleToId.entries
          .where((entry) => entry.value == id)
          .map((entry) => entry.key)
          .firstOrNull;

      if (otherRole != null) {
        throw Exception('هذا الرقم المدني مسجل كـ ${otherRole.displayName}');
      } else {
        throw Exception('الرقم المدني غير مسجل');
      }
    } else {
      throw Exception('فشل تسجيل الدخول: بيانات غير صحيحة');
    }
  }

  @override
  Future<void> resetPassword({required String id}) async {
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));
  }
}
