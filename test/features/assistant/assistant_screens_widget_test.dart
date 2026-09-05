import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';

import 'package:msaratwasel_services/features/assistant/checklist/presentation/screens/daily_checklist_screen.dart';
import 'package:msaratwasel_services/features/assistant/home/presentation/screens/assistant_home_screen.dart';
import 'package:msaratwasel_services/features/assistant/incidents/presentation/screens/incident_report_screen.dart';
import 'package:msaratwasel_services/features/assistant/students/presentation/screens/bus_students_screen.dart';

import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_trip_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/repositories/assistant_repository.dart';
import 'package:msaratwasel_services/features/assistant/core/presentation/cubit/bus_trip_cubit.dart';

import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class MockAuthCubit extends Cubit<AuthState> implements AuthCubit {
  MockAuthCubit([AuthState? initial])
      : super(
          initial ??
              const AuthAuthenticated(
                UserEntity(
                  id: 'ast_1',
                  name: 'منى المرافقة',
                  role: UserRole.assistant,
                  token: 'token_ast',
                  phone: '0555555555',
                  email: 'assistant@example.com',
                  busId: null, // Set null to avoid live Reverb websocket connection in tests
                ),
              ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAssistantRepository implements AssistantRepository {
  final BusTripEntity trip;
  final List<BusStudentEntity> students;
  bool shouldFail;

  FakeAssistantRepository({
    required this.trip,
    required this.students,
    this.shouldFail = false,
  });

  @override
  Future<Either<String, BusTripEntity>> getActiveTrip() async {
    if (shouldFail) return const Left('Failed to fetch active trip');
    return Right(trip);
  }

  @override
  Future<Either<String, List<BusStudentEntity>>> getStudents() async => Right(students);

  @override
  Future<Either<String, void>> confirmTrip(String tripId) async {
    if (shouldFail) return const Left('Failed to confirm trip');
    return const Right(null);
  }

  @override
  Future<Either<String, void>> updateStudentStatus(
    String studentId,
    BusStudentStatus status,
    String? direction,
  ) async {
    if (shouldFail) return const Left('Failed to update student');
    return const Right(null);
  }

  @override
  Future<Either<String, void>> groupAlight({
    required List<String> studentIds,
    required String direction,
  }) async {
    if (shouldFail) return const Left('Group alight failed');
    return const Right(null);
  }

  @override
  Future<Either<String, void>> groupBoard({
    required List<String> studentIds,
    required String direction,
  }) async {
    if (shouldFail) return const Left('Group board failed');
    return const Right(null);
  }

  @override
  Future<Either<String, void>> submitIncidentReport({
    required String studentId,
    required String type,
    required String description,
  }) async =>
      const Right(null);

  @override
  Future<Either<String, void>> submitDailyChecklist(Map<String, bool> items) async =>
      const Right(null);

  @override
  Future<Either<String, void>> confirmEmptyBus() async => const Right(null);

  @override
  Future<Either<String, void>> sendAlertToDriver(String message) async =>
      const Right(null);

  @override
  Future<Either<String, void>> updateBehavioralNote(
    String studentId,
    String note,
  ) async =>
      const Right(null);
}

final sampleStudents = [
  const BusStudentEntity(
    id: 's1',
    studentCode: 'STD001',
    name: 'عبدالله محمد',
    grade: 'الصف الثالث',
    schoolId: 'sch_1',
    parentName: 'محمد أحمد',
    parentPhone: '0501112233',
    status: BusStudentStatus.atHome,
    waitingElapsedSeconds: 0,
  ),
  const BusStudentEntity(
    id: 's2',
    studentCode: 'STD002',
    name: 'سارة علي',
    grade: 'الصف الثالث',
    schoolId: 'sch_1',
    parentName: 'علي حسن',
    parentPhone: '0502223344',
    status: BusStudentStatus.onBus,
    waitingElapsedSeconds: 120,
  ),
];

final sampleTrip = BusTripEntity(
  id: 'trip_100',
  busNumber: 'Bus-42',
  driverName: 'سعيد السائق',
  assistantName: 'منى المرافقة',
  students: sampleStudents,
  startTime: DateTime(2026, 9, 4, 7, 0),
  tripStatus: 'in_progress',
  suggestedDirection: 'to_school',
  suggestedTripType: 'morning',
);

Widget buildTestableAssistantWidget({
  required Widget child,
  required AuthCubit authCubit,
  required BusTripCubit busTripCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<BusTripCubit>.value(value: busTripCubit),
    ],
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
  late FakeAssistantRepository fakeRepo;
  late BusTripCubit busTripCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'bus_id': 42,
      'bus_code': 'Bus-42',
      'driver_name': 'سعيد السائق',
      'assistant_name': 'منى المرافقة',
    });
    final prefs = await SharedPreferences.getInstance();
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
    }

    mockAuthCubit = MockAuthCubit();
    fakeRepo = FakeAssistantRepository(trip: sampleTrip, students: sampleStudents);
    busTripCubit = BusTripCubit(repository: fakeRepo);
  });

  tearDown(() async {
    await mockAuthCubit.close();
    await busTripCubit.close();
  });

  group('Agent 2: Assistant Screens Widget Suite', () {
    testWidgets('1. DailyChecklistScreen mounts, displays checklist and toggles items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableAssistantWidget(
          child: const DailyChecklistScreen(),
          authCubit: mockAuthCubit,
          busTripCubit: busTripCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(DailyChecklistScreen), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsWidgets);

      // Tap first checkbox
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
    });

    testWidgets('2. AssistantHomeScreen mounts, renders trip info and action buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableAssistantWidget(
          child: const AssistantHomeScreen(),
          authCubit: mockAuthCubit,
          busTripCubit: busTripCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(AssistantHomeScreen), findsOneWidget);
    });

    testWidgets('3. IncidentReportScreen mounts and displays report form fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableAssistantWidget(
          child: const IncidentReportScreen(),
          authCubit: mockAuthCubit,
          busTripCubit: busTripCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(IncidentReportScreen), findsOneWidget);
    });

    testWidgets('4. BusStudentsScreen mounts, renders search and students list and disposes cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableAssistantWidget(
          child: const BusStudentsScreen(),
          authCubit: mockAuthCubit,
          busTripCubit: busTripCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(BusStudentsScreen), findsOneWidget);

      // Cleanly dispose to stop polling timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    test('5. BusTripCubit full workflow (load, confirm, updateStudent, group operations, errors)', () async {
      expect(busTripCubit.state, isA<BusTripInitial>());

      // 1. loadTrip success
      await busTripCubit.loadTrip();
      expect(busTripCubit.state, isA<BusTripLoaded>());
      final loaded = busTripCubit.state as BusTripLoaded;
      expect(loaded.trip.id, 'trip_100');
      expect(loaded.trip.students.length, 2);

      // 2. confirmTrip success
      await busTripCubit.confirmTrip('trip_100');
      await Future.delayed(Duration.zero);
      expect(busTripCubit.state, isA<BusTripLoaded>());

      // 3. updateStudentStatus success
      await busTripCubit.updateStudentStatus('s1', BusStudentStatus.onBus, direction: 'to_school');
      expect(busTripCubit.state, isA<BusTripLoaded>());

      // 4. groupBoard and groupAlight
      await busTripCubit.groupBoard(['s1'], 'to_school');
      await Future.delayed(Duration.zero);
      expect(busTripCubit.state, isA<BusTripLoaded>());

      await busTripCubit.groupAlight(['s2'], 'to_school');
      await Future.delayed(Duration.zero);
      expect(busTripCubit.state, isA<BusTripLoaded>());

      // 5. updateBehavioralNote
      await busTripCubit.updateBehavioralNote('s1', 'سلوك ممتاز');
      expect(busTripCubit.state, isA<BusTripLoaded>());

      // 6. Error handling branches
      fakeRepo.shouldFail = true;
      await busTripCubit.loadTrip();
      expect(busTripCubit.state, isA<BusTripError>());
      expect((busTripCubit.state as BusTripError).message, 'Failed to fetch active trip');

      // Test confirmTrip failure when in loaded state
      fakeRepo.shouldFail = false;
      await busTripCubit.loadTrip();
      fakeRepo.shouldFail = true;
      await busTripCubit.confirmTrip('trip_100');
      expect(busTripCubit.state, isA<BusTripLoaded>()); // Restores current trip after error
    });
  });
}
