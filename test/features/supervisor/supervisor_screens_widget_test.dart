import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/core/usecases/usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';

import 'package:msaratwasel_services/features/field_supervisor/home/presentation/screens/supervisor_home_screen.dart';
import 'package:msaratwasel_services/features/field_supervisor/incidents/presentation/screens/sos_alerts_screen.dart';
import 'package:msaratwasel_services/features/field_supervisor/delays/presentation/screens/delays_screen.dart';
import 'package:msaratwasel_services/features/field_supervisor/staff/presentation/screens/drivers_list_screen.dart';
import 'package:msaratwasel_services/features/field_supervisor/inspection/presentation/screens/field_inspection_screen.dart';
import 'package:msaratwasel_services/features/field_supervisor/field_trips/presentation/screens/field_trips_screen.dart';
import 'package:msaratwasel_services/features/field_supervisor/reports/presentation/screens/reports_screen.dart' as sup_reports;

import 'package:msaratwasel_services/features/field_supervisor/buses/domain/entities/fleet_bus.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/domain/repositories/fleet_repository.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/domain/usecases/get_fleet_buses_usecase.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/presentation/cubit/fleet_tracking_cubit.dart';

import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class MockAuthCubit extends Cubit<AuthState> implements AuthCubit {
  MockAuthCubit([AuthState? initial])
      : super(
          initial ??
              const AuthAuthenticated(
                UserEntity(
                  id: 'sup_1',
                  name: 'أحمد المشرف',
                  role: UserRole.fieldSupervisor,
                  token: 'token_sup',
                  phone: '0555555555',
                  email: 'supervisor@example.com',
                ),
              ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFleetRepository implements FleetRepository {
  final List<FleetBus> buses;
  final bool shouldFail;

  FakeFleetRepository({required this.buses, this.shouldFail = false});

  @override
  Future<Either<Failure, List<FleetBus>>> getFleetBuses() async {
    if (shouldFail) {
      return const Left(ServerFailure('Failed to load fleet'));
    }
    return Right(buses);
  }
}

Widget buildTestableSupervisorWidget({
  required Widget child,
  required AuthCubit authCubit,
}) {
  return BlocProvider<AuthCubit>.value(
    value: authCubit,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthCubit mockAuthCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_name': 'أحمد المشرف',
      'user_role': 'field_supervisor',
    });
    final prefs = await SharedPreferences.getInstance();
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
    }
    mockAuthCubit = MockAuthCubit();
  });

  tearDown(() async {
    await mockAuthCubit.close();
  });

  group('Agent 3: Field Supervisor Screens Widget Suite', () {
    testWidgets('1. SupervisorHomeScreen mounts, renders dashboard title and stats', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableSupervisorWidget(
          child: const SupervisorHomeScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(SupervisorHomeScreen), findsOneWidget);
    });

    testWidgets('2. SosAlertsScreen mounts and displays incidents interface', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableSupervisorWidget(
          child: const SosAlertsScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(SosAlertsScreen), findsOneWidget);
    });

    testWidgets('3. DelaysScreen mounts and displays tabs for student and bus delays', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableSupervisorWidget(
          child: const DelaysScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(DelaysScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('4. DriversListScreen mounts and displays staff tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableSupervisorWidget(
          child: const DriversListScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(DriversListScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('5. FieldInspectionScreen mounts and displays inspection view', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableSupervisorWidget(
          child: const FieldInspectionScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(FieldInspectionScreen), findsOneWidget);
    });

    testWidgets('6. FieldTripsScreen mounts and renders trips management view', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableSupervisorWidget(
          child: const FieldTripsScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(FieldTripsScreen), findsOneWidget);
    });

    testWidgets('7. Supervisor ReportsScreen mounts and displays dashboard reports', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableSupervisorWidget(
          child: const sup_reports.ReportsScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(sup_reports.ReportsScreen), findsOneWidget);
    });

    test('8. FleetTrackingCubit state transitions, selection and error handling', () async {
      final sampleBuses = [
        FleetBus(
          id: 'bus_1',
          name: '101',
          driverName: 'سالم',
          supervisorName: 'فاطمة',
          schoolName: 'مدرسة الأمل',
          driverPhone: '0551111111',
          route: 'المسار 1',
          lat: 24.7136,
          lng: 46.6753,
          speedKmh: 45.0,
          studentsOnBoard: 15,
          status: FleetBusStatus.active,
          updatedAt: DateTime(2026, 9, 4),
        ),
        FleetBus(
          id: 'bus_2',
          name: '102',
          driverName: 'خالد',
          supervisorName: 'مريم',
          schoolName: 'مدرسة الأمل',
          driverPhone: '0552222222',
          route: 'المسار 2',
          lat: 24.7200,
          lng: 46.6800,
          speedKmh: 0.0,
          studentsOnBoard: 0,
          status: FleetBusStatus.stopped,
          updatedAt: DateTime(2026, 9, 4),
        ),
        FleetBus(
          id: 'bus_3',
          name: '103',
          driverName: 'فهد',
          supervisorName: 'نورة',
          schoolName: 'مدرسة الأمل',
          driverPhone: '0553333333',
          route: 'المسار 3',
          lat: 24.7300,
          lng: 46.6900,
          speedKmh: 0.0,
          studentsOnBoard: 0,
          status: FleetBusStatus.maintenance,
          updatedAt: DateTime(2026, 9, 4),
        ),
      ];

      final successRepo = FakeFleetRepository(buses: sampleBuses);
      final cubit = FleetTrackingCubit(GetFleetBusesUseCase(successRepo));

      expect(cubit.state, isA<FleetTrackingInitial>());

      await cubit.loadFleet();
      expect(cubit.state, isA<FleetTrackingLoaded>());
      final loaded = cubit.state as FleetTrackingLoaded;
      expect(loaded.buses.length, 3);
      expect(loaded.activeCount, 1);
      expect(loaded.stoppedCount, 1);
      expect(loaded.maintenanceCount, 1);
      expect(loaded.selectedBus, isNull);

      cubit.selectBus('bus_1');
      final selected = cubit.state as FleetTrackingLoaded;
      expect(selected.selectedBusId, 'bus_1');
      expect(selected.selectedBus?.driverName, 'سالم');

      cubit.clearSelection();
      final cleared = cubit.state as FleetTrackingLoaded;
      expect(cleared.selectedBusId, isNull);

      await cubit.close();

      // Test error branch
      final failRepo = FakeFleetRepository(buses: [], shouldFail: true);
      final failCubit = FleetTrackingCubit(GetFleetBusesUseCase(failRepo));
      await failCubit.loadFleet();
      expect(failCubit.state, isA<FleetTrackingError>());
      expect((failCubit.state as FleetTrackingError).message, 'Failed to load fleet');
      await failCubit.close();
    });
  });
}
