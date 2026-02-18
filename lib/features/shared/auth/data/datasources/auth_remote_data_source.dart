import 'package:injectable/injectable.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'mock_auth_data.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String id,
    required String password,
    required UserRole role,
  });

  Future<void> resetPassword({required String id});
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> login({
    required String id,
    required String password,
    required UserRole role,
  }) async {
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));

    // Role-based credential mapping (from mock data)
    // See mock_auth_data.dart for values
    final String? expectedId = kMockRoleToId[role];

    if (id == expectedId && password == kMockPassword) {
      return UserModel(
        id: id,
        name: '${role.name} $id',
        role: role,
        token: 'mock_token_${role.name}_$id',
      );
    } else if (password != kMockPassword) {
      throw Exception('Password is incorrect');
    } else if (id != expectedId) {
      // Check if ID belongs to another role to provide better error message
      final otherRole = kMockRoleToId.entries
          .where((entry) => entry.value == id)
          .map((entry) => entry.key)
          .firstOrNull;

      if (otherRole != null) {
        throw Exception('This civil ID is registered as ${otherRole.name}');
      } else {
        throw Exception('This civil ID is not registered');
      }
    } else {
      throw Exception('Login failed: Invalid credentials');
    }
  }

  @override
  Future<void> resetPassword({required String id}) async {
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));
  }
}
