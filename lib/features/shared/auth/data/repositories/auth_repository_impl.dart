import 'package:dartz/dartz.dart';

import '../../../../../core/error/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String id,
    required String password,
    required UserRole role,
  }) async {
    try {
      final user = await remoteDataSource.login(
        id: id,
        password: password,
        role: role,
      );

      // Cache the user data locally
      await localDataSource.cacheUser(user);

      return Right(user);
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('Invalid credentials')) {
        return const Left(AuthFailure('Invalid ID or password'));
      }
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearCache();
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCachedUser();
      return Right(user);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String id}) async {
    try {
      await remoteDataSource.resetPassword(id: id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
