import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_text_field.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/repositories/auth_repository.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/screens/login_screen.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/core/error/failure.dart';

class FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  String? lastLoginId;
  String? lastLoginPassword;
  UserRole? lastLoginRole;
  int loginCallCount = 0;

  FakeAuthCubit([AuthState? initialState]) : super(initialState ?? AuthInitial());

  @override
  Future<void> login({
    required String id,
    required String password,
    required UserRole selectedRole,
  }) async {
    loginCallCount++;
    lastLoginId = id;
    lastLoginPassword = password;
    lastLoginRole = selectedRole;
  }

  @override
  Future<void> refreshUserProfile() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  String? lastLanguageCode;

  @override
  Future<Either<Failure, void>> updateLanguage(String languageCode) async {
    lastLanguageCode = languageCode;
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeController themeController;
  late SettingsController settingsController;
  late FakeAuthCubit authCubit;
  late FakeAuthRepository authRepository;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.unregister<SharedPreferences>();
    }
    GetIt.I.registerSingleton<SharedPreferences>(prefs);

    authRepository = FakeAuthRepository();
    if (GetIt.I.isRegistered<AuthRepository>()) {
      GetIt.I.unregister<AuthRepository>();
    }
    GetIt.I.registerSingleton<AuthRepository>(authRepository);

    authCubit = FakeAuthCubit();
    if (GetIt.I.isRegistered<AuthCubit>()) {
      GetIt.I.unregister<AuthCubit>();
    }
    GetIt.I.registerSingleton<AuthCubit>(authCubit);

    themeController = ThemeController();
    await themeController.load();

    settingsController = SettingsController();
    await settingsController.load();
  });

  tearDown(() {
    authCubit.close();
    if (GetIt.I.isRegistered<AuthCubit>()) {
      GetIt.I.unregister<AuthCubit>();
    }
    if (GetIt.I.isRegistered<AuthRepository>()) {
      GetIt.I.unregister<AuthRepository>();
    }
    if (GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.unregister<SharedPreferences>();
    }
  });

  Widget buildTestWidget({
    GoRouter? router,
    Locale locale = const Locale('ar'),
  }) {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: AppRoutes.login,
          routes: [
            GoRoute(
              path: AppRoutes.login,
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: AppRoutes.resetPassword,
              builder: (context, state) => const Scaffold(
                body: Text('ResetPasswordDestination'),
              ),
            ),
          ],
        );

    return ThemeProvider(
      controller: themeController,
      child: SettingsProvider(
        controller: settingsController,
        child: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: AnimatedBuilder(
            animation: Listenable.merge([themeController, settingsController]),
            builder: (context, _) => MaterialApp.router(
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: themeController.mode,
              locale: settingsController.locale ?? locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: effectiveRouter,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester, {GoRouter? router, Locale locale = const Locale('ar')}) async {
    await tester.pumpWidget(buildTestWidget(router: router, locale: locale));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('1. Initial render displays all essential UI elements and driver role selected', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(l10n.appTitle), findsOneWidget);
      expect(find.text(l10n.welcomeBack), findsOneWidget);
      expect(find.text(l10n.driverLogin), findsOneWidget);

      // Verify role options rendered
      expect(find.text(l10n.roleDriver), findsOneWidget);
      expect(find.text(l10n.roleBusAssistant), findsOneWidget);
      expect(find.text(l10n.roleFieldSupervisor), findsOneWidget);
      expect(find.text(l10n.roleTeacher), findsOneWidget);

      // Verify input fields & action buttons
      expect(find.byType(PremiumTextField), findsNWidgets(2));
      expect(find.text(l10n.civilId), findsOneWidget);
      expect(find.text(l10n.password), findsOneWidget);
      expect(find.text(l10n.forgotPassword), findsOneWidget);
      expect(find.byType(PremiumButton), findsOneWidget);
      expect(find.text(l10n.login), findsOneWidget);

      // Top control icons (sun/moon and globe)
      expect(find.byIcon(PhosphorIconsRegular.globe), findsOneWidget);
    });

    testWidgets('2. Role selection toggles correctly between all roles and updates subtitle', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Initial: Driver
      expect(find.text(l10n.driverLogin), findsOneWidget);

      // Switch to Assistant
      await tester.tap(find.text(l10n.roleBusAssistant));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n.assistantLogin), findsOneWidget);

      // Switch to Field Supervisor
      await tester.tap(find.text(l10n.roleFieldSupervisor));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n.supervisorLogin), findsOneWidget);

      // Switch to Teacher
      await tester.tap(find.text(l10n.roleTeacher));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n.teacherLogin), findsOneWidget);

      // Switch back to Driver
      await tester.tap(find.text(l10n.roleDriver));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n.driverLogin), findsOneWidget);
    });

    testWidgets('3. Form validation triggers error messages when submitting empty inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Tap Login button while fields are empty
      await tester.tap(find.byType(PremiumButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l10n.pleaseEnterCivilId), findsOneWidget);
      expect(find.text(l10n.pleaseEnterPassword), findsOneWidget);
      expect(authCubit.loginCallCount, 0);

      // Fill in Civil ID only
      await tester.enterText(find.byType(TextField).first, '12345678');
      await tester.tap(find.byType(PremiumButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l10n.pleaseEnterCivilId), findsNothing);
      expect(find.text(l10n.pleaseEnterPassword), findsOneWidget);
      expect(authCubit.loginCallCount, 0);
    });

    testWidgets('4. Submitting valid form triggers authCubit.login with correct arguments', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Select Assistant role
      await tester.tap(find.text(l10n.roleBusAssistant));
      await tester.pump(const Duration(milliseconds: 300));

      // Enter civil ID and password
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '98765432');
      await tester.enterText(textFields.at(1), 'SecretPass123');
      await tester.pump();

      // Tap login
      await tester.tap(find.byType(PremiumButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(authCubit.loginCallCount, 1);
      expect(authCubit.lastLoginId, '98765432');
      expect(authCubit.lastLoginPassword, 'SecretPass123');
      expect(authCubit.lastLoginRole, UserRole.assistant);
    });

    testWidgets('5. Loading state disables button and renders loading indicator', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      authCubit.emit(AuthLoading());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final premiumButton = tester.widget<PremiumButton>(find.byType(PremiumButton));
      expect(premiumButton.isLoading, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('6. AuthError state displays SnackBar with error message', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Emit AuthError
      const errorMsg = 'الرقم المدني أو كلمة المرور غير صحيحة';
      authCubit.emit(const AuthError(errorMsg));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(errorMsg), findsOneWidget);
    });

    testWidgets('7. Forgot password button navigates to reset password screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text(l10n.forgotPassword));
      await tester.pumpAndSettle();

      expect(find.text('ResetPasswordDestination'), findsOneWidget);
    });

    testWidgets('8. Top controls toggle theme and language properly', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      // Theme toggle: initially light or system -> tap to toggle to dark
      final themeBtn = find.byIcon(PhosphorIconsRegular.moon);
      expect(themeBtn, findsOneWidget);
      await tester.tap(themeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(themeController.mode, ThemeMode.dark);

      // Now in dark mode, icon changes to sun -> tap to toggle back to light
      final sunBtn = find.byIcon(PhosphorIconsRegular.sun);
      expect(sunBtn, findsOneWidget);
      await tester.tap(sunBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(themeController.mode, ThemeMode.light);

      // Language toggle: tap globe icon to change from Arabic to English
      final langBtn = find.byIcon(PhosphorIconsRegular.globe);
      expect(langBtn, findsOneWidget);
      await tester.tap(langBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(settingsController.locale?.languageCode, 'en');

      // Tap globe again to toggle back to Arabic
      await tester.tap(langBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(settingsController.locale?.languageCode, 'ar');
    });

    testWidgets('9. Tapping outside fields dismisses keyboard (unfocuses)', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Focus first textfield
      await tester.tap(find.byType(TextField).first);
      await tester.pump();

      // Tap background
      await tester.tapAt(const Offset(50, 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
