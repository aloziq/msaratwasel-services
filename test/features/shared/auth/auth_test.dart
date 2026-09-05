import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/features/shared/auth/data/models/user_model.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/data/repositories/auth_repository_impl.dart';
import 'package:msaratwasel_services/features/shared/auth/data/datasources/auth_remote_data_source.dart';
import 'package:msaratwasel_services/features/shared/auth/data/datasources/auth_local_data_source.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fakes
// ─────────────────────────────────────────────────────────────────────────────

class FakeRemoteDataSource implements AuthRemoteDataSource {
  UserModel? userToReturn;
  Exception? exceptionToThrow;
  String? lastLogoutToken;
  String? lastChangedPassword;
  String? lastLanguage;
  String? lastFcmToken;
  String? avatarUrlToReturn;
  String? resetPasswordMessage;

  @override
  Future<UserModel> login({required String nationalId, required String password}) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return userToReturn!;
  }

  @override
  Future<void> logout({required String token, String? fcmToken}) async {
    lastLogoutToken = token;
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword, required String confirmPassword}) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    lastChangedPassword = newPassword;
  }

  @override
  Future<void> updateProfile({required String phone, required String email, String? address, double? latitude, double? longitude}) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }

  @override
  Future<String> updateAvatar({required String imagePath}) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return avatarUrlToReturn ?? 'https://example.com/avatar.jpg';
  }

  @override
  Future<void> updateLanguage(String languageCode) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    lastLanguage = languageCode;
  }

  @override
  Future<UserModel> fetchUserProfile() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return userToReturn!;
  }

  @override
  Future<void> updateFcmToken(String fcmToken) async {
    lastFcmToken = fcmToken;
  }

  @override
  Future<String> resetPassword({required String nationalId}) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return resetPasswordMessage ?? 'تم إعادة التعيين';
  }
}

class FakeLocalDataSource implements AuthLocalDataSource {
  UserModel? cached;
  bool clearCalled = false;

  @override
  Future<UserModel> getCachedUser() async {
    if (cached == null) throw Exception('No cached user');
    return cached!;
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    cached = user;
  }

  @override
  Future<void> clearCache() async {
    cached = null;
    clearCalled = true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────

UserModel makeUser({
  String id = '1',
  String name = 'محمد العمري',
  String? nameEn = 'Mohammed',
  UserRole role = UserRole.driver,
  String token = 'tok_123',
  String? email = 'driver@test.com',
  String? phone = '0501234567',
  String? nationalId = '1234567890',
  int? busId = 42,
  String? schoolName = 'مدرسة النور',
}) {
  return UserModel(
    id: id,
    name: name,
    nameEn: nameEn,
    role: role,
    token: token,
    email: email,
    phone: phone,
    nationalId: nationalId,
    busId: busId,
    schoolName: schoolName,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── UserRole enum ──────────────────────────────────────────────────────────

  group('UserRole.fromString', () {
    test('1. "driver" → UserRole.driver', () => expect(UserRole.fromString('driver'), UserRole.driver));
    test('2. "assistant" → UserRole.assistant', () => expect(UserRole.fromString('assistant'), UserRole.assistant));
    test('3. "bus_assistant" → UserRole.assistant', () => expect(UserRole.fromString('bus_assistant'), UserRole.assistant));
    test('4. "field_supervisor" → UserRole.fieldSupervisor', () => expect(UserRole.fromString('field_supervisor'), UserRole.fieldSupervisor));
    test('5. "fieldsupervisor" → UserRole.fieldSupervisor', () => expect(UserRole.fromString('fieldsupervisor'), UserRole.fieldSupervisor));
    test('6. "teacher" → UserRole.teacher', () => expect(UserRole.fromString('teacher'), UserRole.teacher));
    test('7. unknown → fallback to driver', () => expect(UserRole.fromString('unknown_role'), UserRole.driver));
    test('8. case-insensitive "DRIVER"', () => expect(UserRole.fromString('DRIVER'), UserRole.driver));
  });

  // ── UserEntity ─────────────────────────────────────────────────────────────

  group('UserEntity', () {
    test('9. getLocalizedName returns Arabic by default', () {
      final u = makeUser(name: 'محمد', nameEn: 'Mohammed');
      expect(u.getLocalizedName('ar'), 'محمد');
    });
    test('10. getLocalizedName returns English when locale is en', () {
      final u = makeUser(name: 'محمد', nameEn: 'Mohammed');
      expect(u.getLocalizedName('en'), 'Mohammed');
    });
    test('11. getLocalizedName falls back to Arabic when nameEn is null', () {
      final u = makeUser(name: 'محمد', nameEn: null);
      expect(u.getLocalizedName('en'), 'محمد');
    });
    test('12. Equatable props produce equality', () {
      expect(makeUser(id: 'x'), equals(makeUser(id: 'x')));
      expect(makeUser(id: 'x'), isNot(equals(makeUser(id: 'y'))));
    });
    test('13. copyWith replaces only specified fields', () {
      final u = makeUser();
      final updated = u.copyWith(name: 'أحمد', role: UserRole.teacher);
      expect(updated.name, 'أحمد');
      expect(updated.role, UserRole.teacher);
      expect(updated.id, u.id);
    });
  });

  // ── UserModel ──────────────────────────────────────────────────────────────

  group('UserModel', () {
    test('14. fromJson constructs valid model', () {
      final json = {
        'id': '5',
        'name': 'سالم',
        'name_en': 'Salem',
        'role': 'teacher',
        'token': 'tok_abc',
        'avatar': 'https://example.com/img.png',
        'bus_id': '10',
        'email': 'salem@test.com',
        'phone': '0509876543',
        'national_id': '9876543210',
        'school_name': 'مدرسة الأمل',
        'bus': {'number': '42'},
      };
      final model = UserModel.fromJson(json);
      expect(model.id, '5');
      expect(model.name, 'سالم');
      expect(model.nameEn, 'Salem');
      expect(model.role, UserRole.teacher);
      expect(model.token, 'tok_abc');
      expect(model.busId, 10);
      expect(model.email, 'salem@test.com');
      expect(model.schoolName, 'مدرسة الأمل');
      expect(model.busDetails, {'number': '42'});
    });

    test('15. fromJson handles missing optional fields gracefully', () {
      final json = {'id': '1', 'name': 'خالد', 'role': 'driver', 'token': 't'};
      final model = UserModel.fromJson(json);
      expect(model.id, '1');
      expect(model.email, isNull);
      expect(model.busId, isNull);
      expect(model.busDetails, isNull);
    });

    test('16. fromJson handles null id by defaulting to empty string', () {
      final json = {'id': null, 'name': 'فيصل', 'role': 'driver', 'token': 't'};
      final model = UserModel.fromJson(json);
      expect(model.id, '');
    });

    test('17. fromJson handles integer bus_id', () {
      final json = {'id': '1', 'name': 'Ali', 'role': 'driver', 'token': 't', 'bus_id': 7};
      expect(UserModel.fromJson(json).busId, 7);
    });

    test('18. fromJson uses nameEn fallback key', () {
      final json = {'id': '1', 'name': 'Ali', 'nameEn': 'Ali En', 'role': 'driver', 'token': 't'};
      expect(UserModel.fromJson(json).nameEn, 'Ali En');
    });

    test('19. toJson round-trips correctly', () {
      final model = makeUser();
      final json = model.toJson();
      expect(json['id'], model.id);
      expect(json['role'], model.role.name);
      expect(json['token'], model.token);
      expect(json['bus_id'], model.busId);
    });

    test('20. copyWith updates token field', () {
      final model = makeUser(token: 'old');
      final updated = model.copyWith(token: 'new_tok');
      expect(updated.token, 'new_tok');
      expect(updated.name, model.name);
    });

    test('21. fromEntity constructs correct model', () {
      final entity = makeUser();
      final model = UserModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.role, entity.role);
    });
  });

  // ── AuthRepositoryImpl ─────────────────────────────────────────────────────

  group('AuthRepositoryImpl', () {
    late FakeRemoteDataSource remote;
    late FakeLocalDataSource local;
    late AuthRepositoryImpl repo;

    setUp(() {
      remote = FakeRemoteDataSource();
      local = FakeLocalDataSource();
      repo = AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);
    });

    test('22. login success returns Right(UserEntity) and caches user', () async {
      remote.userToReturn = makeUser();
      final result = await repo.login(id: '1234', password: 'pass');
      expect(result.isRight(), isTrue);
      expect(local.cached, isNotNull);
    });

    test('23. login failure returns Left(ServerFailure)', () async {
      remote.exceptionToThrow = Exception('Server error');
      final result = await repo.login(id: 'bad', password: 'bad');
      expect(result.isLeft(), isTrue);
      result.fold((l) => expect(l, isA<ServerFailure>()), (_) => fail('should be left'));
    });

    test('24. login invalid credentials returns Left(AuthFailure)', () async {
      remote.exceptionToThrow = Exception('Invalid credentials');
      final result = await repo.login(id: 'x', password: 'y');
      expect(result.isLeft(), isTrue);
      result.fold((l) => expect(l, isA<AuthFailure>()), (_) => fail('should be left'));
    });

    test('25. getCurrentUser returns cached user', () async {
      local.cached = makeUser();
      final result = await repo.getCurrentUser();
      expect(result.isRight(), isTrue);
    });

    test('26. getCurrentUser returns Left(CacheFailure) when no cache', () async {
      final result = await repo.getCurrentUser();
      expect(result.isLeft(), isTrue);
      result.fold((l) => expect(l, isA<CacheFailure>()), (_) => fail('should be left'));
    });

    test('27. logout clears cache and returns Right', () async {
      local.cached = makeUser(token: 'tok_for_logout');
      final result = await repo.logout();
      expect(result.isRight(), isTrue);
      expect(local.clearCalled, isTrue);
    });

    test('28. changePassword success returns Right', () async {
      final result = await repo.changePassword(currentPassword: 'old', newPassword: 'new', confirmPassword: 'new');
      expect(result.isRight(), isTrue);
    });

    test('29. changePassword failure returns Left(ServerFailure)', () async {
      remote.exceptionToThrow = Exception('Wrong password');
      final result = await repo.changePassword(currentPassword: 'x', newPassword: 'y', confirmPassword: 'y');
      result.fold((l) => expect(l, isA<ServerFailure>()), (_) => fail('should be left'));
    });

    test('30. resetPassword success returns Right', () async {
      final result = await repo.resetPassword(id: '1234');
      expect(result.isRight(), isTrue);
    });

    test('31. resetPassword failure returns Left(ServerFailure)', () async {
      remote.exceptionToThrow = Exception('User not found');
      final result = await repo.resetPassword(id: '9999');
      result.fold((l) => expect(l, isA<ServerFailure>()), (_) => fail('should be left'));
    });

    test('32. updateLanguage success returns Right', () async {
      final result = await repo.updateLanguage('ar');
      expect(result.isRight(), isTrue);
      expect(remote.lastLanguage, 'ar');
    });

    test('33. updateLanguage failure returns Left(ServerFailure)', () async {
      remote.exceptionToThrow = Exception('Network error');
      final result = await repo.updateLanguage('en');
      result.fold((l) => expect(l, isA<ServerFailure>()), (_) => fail('should be left'));
    });

    test('34. updateAvatar success caches updated avatar URL', () async {
      local.cached = makeUser();
      remote.avatarUrlToReturn = 'https://new.com/avatar.png';
      final result = await repo.updateAvatar('/path/to/img.jpg');
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (url) => expect(url, 'https://new.com/avatar.png'));
      expect(local.cached?.avatar, 'https://new.com/avatar.png');
    });

    test('35. updateProfile success caches updated phone and email', () async {
      local.cached = makeUser(phone: 'old_phone', email: 'old@email.com');
      final result = await repo.updateProfile(phone: '0509999999', email: 'new@email.com');
      expect(result.isRight(), isTrue);
      expect(local.cached?.phone, '0509999999');
      expect(local.cached?.email, 'new@email.com');
    });

    test('36. updateFcmToken success returns Right', () async {
      final result = await repo.updateFcmToken('fcm_xyz');
      expect(result.isRight(), isTrue);
      expect(remote.lastFcmToken, 'fcm_xyz');
    });

    test('37. refreshUserProfile merges token from cache with fresh profile', () async {
      local.cached = makeUser(token: 'cached_tok');
      remote.userToReturn = makeUser(token: ''); // server returns empty token
      final result = await repo.refreshUserProfile();
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (user) => expect(user.token, 'cached_tok'));
    });
  });
}
