import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import '../../../../../core/error/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

@LazySingleton(as: AuthRepository)
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
  }) async {
    try {
      final user = await remoteDataSource.login(
        nationalId: id,
        password: password,
      );

      await localDataSource.cacheUser(user);

      return Right(user);
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('Invalid') || message.contains('غير صحيحة')) {
        return Left(AuthFailure(message));
      }
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // جلب الـ token المحفوظ محلياً لإرساله للـ API
      final user = await localDataSource.getCachedUser();
      await remoteDataSource.logout(token: user.token);
      await localDataSource.clearCache();
      return const Right(null);
    } on Exception catch (e) {
      // حتى لو فشل الـ logout من السيرفر، نمسح البيانات المحلية
      await localDataSource.clearCache();
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
    // لم يُنفَّذ بعد في الـ Backend
    return const Right(null);
  }
}
