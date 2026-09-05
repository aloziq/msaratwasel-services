import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/core/services/fcm_service.dart';
import 'package:msaratwasel_services/core/usecases/usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/repositories/auth_repository.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/change_password_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/login_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/logout_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/reset_password_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/update_avatar_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/update_fcm_token_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';

const testUser = UserEntity(
  id: '101',
  name: 'سالم السعدي',
  role: UserRole.driver,
  token: 'mock_driver_token',
  phone: '96891234567',
  avatar: 'https://example.com/avatar.jpg',
);

class FakeLoginUseCase extends Fake implements LoginUseCase {
  Either<Failure, UserEntity>? result;
  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async => result!;
}

class FakeLogoutUseCase extends Fake implements LogoutUseCase {
  Either<Failure, void>? result;
  @override
  Future<Either<Failure, void>> call(NoParams params) async => result ?? const Right(null);
}

class FakeGetCurrentUserUseCase extends Fake implements GetCurrentUserUseCase {
  Either<Failure, UserEntity>? result;
  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async => result!;
}

class FakeResetPasswordUseCase extends Fake implements ResetPasswordUseCase {
  Either<Failure, void>? result;
  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async => result!;
}

class FakeChangePasswordUseCase extends Fake implements ChangePasswordUseCase {
  Either<Failure, void>? result;
  @override
  Future<Either<Failure, void>> call(ChangePasswordParams params) async => result!;
}

class FakeUpdateAvatarUseCase extends Fake implements UpdateAvatarUseCase {
  Either<Failure, String>? result;
  @override
  Future<Either<Failure, String>> call(String path) async => result!;
}

class FakeUpdateFcmTokenUseCase extends Fake implements UpdateFcmTokenUseCase {
  @override
  Future<Either<Failure, void>> call(String token) async => const Right(null);
}

class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  Future<Either<Failure, UserEntity>> refreshUserProfile() async => const Right(testUser);
}

class FakeFcmService extends Fake implements FcmService {
  bool deleteTokenCalled = false;
  @override
  Future<String?> getToken() async => 'fake_fcm_token';

  @override
  Future<void> deleteToken() async {
    deleteTokenCalled = true;
  }
}

class FakeBackgroundServicePlatform extends FlutterBackgroundServicePlatform {
  @override
  Future<bool> configure({
    required IosConfiguration iosConfiguration,
    required AndroidConfiguration androidConfiguration,
  }) async => true;

  @override
  Future<bool> start() async => true;

  @override
  Future<bool> isServiceRunning() async => false;

  @override
  void invoke(String method, [Map<String, dynamic>? args]) {}

  @override
  Stream<Map<String, dynamic>?> on(String method) => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterBackgroundServicePlatform.instance = FakeBackgroundServicePlatform();

  late AuthCubit cubit;
  late FakeLoginUseCase fakeLoginUseCase;
  late FakeLogoutUseCase fakeLogoutUseCase;
  late FakeGetCurrentUserUseCase fakeGetCurrentUserUseCase;
  late FakeResetPasswordUseCase fakeResetPasswordUseCase;
  late FakeChangePasswordUseCase fakeChangePasswordUseCase;
  late FakeUpdateAvatarUseCase fakeUpdateAvatarUseCase;
  late FakeUpdateFcmTokenUseCase fakeUpdateFcmTokenUseCase;
  late FakeAuthRepository fakeAuthRepository;
  late FakeFcmService fakeFcmService;

  setUp(() {
    fakeLoginUseCase = FakeLoginUseCase();
    fakeLogoutUseCase = FakeLogoutUseCase();
    fakeGetCurrentUserUseCase = FakeGetCurrentUserUseCase();
    fakeResetPasswordUseCase = FakeResetPasswordUseCase();
    fakeChangePasswordUseCase = FakeChangePasswordUseCase();
    fakeUpdateAvatarUseCase = FakeUpdateAvatarUseCase();
    fakeUpdateFcmTokenUseCase = FakeUpdateFcmTokenUseCase();
    fakeAuthRepository = FakeAuthRepository();
    fakeFcmService = FakeFcmService();

    if (getIt.isRegistered<FcmService>()) {
      getIt.unregister<FcmService>();
    }
    getIt.registerSingleton<FcmService>(fakeFcmService);

    cubit = AuthCubit(
      loginUseCase: fakeLoginUseCase,
      logoutUseCase: fakeLogoutUseCase,
      getCurrentUserUseCase: fakeGetCurrentUserUseCase,
      resetPasswordUseCase: fakeResetPasswordUseCase,
      changePasswordUseCase: fakeChangePasswordUseCase,
      updateAvatarUseCase: fakeUpdateAvatarUseCase,
      updateFcmTokenUseCase: fakeUpdateFcmTokenUseCase,
      authRepository: fakeAuthRepository,
    );
  });

  tearDown(() async {
    await cubit.close();
    if (getIt.isRegistered<FcmService>()) {
      getIt.unregister<FcmService>();
    }
  });

  group('Agent 1 (srv-auth) — Services App AuthCubit Suite', () {
    test('1. Initial state is AuthInitial', () {
      expect(cubit.state, isA<AuthInitial>());
    });

    test('2. checkAuthStatus emits AuthAuthenticated when user session exists', () async {
      fakeGetCurrentUserUseCase.result = const Right(testUser);

      await cubit.checkAuthStatus();

      expect(cubit.state, isA<AuthAuthenticated>());
      final authState = cubit.state as AuthAuthenticated;
      expect(authState.user.id, '101');
      expect(authState.user.name, 'سالم السعدي');
      expect(authState.user.token, 'mock_driver_token');
    });

    test('3. checkAuthStatus emits AuthUnauthenticated when no session exists', () async {
      fakeGetCurrentUserUseCase.result = const Left(ServerFailure('No session'));

      await cubit.checkAuthStatus();

      expect(cubit.state, isA<AuthUnauthenticated>());
    });

    test('4. login emits AuthAuthenticated on valid credentials', () async {
      fakeLoginUseCase.result = const Right(testUser);

      await cubit.login(
        id: '101',
        password: 'secure_password',
        selectedRole: UserRole.driver,
      );

      expect(cubit.state, isA<AuthAuthenticated>());
      final auth = cubit.state as AuthAuthenticated;
      expect(auth.user.id, '101');
      expect(auth.user.role, UserRole.driver);
    });

    test('5. login emits AuthError on 401 invalid credentials', () async {
      fakeLoginUseCase.result = const Left(ServerFailure('بيانات الدخول غير صحيحة'));

      await cubit.login(
        id: '101',
        password: 'wrong_password',
        selectedRole: UserRole.driver,
      );

      expect(cubit.state, isA<AuthError>());
      final err = cubit.state as AuthError;
      expect(err.message, 'بيانات الدخول غير صحيحة');
    });

    test('6. logout emits AuthUnauthenticated and triggers token cleanup', () async {
      fakeLogoutUseCase.result = const Right(null);

      await cubit.logout();

      expect(cubit.state, isA<AuthUnauthenticated>());
      expect(fakeFcmService.deleteTokenCalled, isTrue);
    });

    test('7. resetPassword emits AuthPasswordResetSent on success', () async {
      fakeResetPasswordUseCase.result = const Right(null);

      await cubit.resetPassword('101');

      expect(cubit.state, isA<AuthPasswordResetSent>());
    });

    test('8. resetPassword emits AuthError on failure', () async {
      fakeResetPasswordUseCase.result = const Left(ServerFailure('المستخدم غير موجود'));

      await cubit.resetPassword('999');

      expect(cubit.state, isA<AuthError>());
      expect((cubit.state as AuthError).message, 'المستخدم غير موجود');
    });

    test('9. changePassword returns true on success and false on failure', () async {
      fakeChangePasswordUseCase.result = const Right(null);

      final success = await cubit.changePassword(
        currentPassword: 'old_pw',
        newPassword: 'new_pw',
        confirmPassword: 'new_pw',
      );
      expect(success, isTrue);

      fakeChangePasswordUseCase.result = const Left(ServerFailure('كلمة السر القديمة غير صحيحة'));

      final failed = await cubit.changePassword(
        currentPassword: 'wrong_old_pw',
        newPassword: 'new_pw',
        confirmPassword: 'new_pw',
      );
      expect(failed, isFalse);
      expect(cubit.state, isA<AuthError>());
    });

    test('10. updateAvatar updates user entity in AuthAuthenticated state', () async {
      fakeGetCurrentUserUseCase.result = const Right(testUser);
      await cubit.checkAuthStatus();
      expect(cubit.state, isA<AuthAuthenticated>());

      fakeUpdateAvatarUseCase.result = const Right('https://example.com/new_avatar.jpg');

      await cubit.updateAvatar('/path/to/image.png');

      expect(cubit.state, isA<AuthAuthenticated>());
      final updatedState = cubit.state as AuthAuthenticated;
      expect(updatedState.user.avatar, 'https://example.com/new_avatar.jpg');
    });

    test('11. forceLogout stops services and immediately unauthenticates', () {
      cubit.forceLogout();
      expect(cubit.state, isA<AuthUnauthenticated>());
      expect(fakeFcmService.deleteTokenCalled, isTrue);
    });
  });
}
