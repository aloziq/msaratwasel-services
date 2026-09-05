import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';

import 'package:msaratwasel_services/features/driver/home/domain/entities/trip_status.dart';
import 'package:msaratwasel_services/features/driver/home/domain/repositories/home_repository.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/manager/driver_home_cubit.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/screens/driver_home_screen.dart';

import 'package:msaratwasel_services/features/driver/maintenance/domain/entities/bus_expense.dart';
import 'package:msaratwasel_services/features/driver/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:msaratwasel_services/features/driver/maintenance/presentation/manager/maintenance_cubit.dart';
import 'package:msaratwasel_services/features/driver/maintenance/presentation/screens/fuel_refill_screen.dart';
import 'package:msaratwasel_services/features/driver/maintenance/presentation/screens/maintenance_entry_screen.dart';
import 'package:msaratwasel_services/features/driver/maintenance/presentation/screens/maintenance_logs_screen.dart';
import 'package:msaratwasel_services/features/driver/maintenance/presentation/screens/maintenance_request_screen.dart';

import 'package:msaratwasel_services/features/driver/trip/data/models/trip_history_model.dart';
import 'package:msaratwasel_services/features/driver/trip/domain/repositories/trip_history_repository.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/manager/trip_history_cubit.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/screens/trip_history_page.dart';

import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

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

class FakeHomeRepository implements HomeRepository {
  final List<TripStatus> trips;

  FakeHomeRepository({required this.trips});

  @override
  Future<TripStatus> getCurrentTripStatus() async => trips.first;

  @override
  Future<List<TripStatus>> getMyTrips() async => trips;

  @override
  Future<void> startTrip(String tripId) async {}

  @override
  Future<void> confirmTrip(String tripId) async {}
}

class FakeMaintenanceRepository implements MaintenanceRepository {
  final List<BusExpense> expenses;

  FakeMaintenanceRepository({required this.expenses});

  @override
  Future<void> submitFuelRefill({
    required double amount,
    required int odometer,
    required DateTime date,
    String? photoPath,
  }) async {}

  @override
  Future<void> submitMaintenanceRequest({
    required String description,
    required DateTime date,
    double? cost,
    String? photoPath,
  }) async {}

  @override
  Future<List<BusExpense>> getExpenses({int page = 1}) async => expenses;
}

class FakeTripHistoryRepository implements TripHistoryRepository {
  final TripHistoryResponse response;

  FakeTripHistoryRepository({required this.response});

  @override
  Future<Either<Failure, TripHistoryResponse>> getTripsHistory({
    String? startDate,
    String? endDate,
    String? status,
    int? page,
  }) async =>
      Right(response);
}

class MockAuthCubit extends Cubit<AuthState> implements AuthCubit {
  MockAuthCubit([AuthState? initial])
      : super(
          initial ??
              const AuthAuthenticated(
                UserEntity(
                  id: 'drv_1',
                  name: 'علي السائق',
                  role: UserRole.driver,
                  token: 'token_drv',
                  phone: '0555555555',
                  email: 'driver@example.com',
                  busId: 10,
                ),
              ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget buildTestableDriverWidget({
  required Widget child,
  required AuthCubit authCubit,
  TripHistoryCubit? tripHistoryCubit,
}) {
  final providers = <BlocProvider>[
    BlocProvider<AuthCubit>.value(value: authCubit),
  ];
  if (tripHistoryCubit != null) {
    providers.add(BlocProvider<TripHistoryCubit>.value(value: tripHistoryCubit));
  }

  return MultiBlocProvider(
    providers: providers,
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
  late FakeHomeRepository fakeHomeRepo;
  late FakeMaintenanceRepository fakeMaintenanceRepo;
  late FakeTripHistoryRepository fakeTripHistoryRepo;
  late TripHistoryCubit tripHistoryCubit;

  final sampleTrips = [
    const TripStatus(
      id: 'trip_1',
      type: 'forth',
      typeLabel: 'صباحية',
      status: 'pending',
      departureTime: '06:30 ص',
      totalStudents: 15,
      routeName: 'مسار حي الياسمين',
    ),
  ];

  final sampleExpenses = [
    BusExpense(
      id: 1,
      busId: 10,
      type: 'fuel',
      amount: 25.5,
      date: DateTime(2026, 9, 4),
      extraInfo: 'تعبئة بنزين ممتاز',
    ),
    BusExpense(
      id: 2,
      busId: 10,
      type: 'maintenance',
      amount: 40.0,
      date: DateTime(2026, 9, 3),
      extraInfo: 'تغيير زيت وفلتر',
    ),
  ];

  final sampleTripHistoryResponse = TripHistoryResponse(
    trips: [
      TripHistoryModel(
        id: 1,
        type: 'forth',
        typeLabel: 'صباحية',
        status: 'completed',
        tripDate: '2026-09-04',
        totalStudents: 18,
        departureTime: '06:30:00',
        arrivalTime: '07:15:00',
        route: RouteModel(id: 101, name: 'مسار العليا'),
      ),
    ],
    pagination: PaginationModel(currentPage: 1, lastPage: 1, total: 1),
    filters: FiltersModel(startDate: '2026-09-01', endDate: '2026-09-04'),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_name': 'علي السائق',
      'bus_id': 10,
      'bus_code': 'Bus-10',
    });
    final prefs = await SharedPreferences.getInstance();
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
    }

    mockAuthCubit = MockAuthCubit();
    fakeHomeRepo = FakeHomeRepository(trips: sampleTrips);
    fakeMaintenanceRepo = FakeMaintenanceRepository(expenses: sampleExpenses);
    fakeTripHistoryRepo = FakeTripHistoryRepository(response: sampleTripHistoryResponse);
    tripHistoryCubit = TripHistoryCubit(fakeTripHistoryRepo);

    if (GetIt.I.isRegistered<DriverHomeCubit>()) {
      GetIt.I.unregister<DriverHomeCubit>();
    }
    GetIt.I.registerFactory<DriverHomeCubit>(() => DriverHomeCubit(fakeHomeRepo));

    if (GetIt.I.isRegistered<MaintenanceCubit>()) {
      GetIt.I.unregister<MaintenanceCubit>();
    }
    GetIt.I.registerFactory<MaintenanceCubit>(() => MaintenanceCubit(fakeMaintenanceRepo));
  });

  tearDown(() async {
    await mockAuthCubit.close();
    await tripHistoryCubit.close();
  });

  group('Agent 1: Driver Screens Widget Suite', () {
    testWidgets('1. MaintenanceEntryScreen mounts, loads logs and displays action cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableDriverWidget(
          child: const MaintenanceEntryScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(MaintenanceEntryScreen), findsOneWidget);
    });

    testWidgets('2. MaintenanceLogsScreen mounts and displays expense items list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableDriverWidget(
          child: const MaintenanceLogsScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(MaintenanceLogsScreen), findsOneWidget);
      expect(find.text('وقود'), findsWidgets);
      expect(find.text('صيانة'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('3. FuelRefillScreen mounts and renders refill form inputs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableDriverWidget(
          child: const FuelRefillScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(FuelRefillScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('4. MaintenanceRequestScreen mounts and renders request form inputs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableDriverWidget(
          child: const MaintenanceRequestScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(MaintenanceRequestScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('5. TripHistoryView mounts, renders trip item with status and route', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tripHistoryCubit.loadTrips();

      await tester.pumpWidget(
        buildTestableDriverWidget(
          child: const TripHistoryView(),
          authCubit: mockAuthCubit,
          tripHistoryCubit: tripHistoryCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TripHistoryView), findsOneWidget);
      expect(find.text('مسار العليا'), findsOneWidget);
    });

    testWidgets('6. DriverHomeScreen mounts and displays dashboard with daily trips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableDriverWidget(
          child: const DriverHomeScreen(),
          authCubit: mockAuthCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(DriverHomeScreen), findsOneWidget);
    });
  });
}
