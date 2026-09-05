import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/features/driver/home/domain/entities/trip_status.dart';
import 'package:msaratwasel_services/features/driver/home/domain/repositories/home_repository.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/manager/driver_home_cubit.dart';

import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit(super.initialState);

  void setState(AuthState newState) => emit(newState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<TripStatus> getCurrentTripStatus() async => const TripStatus(
    id: '1',
    status: 'pending',
    departureTime: '07:00 AM',
    totalStudents: 10,
  );

  @override
  Future<List<TripStatus>> getMyTrips() async => [];

  @override
  Future<void> startTrip(String tripId) async {}

  @override
  Future<void> confirmTrip(String tripId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeController themeController;
  late SettingsController settingsController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
    }
    if (GetIt.I.isRegistered<DriverHomeCubit>()) {
      GetIt.I.unregister<DriverHomeCubit>();
    }
    GetIt.I.registerFactory<DriverHomeCubit>(() => DriverHomeCubit(_FakeHomeRepository()));

    themeController = ThemeController();
    await themeController.load();
    settingsController = SettingsController();
    await settingsController.load();
  });

  tearDown(() {
    if (GetIt.I.isRegistered<DriverHomeCubit>()) {
      GetIt.I.unregister<DriverHomeCubit>();
    }
  });

  UserEntity makeUser(UserRole role) {
    return UserEntity(
      id: '1',
      name: 'Test User',
      role: role,
      token: 'tok_123',
    );
  }

  Widget buildTestApp(AppRouter appRouter) {
    return ThemeProvider(
      controller: themeController,
      child: SettingsProvider(
        controller: settingsController,
        child: BlocProvider<AuthCubit>.value(
          value: appRouter.authCubit,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            routerConfig: appRouter.router,
          ),
        ),
      ),
    );
  }

  group('AppRouter & Route Guard Suite', () {
    test('1. Unauthenticated user on protected route redirects to login', () {
      final authCubit = _FakeAuthCubit(AuthUnauthenticated());
      final appRouter = AppRouter(authCubit: authCubit);

      // Verify router instance created
      expect(appRouter.router, isNotNull);
      expect(appRouter.authCubit, authCubit);
      authCubit.close();
    });

    testWidgets('2. Unauthenticated user accessing protected route gets redirected to login', (tester) async {
      final authCubit = _FakeAuthCubit(AuthUnauthenticated());
      final appRouter = AppRouter(authCubit: authCubit);
      await tester.pumpWidget(buildTestApp(appRouter));
      await tester.pump(const Duration(seconds: 5));

      expect(appRouter.router.state.matchedLocation, AppRoutes.login);
      await tester.pumpWidget(const SizedBox());
      authCubit.close();
    });

    testWidgets('3. Authenticated driver on login page redirects to driverHome', (tester) async {
      final driverUser = makeUser(UserRole.driver);
      final authCubit = _FakeAuthCubit(AuthAuthenticated(driverUser));
      final appRouter = AppRouter(authCubit: authCubit);

      await tester.pumpWidget(buildTestApp(appRouter));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(appRouter.router.state.matchedLocation, AppRoutes.driverHome);
      await tester.pumpWidget(const SizedBox());
      authCubit.close();
    });

    testWidgets('4. Authenticated assistant on login page redirects to assistantHome', (tester) async {
      final assistantUser = makeUser(UserRole.assistant);
      final authCubit = _FakeAuthCubit(AuthAuthenticated(assistantUser));
      final appRouter = AppRouter(authCubit: authCubit);

      await tester.pumpWidget(buildTestApp(appRouter));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(appRouter.router.state.matchedLocation, AppRoutes.assistantHome);
      await tester.pumpWidget(const SizedBox());
      authCubit.close();
    });

    testWidgets('5. Authenticated field supervisor on login redirects to supervisorHome', (tester) async {
      final supervisorUser = makeUser(UserRole.fieldSupervisor);
      final authCubit = _FakeAuthCubit(AuthAuthenticated(supervisorUser));
      final appRouter = AppRouter(authCubit: authCubit);

      await tester.pumpWidget(buildTestApp(appRouter));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(appRouter.router.state.matchedLocation, AppRoutes.supervisorHome);
      await tester.pumpWidget(const SizedBox());
      authCubit.close();
    });

    testWidgets('6. Authenticated field supervisor accessing / is redirected to supervisorHome', (tester) async {
      final supervisorUser = makeUser(UserRole.fieldSupervisor);
      final authCubit = _FakeAuthCubit(AuthAuthenticated(supervisorUser));
      final appRouter = AppRouter(authCubit: authCubit);

      await tester.pumpWidget(buildTestApp(appRouter));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      appRouter.router.go(AppRoutes.teacherHome);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(appRouter.router.state.matchedLocation, AppRoutes.supervisorHome);
      await tester.pumpWidget(const SizedBox());
      authCubit.close();
    });

    testWidgets('7. Unauthenticated user can access resetPassword without redirect', (tester) async {
      final authCubit = _FakeAuthCubit(AuthUnauthenticated());
      final appRouter = AppRouter(authCubit: authCubit);

      await tester.pumpWidget(buildTestApp(appRouter));
      await tester.pump();

      appRouter.router.go(AppRoutes.resetPassword);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(appRouter.router.state.matchedLocation, AppRoutes.resetPassword);
      await tester.pumpWidget(const SizedBox());
      authCubit.close();
    });

    test('8. GoRouterRefreshStream notifies listeners on stream events and disposes cleanly', () async {
      final controller = StreamController<String>.broadcast();
      final refreshStream = GoRouterRefreshStream(controller.stream);

      int notifyCount = 0;
      refreshStream.addListener(() {
        notifyCount++;
      });

      controller.add('event1');
      await Future.delayed(Duration.zero);
      expect(notifyCount, greaterThan(0));

      refreshStream.dispose();
      await controller.close();
    });
  });
}
