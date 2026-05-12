import 'package:dartz/dartz.dart';
import '../../../../../core/error/failure.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String id,
    required String password,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, void>> resetPassword({required String id});

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<Either<Failure, String>> updateAvatar(String imagePath);

  Future<Either<Failure, void>> updateProfile({
    required String phone,
    required String email,
    String? address,
    double? latitude,
    double? longitude,
  });

  Future<Either<Failure, void>> updateLanguage(String languageCode);
  Future<Either<Failure, void>> updateFcmToken(String fcmToken);
}
