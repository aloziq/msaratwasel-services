import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  int logoutCount = 0;

  _FakeAuthCubit([AuthState? state]) : super(state ?? AuthInitial());

  @override
  Future<void> logout() async {
    logoutCount++;
  }

  void emitState(AuthState state) => emit(state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthCubit authCubit;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    authCubit = _FakeAuthCubit();
  });

  tearDown(() {
    authCubit.close();
  });

  Widget buildWidget({
    int currentIndex = 0,
    ValueChanged<int>? onSelect,
    bool isDark = false,
    GoRouter? router,
  }) {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: '/test-screen',
          routes: [
            GoRoute(
              path: '/test-screen',
              builder: (context, state) => Scaffold(
                drawer: SupervisorDrawer(
                  currentIndex: currentIndex,
                  onSelect: onSelect ?? (_) {},
                ),
                body: Builder(
                  builder: (scaffoldContext) => ElevatedButton(
                    onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                    child: const Text('OpenDrawer'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const Scaffold(
                body: Text('ProfileScreen'),
              ),
            ),
          ],
        );

    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp.router(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: effectiveRouter,
      ),
    );
  }

  group('SupervisorDrawer Comprehensive Tests', () {
    testWidgets('1. Displays default supervisor role and opens drawer', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenDrawer'));
      await tester.pumpAndSettle();

      expect(find.byType(SupervisorDrawer), findsOneWidget);
      expect(find.text(l10n.fieldSupervisor), findsOneWidget);
      expect(find.text(l10n.supervisorRole), findsOneWidget);
      expect(find.byIcon(Icons.supervisor_account_rounded), findsOneWidget);
      expect(find.text(l10n.home), findsOneWidget);
      expect(find.text(l10n.busTracking), findsOneWidget);
      expect(find.text(l10n.driversAndSupervisors), findsOneWidget);
      expect(find.text(l10n.incidentsAndEmergencies), findsOneWidget);
      expect(find.text(l10n.fieldInspection), findsOneWidget);
      expect(find.text(l10n.registerDelays), findsOneWidget);
      expect(find.text(l10n.fieldTrips), findsOneWidget);
      expect(find.text(l10n.reports), findsOneWidget);
      expect(find.text(l10n.settings), findsOneWidget);
      expect(find.text(l10n.logout), findsOneWidget);
    });

    testWidgets('2. Displays authenticated user name', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final user = const UserEntity(
        id: 'usr_sup_1',
        name: 'سالم المعمري',
        nameEn: 'Salim Al-Maamari',
        email: 'salim@example.com',
        phone: '99887766',
        role: UserRole.fieldSupervisor,
        token: 'token_123',
        avatar: null,
      );
      authCubit.emitState(AuthAuthenticated(user));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenDrawer'));
      await tester.pumpAndSettle();

      expect(find.text('سالم المعمري'), findsOneWidget);
    });

    testWidgets('3. Tap avatar navigates to profile screen and closes drawer', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenDrawer'));
      await tester.pumpAndSettle();

      // Tap avatar
      await tester.tap(find.byIcon(Icons.supervisor_account_rounded));
      await tester.pumpAndSettle();

      expect(find.text('ProfileScreen'), findsOneWidget);
      expect(find.byType(SupervisorDrawer), findsNothing);
    });

    testWidgets('4. Tapping menu items triggers onSelect callback with correct indexes', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final selectedIndexes = <int>[];
      await tester.pumpWidget(buildWidget(
        currentIndex: 1,
        onSelect: (idx) => selectedIndexes.add(idx),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenDrawer'));
      await tester.pumpAndSettle();

      // Tap Home (index 0)
      await tester.tap(find.text(l10n.home));
      await tester.pump();
      expect(selectedIndexes, contains(0));

      // Tap Drivers & Supervisors (index 2)
      await tester.tap(find.text(l10n.driversAndSupervisors));
      await tester.pump();
      expect(selectedIndexes, contains(2));

      // Tap Field Inspection (index 5)
      await tester.tap(find.text(l10n.fieldInspection));
      await tester.pump();
      expect(selectedIndexes, contains(5));

      // Tap Settings (index 9)
      await tester.tap(find.text(l10n.settings));
      await tester.pump();
      expect(selectedIndexes, contains(9));
    });

    testWidgets('5. Logout button calls AuthCubit.logout and pops drawer', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenDrawer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.logout));
      await tester.pumpAndSettle();

      expect(authCubit.logoutCount, 1);
      expect(find.byType(SupervisorDrawer), findsNothing);
    });

    testWidgets('6. Renders in dark theme correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget(isDark: true, currentIndex: 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenDrawer'));
      await tester.pumpAndSettle();

      expect(find.byType(SupervisorDrawer), findsOneWidget);
      expect(find.text(l10n.fieldSupervisor), findsOneWidget);
    });
  });
}
