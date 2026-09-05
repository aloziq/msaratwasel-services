import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/features/driver/trip/domain/repositories/trip_repository.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/manager/end_trip_cubit.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/screens/end_trip_screen.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';

class MockBackgroundServicePlatform extends FlutterBackgroundServicePlatform {
  @override
  Future<bool> configure({
    required IosConfiguration iosConfiguration,
    required AndroidConfiguration androidConfiguration,
  }) async =>
      true;

  @override
  Future<bool> start() async => true;

  @override
  Future<bool> isServiceRunning() async => false;

  @override
  void invoke(String method, [Map<String, dynamic>? args]) {}

  @override
  Stream<Map<String, dynamic>?> on(String method) => const Stream.empty();
}

class _FakeTripRepository implements TripRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit([AuthState? initial])
      : super(
          initial ??
              const AuthAuthenticated(
                UserEntity(
                  id: 'drv_1',
                  name: 'علي السائق',
                  role: UserRole.driver,
                  token: 'token_drv',
                ),
              ),
        );

  void emitState(AuthState state) => emit(state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeController themeController;
  late SettingsController settingsController;
  late _FakeAuthCubit authCubit;
  late EndTripCubit endTripCubit;

  setUp(() async {
    FlutterBackgroundServicePlatform.instance = MockBackgroundServicePlatform();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
    }

    themeController = ThemeController();
    await themeController.load();
    settingsController = SettingsController();
    await settingsController.load();

    authCubit = _FakeAuthCubit();
    endTripCubit = EndTripCubit(_FakeTripRepository());

    if (GetIt.I.isRegistered<EndTripCubit>()) {
      GetIt.I.unregister<EndTripCubit>();
    }
    GetIt.I.registerFactory<EndTripCubit>(() => endTripCubit);
  });

  tearDown(() {
    if (GetIt.I.isRegistered<EndTripCubit>()) {
      GetIt.I.unregister<EndTripCubit>();
    }
    authCubit.close();
    endTripCubit.close();
  });

  Widget buildTestApp({GoRouter? router}) {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: AppRoutes.driverEndTrip,
          routes: [
            GoRoute(
              path: AppRoutes.driverEndTrip,
              builder: (context, state) => const EndTripScreen(),
            ),
            GoRoute(
              path: AppRoutes.driverHome,
              builder: (context, state) => const Scaffold(body: Text('DriverHomeLanding')),
            ),
            GoRoute(
              path: AppRoutes.assistantHome,
              builder: (context, state) => const Scaffold(body: Text('AssistantHomeLanding')),
            ),
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(body: Text('RootLanding')),
            ),
          ],
        );

    return ThemeProvider(
      controller: themeController,
      child: SettingsProvider(
        controller: settingsController,
        child: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            routerConfig: effectiveRouter,
          ),
        ),
      ),
    );
  }

  group('EndTripScreen Widget Tests', () {
    testWidgets('1. Mounts EndTripScreen and displays camera placeholder / indicator', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.byType(CameraAwesomeBuilder), findsOneWidget);
      expect(find.byType(EndTripScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('2. Listener responds to EndTripError state and displays error snackbar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      endTripCubit.emit(const EndTripError('فشل التحقق من باركود الحافلة'));
      await tester.pump();

      expect(find.text('فشل التحقق من باركود الحافلة'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Driver success triggers success message and navigates to driverHome', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      endTripCubit.emit(EndTripSuccess());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('تمت الرحلة بنجاح. تم حفظ وتوثيق حالة الحافلة خالية.'), findsOneWidget);
      expect(find.text('DriverHomeLanding'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('4. Assistant success triggers success message and navigates to assistantHome', (tester) async {
      authCubit.emitState(
        const AuthAuthenticated(
          UserEntity(
            id: 'asst_1',
            name: 'فاطمة المساعدة',
            role: UserRole.assistant,
            token: 'tok_asst',
          ),
        ),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      endTripCubit.emit(EndTripSuccess());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('AssistantHomeLanding'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('5. Unauthenticated user on success navigates to root /', (tester) async {
      authCubit.emitState(AuthUnauthenticated());

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      endTripCubit.emit(EndTripSuccess());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('RootLanding'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
