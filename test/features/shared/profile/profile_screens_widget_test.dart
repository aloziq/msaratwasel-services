import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/shared/profile/presentation/screens/change_password_screen.dart';
import 'package:msaratwasel_services/features/shared/profile/presentation/screens/profile_screen.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  bool changePasswordResult = true;
  String? lastCurrentPassword;
  String? lastNewPassword;
  String? lastConfirmPassword;

  FakeAuthCubit(super.initialState);

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    lastConfirmPassword = confirmPassword;
    return changePasswordResult;
  }

  @override
  Future<void> updateLanguage(String languageCode) async {}

  @override
  Future<void> updateAvatar(String photoPath) async {}

  @override
  Future<void> logout() async {
    emit(AuthUnauthenticated());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    required Widget child,
    required AuthCubit authCubit,
    Locale locale = const Locale('ar'),
  }) {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('ProfileScreen & ChangePasswordScreen UI Suite', () {
    testWidgets('1. ProfileScreen displays Driver user info and bus details', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const driverUser = UserEntity(
        id: '10',
        name: 'سالم الكندي',
        nameEn: 'Salim Al-Kindi',
        role: UserRole.driver,
        token: 'token_drv_10',
        phone: '96891234567',
        email: 'salim@msarat.om',
        nationalId: '10293847',
        busId: 42,
        busDetails: {
          'bus_number': 'BUS-42',
          'plate_number': '1234-A',
          'capacity': 30,
        },
      );

      final authCubit = FakeAuthCubit(const AuthAuthenticated(driverUser));

      await tester.pumpWidget(
        createTestWidget(
          child: const ProfileScreen(),
          authCubit: authCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('سالم الكندي'), findsOneWidget);
      expect(find.text('96891234567'), findsOneWidget);
      expect(find.text('salim@msarat.om'), findsOneWidget);
      expect(find.text('10293847'), findsOneWidget);
      expect(find.text('BUS-42'), findsOneWidget);
      expect(find.text('1234-A'), findsOneWidget);
      expect(find.textContaining('30'), findsWidgets);

      await authCubit.close();
    });

    testWidgets('2. ProfileScreen displays Teacher user info and school name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const teacherUser = UserEntity(
        id: '20',
        name: 'مريم الحارثية',
        role: UserRole.teacher,
        token: 'token_tea_20',
        phone: '96898765432',
        email: 'maryam@school.om',
        schoolName: 'مدرسة الأمل للتعليم الأساسي',
      );

      final authCubit = FakeAuthCubit(const AuthAuthenticated(teacherUser));

      await tester.pumpWidget(
        createTestWidget(
          child: const ProfileScreen(),
          authCubit: authCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('مريم الحارثية'), findsOneWidget);
      expect(find.text('مدرسة الأمل للتعليم الأساسي'), findsOneWidget);

      await authCubit.close();
    });

    testWidgets('3. ChangePasswordScreen validates inputs and submits successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const user = UserEntity(
        id: '1',
        name: 'مستخدم',
        role: UserRole.driver,
        token: 'tok',
      );

      final authCubit = FakeAuthCubit(const AuthAuthenticated(user));

      await tester.pumpWidget(
        createTestWidget(
          child: const ChangePasswordScreen(),
          authCubit: authCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));

      // 1. Submit empty form -> triggers validation errors
      final submitButton = find.byType(ElevatedButton);
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // 2. Fill current password and mismatching new passwords
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'oldPassword123');
      await tester.enterText(textFields.at(1), 'newSecret456');
      await tester.enterText(textFields.at(2), 'mismatchSecret789');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // 3. Fix confirmation password to match
      await tester.enterText(textFields.at(2), 'newSecret456');
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(authCubit.lastCurrentPassword, 'oldPassword123');
      expect(authCubit.lastNewPassword, 'newSecret456');
      expect(authCubit.lastConfirmPassword, 'newSecret456');

      await authCubit.close();
    });
  });
}
