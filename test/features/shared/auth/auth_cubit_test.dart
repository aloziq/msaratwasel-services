import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Domain & State Baseline Suite', () {
    test('1. UserRole.fromString maps roles with case-insensitivity and aliases correctly', () {
      expect(UserRole.fromString('driver'), UserRole.driver);
      expect(UserRole.fromString('DRIVER'), UserRole.driver);

      expect(UserRole.fromString('assistant'), UserRole.assistant);
      expect(UserRole.fromString('bus_assistant'), UserRole.assistant);
      expect(UserRole.fromString('BUS_ASSISTANT'), UserRole.assistant);

      expect(UserRole.fromString('field_supervisor'), UserRole.fieldSupervisor);
      expect(UserRole.fromString('fieldsupervisor'), UserRole.fieldSupervisor);

      expect(UserRole.fromString('teacher'), UserRole.teacher);

      // Unknown roles default safely to driver
      expect(UserRole.fromString('admin'), UserRole.driver);
      expect(UserRole.fromString(''), UserRole.driver);
    });

    test('2. UserEntity bilingual name resolution handles fallbacks correctly', () {
      const userWithBoth = UserEntity(
        id: '1',
        name: 'علي المعمري',
        nameEn: 'Ali Al-Maamari',
        role: UserRole.driver,
        token: 'token_123',
      );

      // In Arabic locale
      expect(userWithBoth.getLocalizedName('ar'), 'علي المعمري');
      // In English locale
      expect(userWithBoth.getLocalizedName('en'), 'Ali Al-Maamari');
      expect(userWithBoth.getLocalizedName('EN'), 'Ali Al-Maamari');

      const userWithoutEn = UserEntity(
        id: '2',
        name: 'سالم الشكيلي',
        nameEn: null,
        role: UserRole.assistant,
        token: 'token_456',
      );

      // When English name is absent, fall back to Arabic name
      expect(userWithoutEn.getLocalizedName('en'), 'سالم الشكيلي');
    });

    test('3. UserEntity copyWith and Equatable value equality', () {
      const u1 = UserEntity(
        id: '10',
        name: 'حمود',
        role: UserRole.driver,
        token: 'tok_1',
        busId: 5,
        phone: '98765432',
      );

      const u2 = UserEntity(
        id: '10',
        name: 'حمود',
        role: UserRole.driver,
        token: 'tok_1',
        busId: 5,
        phone: '98765432',
      );

      expect(u1, equals(u2));

      final updated = u1.copyWith(
        name: 'حمود الحارثي',
        avatar: 'https://example.com/avatar.jpg',
      );

      expect(updated.name, 'حمود الحارثي');
      expect(updated.avatar, 'https://example.com/avatar.jpg');
      expect(updated.id, '10');
      expect(updated.busId, 5);
      expect(updated.token, 'tok_1');
    });

    test('4. AuthState subclasses equality and prop verification', () {
      expect(AuthInitial(), isA<AuthState>());
      expect(AuthLoading(), isA<AuthState>());
      expect(AuthUnauthenticated(), isA<AuthState>());
      expect(AuthPasswordResetSent(), isA<AuthState>());

      const user = UserEntity(
        id: '1',
        name: 'خالد',
        role: UserRole.assistant,
        token: 'tok',
      );

      final stateAuth1 = const AuthAuthenticated(user);
      final stateAuth2 = const AuthAuthenticated(user);
      expect(stateAuth1, equals(stateAuth2));

      final err1 = const AuthError('كلمة المرور غير صحيحة');
      final err2 = const AuthError('كلمة المرور غير صحيحة');
      expect(err1, equals(err2));
      expect(err1.props, ['كلمة المرور غير صحيحة']);
    });
  });
}
