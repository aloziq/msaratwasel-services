import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';

void main() {
  testWidgets('handleSupervisorNavigation routes correctly for all indices', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.supervisorHome,
      routes: [
        GoRoute(
          path: AppRoutes.supervisorHome,
          builder: (context, state) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'buses',
              builder: (context, state) => const Scaffold(body: Text('Buses')),
            ),
            GoRoute(
              path: 'drivers',
              builder: (context, state) => const Scaffold(body: Text('Drivers')),
            ),
            GoRoute(
              path: 'alerts',
              builder: (context, state) => const Scaffold(body: Text('Alerts')),
            ),
            GoRoute(
              path: 'inspection',
              builder: (context, state) => const Scaffold(body: Text('Inspection')),
            ),
            GoRoute(
              path: 'delays',
              builder: (context, state) => const Scaffold(body: Text('Delays')),
            ),
            GoRoute(
              path: 'trips',
              builder: (context, state) => const Scaffold(body: Text('Trips')),
            ),
            GoRoute(
              path: 'reports',
              builder: (context, state) => const Scaffold(body: Text('Reports')),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    BuildContext currentContext() => tester.element(find.byType(Scaffold).last);

    // 1. Same index -> does not navigate
    handleSupervisorNavigation(currentContext(), 0, 0, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    // 2. Index 1 -> /supervisor/buses
    handleSupervisorNavigation(currentContext(), 1, 0, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Buses'), findsOneWidget);

    // 3. Index 2 -> /supervisor/drivers
    handleSupervisorNavigation(currentContext(), 2, 1, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Drivers'), findsOneWidget);

    // 4. Index 4 -> /supervisor/alerts
    handleSupervisorNavigation(currentContext(), 4, 2, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Alerts'), findsOneWidget);

    // 5. Index 5 -> /supervisor/inspection
    handleSupervisorNavigation(currentContext(), 5, 4, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Inspection'), findsOneWidget);

    // 6. Index 6 -> /supervisor/delays
    handleSupervisorNavigation(currentContext(), 6, 5, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Delays'), findsOneWidget);

    // 7. Index 7 -> /supervisor/trips
    handleSupervisorNavigation(currentContext(), 7, 6, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Trips'), findsOneWidget);

    // 8. Index 8 -> /supervisor/reports
    handleSupervisorNavigation(currentContext(), 8, 7, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Reports'), findsOneWidget);

    // 9. Index 9 -> /settings
    handleSupervisorNavigation(currentContext(), 9, 8, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    // 10. Index 10 -> logout / no-op
    handleSupervisorNavigation(currentContext(), 10, 9, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    // 11. Default index 99 -> /supervisor
    handleSupervisorNavigation(currentContext(), 99, 9, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    // 12. Index 0 -> /supervisor
    handleSupervisorNavigation(currentContext(), 0, 99, closeDrawer: false);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('handleSupervisorNavigation closes drawer when closeDrawer is true', (tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    final router = GoRouter(
      initialLocation: AppRoutes.supervisorHome,
      routes: [
        GoRoute(
          path: AppRoutes.supervisorHome,
          builder: (context, state) => Scaffold(
            key: scaffoldKey,
            drawer: Drawer(
              child: Builder(
                builder: (drawerContext) => TextButton(
                  onPressed: () {
                    handleSupervisorNavigation(drawerContext, 1, 0, closeDrawer: true);
                  },
                  child: const Text('Go to Buses'),
                ),
              ),
            ),
            body: const Text('Home Body'),
          ),
          routes: [
            GoRoute(
              path: 'buses',
              builder: (context, state) => const Scaffold(body: Text('Buses Body')),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Open drawer
    scaffoldKey.currentState?.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Go to Buses'), findsOneWidget);

    // Tap the button which calls handleSupervisorNavigation with closeDrawer: true
    await tester.tap(find.text('Go to Buses'));
    await tester.pumpAndSettle();

    expect(find.text('Buses Body'), findsOneWidget);
    expect(find.text('Go to Buses'), findsNothing); // Drawer closed
  });
}
