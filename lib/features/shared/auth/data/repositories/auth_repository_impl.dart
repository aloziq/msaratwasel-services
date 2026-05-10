import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import '../../../../../core/error/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/services/fcm_service.dart';

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
      final fcmToken = await getIt<FcmService>().getToken();

      // إرسال طلب تسجيل الخروج للخلفية دون انتظار (Fire and Forget)
      // لتجنب التأخير لمدة 30 ثانية في حال كان السيرفر غير متاح
      remoteDataSource.logout(
        token: user.token,
        fcmToken: fcmToken,
      ).catchError((_) {});

      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      // في حال حدوث أي خطأ، نمسح الكاش المحلي ونسمح للمستخدم بالخروج
      await localDataSource.clearCache();
      return const Right(null);
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
    // لم يُنفَّذ بعد في الـ Backend بشكل كامل
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, String>> updateAvatar(String imagePath) async {
    try {
      final imageUrl = await remoteDataSource.updateAvatar(
        imagePath: imagePath,
      );

      // تحديث بيانات المستخدم في الكاش المحلي
      final UserModel currentUser = await localDataSource.getCachedUser();
      final updatedUser = currentUser.copyWith(avatar: imageUrl);
      await localDataSource.cacheUser(updatedUser);

      return Right(imageUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    required String phone,
    required String email,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await remoteDataSource.updateProfile(
        phone: phone,
        email: email,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      // تحديث بيانات المستخدم في الكاش المحلي
      final UserModel currentUser = await localDataSource.getCachedUser();
      final updatedUser = currentUser.copyWith(phone: phone, email: email);
      await localDataSource.cacheUser(updatedUser);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> updateLanguage(String languageCode) async {
    try {
      await remoteDataSource.updateLanguage(languageCode);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
