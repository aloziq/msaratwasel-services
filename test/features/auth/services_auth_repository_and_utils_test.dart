import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/core/usecases/usecase.dart';
import 'package:msaratwasel_services/core/utils/location_utils.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/time_formatter.dart';
import 'package:msaratwasel_services/features/shared/auth/data/datasources/auth_local_data_source.dart';
import 'package:msaratwasel_services/features/shared/auth/data/datasources/auth_remote_data_source.dart';
import 'package:msaratwasel_services/features/shared/auth/data/models/user_model.dart';
import 'package:msaratwasel_services/features/shared/auth/data/repositories/auth_repository_impl.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/repositories/auth_repository.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/change_password_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/login_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/reset_password_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/update_avatar_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/update_fcm_token_usecase.dart';
import 'package:msaratwasel_services/features/shared/presentation/widgets/hold_to_confirm_button.dart';

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  UserModel? userToReturn;
  String? avatarUrlToReturn;
  Exception? exceptionToThrow;

  @override
  Future<UserModel> login({required String nationalId, required String password}) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return userToReturn!;
  }

  @override
  Future<void> logout({required String token, String? fcmToken}) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }

  @override
  Future<String> resetPassword({required String nationalId}) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return 'Reset email sent';
  }

  @override
  Future<String> updateAvatar({required String imagePath}) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return avatarUrlToReturn ?? 'https://example.com/new_avatar.jpg';
  }

  @override
  Future<void> updateProfile({
    required String phone,
    required String email,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }

  @override
  Future<void> updateLanguage(String languageCode) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }

  @override
  Future<UserModel> fetchUserProfile() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return userToReturn!;
  }

  @override
  Future<void> updateFcmToken(String fcmToken) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }
}

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  UserModel? cachedUser;
  bool clearCacheCalled = false;

  @override
  Future<UserModel> getCachedUser() async {
    if (cachedUser == null) throw Exception('No cached user found');
    return cachedUser!;
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    cachedUser = user;
  }

  @override
  Future<void> clearCache() async {
    cachedUser = null;
    clearCacheCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: '10',
    name: 'سالم الكعبي',
    nameEn: 'Salem Al-Kaabi',
    role: UserRole.driver,
    token: 'jwt_salem_token',
    avatar: 'https://example.com/avatar.jpg',
    busId: 12,
    phone: '96899999999',
    email: 'salem@wasel.com',
    nationalId: '1020304050',
    schoolName: 'مدرسة التميز',
    busDetails: {'plate': '1234 A', 'capacity': 30},
  );

  group('AuthLocalDataSourceImpl Direct Suite', () {
    test('1. cacheUser saves all fields and getCachedUser returns reconstructed UserModel', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localDataSource = AuthLocalDataSourceImpl(prefs);

      await localDataSource.cacheUser(testUser);

      final fetched = await localDataSource.getCachedUser();
      expect(fetched.id, '10');
      expect(fetched.name, 'سالم الكعبي');
      expect(fetched.nameEn, 'Salem Al-Kaabi');
      expect(fetched.role, UserRole.driver);
      expect(fetched.token, 'jwt_salem_token');
      expect(fetched.avatar, 'https://example.com/avatar.jpg');
      expect(fetched.busId, 12);
      expect(fetched.phone, '96899999999');
      expect(fetched.email, 'salem@wasel.com');
      expect(fetched.nationalId, '1020304050');
      expect(fetched.schoolName, 'مدرسة التميز');
      expect(fetched.busDetails?['plate'], '1234 A');
    });

    test('2. getCachedUser throws Exception when keys are missing and clearCache wipes them', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localDataSource = AuthLocalDataSourceImpl(prefs);

      expect(() => localDataSource.getCachedUser(), throwsException);

      // Cache and then clear
      await localDataSource.cacheUser(testUser);
      expect(await localDataSource.getCachedUser(), isNotNull);

      await localDataSource.clearCache();
      expect(() => localDataSource.getCachedUser(), throwsException);
    });
  });

  group('AuthRepositoryImpl Suite', () {
    late FakeAuthRemoteDataSource remoteDs;
    late FakeAuthLocalDataSource localDs;
    late AuthRepositoryImpl repo;

    setUp(() {
      remoteDs = FakeAuthRemoteDataSource();
      localDs = FakeAuthLocalDataSource();
      repo = AuthRepositoryImpl(
        remoteDataSource: remoteDs,
        localDataSource: localDs,
      );
    });

    test('3. login succeeds, saves user in local cache, and returns Right(UserEntity)', () async {
      remoteDs.userToReturn = testUser;

      final result = await repo.login(id: '1020304050', password: 'password123');

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got $failure'),
        (user) {
          expect(user.id, '10');
          expect(user.name, 'سالم الكعبي');
          expect(user.role, UserRole.driver);
        },
      );
      expect(localDs.cachedUser, isNotNull);
      expect(localDs.cachedUser?.id, '10');
    });

    test('4. login maps invalid credentials to AuthFailure', () async {
      remoteDs.exceptionToThrow = Exception('بيانات الدخول غير صحيحة');

      final result = await repo.login(id: 'wrong_id', password: 'wrong_password');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, contains('غير صحيحة'));
        },
        (user) => fail('Expected failure'),
      );
    });

    test('5. getCurrentUser returns cached user or CacheFailure', () async {
      localDs.cachedUser = testUser;
      final resultSuccess = await repo.getCurrentUser();
      expect(resultSuccess.isRight(), isTrue);

      localDs.cachedUser = null;
      final resultFail = await repo.getCurrentUser();
      expect(resultFail.isLeft(), isTrue);
      expect(resultFail.swap().getOrElse(() => ServerFailure('')), isA<CacheFailure>());
    });

    test('6. resetPassword and changePassword handle success and server error', () async {
      final resetSuccess = await repo.resetPassword(id: '1020304050');
      expect(resetSuccess.isRight(), isTrue);

      remoteDs.exceptionToThrow = Exception('Database error');
      final resetFail = await repo.resetPassword(id: '1020304050');
      expect(resetFail.isLeft(), isTrue);

      remoteDs.exceptionToThrow = null;
      final changeSuccess = await repo.changePassword(
        currentPassword: 'old',
        newPassword: 'new',
        confirmPassword: 'new',
      );
      expect(changeSuccess.isRight(), isTrue);
    });

    test('7. updateAvatar and updateProfile mutate local cache seamlessly', () async {
      localDs.cachedUser = testUser;
      remoteDs.avatarUrlToReturn = 'https://example.com/updated.jpg';

      final avatarResult = await repo.updateAvatar('path/to/img.jpg');
      expect(avatarResult.isRight(), isTrue);
      expect(localDs.cachedUser?.avatar, 'https://example.com/updated.jpg');

      final profileResult = await repo.updateProfile(
        phone: '96811111111',
        email: 'new_email@wasel.com',
      );
      expect(profileResult.isRight(), isTrue);
      expect(localDs.cachedUser?.phone, '96811111111');
      expect(localDs.cachedUser?.email, 'new_email@wasel.com');
    });

    test('8. updateLanguage and updateFcmToken return Right(null)', () async {
      final langResult = await repo.updateLanguage('ar');
      expect(langResult.isRight(), isTrue);

      final fcmResult = await repo.updateFcmToken('new_fcm_token');
      expect(fcmResult.isRight(), isTrue);
    });
  });

  group('Auth Domain Use Cases Suite', () {
    late FakeAuthRemoteDataSource remoteDs;
    late FakeAuthLocalDataSource localDs;
    late AuthRepository repo;

    setUp(() {
      remoteDs = FakeAuthRemoteDataSource();
      localDs = FakeAuthLocalDataSource();
      remoteDs.userToReturn = testUser;
      localDs.cachedUser = testUser;
      repo = AuthRepositoryImpl(remoteDataSource: remoteDs, localDataSource: localDs);
    });

    test('9. LoginUseCase invokes authRepository.login', () async {
      final usecase = LoginUseCase(repo);
      final result = await usecase(LoginParams(id: '10', password: 'pass'));
      expect(result.isRight(), isTrue);
    });

    test('10. ChangePasswordUseCase and ResetPasswordUseCase execute', () async {
      final changeUsecase = ChangePasswordUseCase(repo);
      final changeResult = await changeUsecase(const ChangePasswordParams(
        currentPassword: 'old',
        newPassword: 'new',
        confirmPassword: 'new',
      ));
      expect(changeResult.isRight(), isTrue);

      final resetUsecase = ResetPasswordUseCase(repo);
      final resetResult = await resetUsecase(const ResetPasswordParams(id: '1020304050'));
      expect(resetResult.isRight(), isTrue);
    });

    test('11. GetCurrentUserUseCase, UpdateAvatarUseCase, and UpdateFcmTokenUseCase execute', () async {
      final getUsecase = GetCurrentUserUseCase(repo);
      final userResult = await getUsecase(NoParams());
      expect(userResult.isRight(), isTrue);

      final avatarUsecase = UpdateAvatarUseCase(repo);
      final avatarResult = await avatarUsecase('path/to/avatar.jpg');
      expect(avatarResult.isRight(), isTrue);

      final fcmUsecase = UpdateFcmTokenUseCase(repo);
      final fcmResult = await fcmUsecase('fcm_token_123');
      expect(fcmResult.isRight(), isTrue);
    });
  });

  group('LocationUtils & TimeFormatter Calculation Suite', () {
    test('12. LocationUtils calculations and bilingual formatting', () {
      expect(LocationUtils.calculateEtaMinutes(80.0), 60.0);
      expect(LocationUtils.calculateEtaMinutes(40.0), 30.0);
      expect(LocationUtils.calculateEtaMinutesRounded(40.0), 30);

      // Arabic ETA format
      expect(LocationUtils.formatEtaArabic(100.0), '1 ساعة و 15 دقيقة');
      expect(LocationUtils.formatEtaArabic(80.0), '1 ساعة');
      expect(LocationUtils.formatEtaArabic(20.0), '15 دقيقة');

      // English ETA format
      expect(LocationUtils.formatEtaEnglish(100.0), '1 hr 15 min');
      expect(LocationUtils.formatEtaEnglish(80.0), '1 hr');
      expect(LocationUtils.formatEtaEnglish(20.0), '15 min');

      // Haversine distance between Muscat points
      final distance = LocationUtils.calculateDistance(23.5880, 58.3820, 23.5880, 58.3920);
      expect(distance, greaterThan(900));
      expect(distance, lessThan(1150));
    });

    test('13. TimeFormatter relative time and compact strings', () {
      final now = DateTime.now();

      final tenMinutesAgo = now.subtract(const Duration(minutes: 10));
      expect(formatRelativeTime(tenMinutesAgo), 'منذ 10 دقيقة');
      expect(formatRelativeTimeCompact(tenMinutesAgo), '10د');

      final threeHoursAgo = now.subtract(const Duration(hours: 3));
      expect(formatRelativeTime(threeHoursAgo), 'منذ 3 ساعة');
      expect(formatRelativeTimeCompact(threeHoursAgo), '3س');

      final twoDaysAgo = now.subtract(const Duration(days: 2));
      expect(formatRelativeTime(twoDaysAgo), 'منذ 2 يوم');
      expect(formatRelativeTimeCompact(twoDaysAgo), '2ي');
    });
  });

  group('HoldToConfirmButton Widget Suite', () {
    testWidgets('14. HoldToConfirmButton displays label, icon, and handles long hold confirmation', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldToConfirmButton(
              label: 'تأكيد إخلاء الحافلة',
              icon: Icons.check,
              duration: const Duration(milliseconds: 300),
              onConfirmed: () {
                confirmed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('تأكيد إخلاء الحافلة'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Short tap should not confirm
      await tester.tap(find.byType(HoldToConfirmButton));
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);

      // Long hold down
      final gesture = await tester.startGesture(tester.getCenter(find.byType(HoldToConfirmButton)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('استمر في الضغط للارسال...'), findsOneWidget);

      // Finish hold (duration is 300ms, pump 500ms to guarantee completion)
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });
  });
}
