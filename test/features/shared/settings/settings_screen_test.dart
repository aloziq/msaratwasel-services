import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/repositories/auth_repository.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/shared/settings/presentation/screens/contact_us_page.dart';
import 'package:msaratwasel_services/features/shared/settings/presentation/screens/privacy_policy_page.dart';
import 'package:msaratwasel_services/features/shared/settings/presentation/screens/settings_screen.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/repositories/teacher_repository.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  bool logoutCalled = false;

  FakeAuthCubit([AuthState? initial]) : super(initial ?? AuthInitial());

  void setAuthenticated(UserEntity user) {
    emit(AuthAuthenticated(user));
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    emit(AuthUnauthenticated());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, void>> updateLanguage(String language) async {
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTeacherRepository implements TeacherRepository {
  @override
  Future<Either<String, List<ClassroomEntity>>> getTeacherClassrooms() async {
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthCubit fakeAuthCubit;
  late ThemeController themeController;
  late SettingsController settingsController;
  late AppLocalizations l10n;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    if (!GetIt.I.isRegistered<AuthRepository>()) {
      GetIt.I.registerSingleton<AuthRepository>(FakeAuthRepository());
    }
    if (!GetIt.I.isRegistered<GetTeacherClassroomsUseCase>()) {
      GetIt.I.registerSingleton<GetTeacherClassroomsUseCase>(
        GetTeacherClassroomsUseCase(FakeTeacherRepository()),
      );
    }

    fakeAuthCubit = FakeAuthCubit();
    themeController = ThemeController();
    await themeController.load();

    settingsController = SettingsController();
    await settingsController.load();
  });

  tearDown(() async {
    await fakeAuthCubit.close();
    await GetIt.I.reset();
  });

  Widget buildSettingsWidget() {
    return ThemeProvider(
      controller: themeController,
      child: SettingsProvider(
        controller: settingsController,
        child: BlocProvider<AuthCubit>.value(
          value: fakeAuthCubit,
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
  }

  group('SettingsScreen & Subpages Suite', () {
    testWidgets('1. Mounts SettingsScreen, renders sections and toggles notifications', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const user = UserEntity(
        id: '1',
        name: 'أحمد الحارثي',
        role: UserRole.driver,
        token: 'token',
      );
      fakeAuthCubit.setAuthenticated(user);

      await tester.pumpWidget(buildSettingsWidget());
      await tester.pumpAndSettle();

      expect(find.text(l10n.settings), findsWidgets);
      expect(find.text(l10n.accountTitle), findsOneWidget);
      expect(find.text(l10n.appearance), findsOneWidget);
      expect(find.text(l10n.notifications), findsOneWidget);
      expect(find.text(l10n.support), findsOneWidget);

      // Toggle notification switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Theme toggle: switch to dark mode
      await themeController.setMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(themeController.mode, ThemeMode.dark);

      // Theme toggle: switch to light mode
      await themeController.setMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(themeController.mode, ThemeMode.light);

      // Logout button
      final logoutFinder = find.text(l10n.logout);
      expect(logoutFinder, findsWidgets);
      await tester.tap(logoutFinder.last);
      await tester.pumpAndSettle();

      expect(fakeAuthCubit.logoutCalled, isTrue);
    });

    testWidgets('2. ContactUsPage mounts, allows input and shows snackbar on submit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ContactUsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.contactUs), findsWidgets);

      // Enter complaint text
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'ملاحظة على مسار الحافلة رقم 5');
      await tester.pumpAndSettle();

      // Tap submit button
      final submitButton = find.text(l10n.submit);
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Check snackbar
      expect(find.text(l10n.complaintSent), findsOneWidget);
    });

    testWidgets('3. PrivacyPolicyPage renders sections correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PrivacyPolicyPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.privacyPolicy), findsWidgets);
      expect(find.text(l10n.privacyIntroTitle), findsOneWidget);
      expect(find.text(l10n.privacyDataCollectionTitle), findsOneWidget);
    });
  });
}
