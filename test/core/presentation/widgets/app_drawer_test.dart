import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_drawer.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
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

class FakeTeacherRepository implements TeacherRepository {
  List<ClassroomEntity> classrooms = [];
  bool shouldFail = false;

  @override
  Future<Either<String, List<ClassroomEntity>>> getTeacherClassrooms() async {
    if (shouldFail) return const Left('Error loading classrooms');
    return Right(classrooms);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthCubit fakeAuthCubit;
  late FakeTeacherRepository fakeTeacherRepo;
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    fakeAuthCubit = FakeAuthCubit();
    fakeTeacherRepo = FakeTeacherRepository();
    fakeTeacherRepo.classrooms = const [
      ClassroomEntity(
        id: 'c1',
        name: 'الصف الأول أ',
        nameEn: 'Grade 1A',
        grade: '1',
        studentCount: 20,
      ),
      ClassroomEntity(
        id: 'c2',
        name: 'الصف الثاني ب',
        nameEn: 'Grade 2B',
        grade: '2',
        studentCount: 22,
      ),
    ];

    if (GetIt.I.isRegistered<GetTeacherClassroomsUseCase>()) {
      GetIt.I.unregister<GetTeacherClassroomsUseCase>();
    }
    GetIt.I.registerSingleton<GetTeacherClassroomsUseCase>(
      GetTeacherClassroomsUseCase(fakeTeacherRepo),
    );
  });

  tearDown(() async {
    await fakeAuthCubit.close();
    await GetIt.I.reset();
  });

  Widget createTestWidget({required Widget child}) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    final router = GoRouter(
      initialLocation: AppRoutes.teacherHome,
      routes: [
        GoRoute(
          path: AppRoutes.teacherHome,
          builder: (context, state) => Scaffold(
            key: scaffoldKey,
            drawer: const AppDrawer(),
            body: Center(
              child: ElevatedButton(
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
                child: const Text('Open Drawer'),
              ),
            ),
          ),
        ),
      ],
    );

    return BlocProvider<AuthCubit>.value(
      value: fakeAuthCubit,
      child: MaterialApp.router(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('AppDrawer UI Widget Suite', () {
    testWidgets('1. Teacher role renders teacher menu items and expands classrooms', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const teacherUser = UserEntity(
        id: 'u_1',
        name: 'الأستاذة مريم',
        role: UserRole.teacher,
        token: 'token_teacher',
      );
      fakeAuthCubit.setAuthenticated(teacherUser);

      await tester.pumpWidget(createTestWidget(child: const AppDrawer()));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      // Check header info
      expect(find.text('الأستاذة مريم'), findsOneWidget);

      // Check teacher menu items using l10n
      expect(find.text(l10n.home), findsWidgets);
      expect(find.text(l10n.myStudents), findsOneWidget);
      expect(find.text(l10n.attendanceHistory), findsOneWidget);
      expect(find.text(l10n.reports), findsOneWidget);
      expect(find.text(l10n.settings), findsOneWidget);
      expect(find.text(l10n.logout), findsOneWidget);

      // Tap on myStudents to expand classroom list
      await tester.tap(find.text(l10n.myStudents));
      await tester.pumpAndSettle();

      // Verify classrooms appear
      expect(find.text('الصف الأول أ'), findsOneWidget);
      expect(find.text('الصف الثاني ب'), findsOneWidget);

      // Tap logout button
      await tester.tap(find.text(l10n.logout));
      await tester.pumpAndSettle();

      expect(fakeAuthCubit.logoutCalled, isTrue);
    });

    testWidgets('2. Assistant role renders assistant specific menu items', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const assistantUser = UserEntity(
        id: 'u_2',
        name: 'المشرفة فاطمة',
        role: UserRole.assistant,
        token: 'token_assistant',
      );
      fakeAuthCubit.setAuthenticated(assistantUser);

      await tester.pumpWidget(createTestWidget(child: const AppDrawer()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('المشرفة فاطمة'), findsOneWidget);
      expect(find.text(l10n.studentsList), findsOneWidget);
      expect(find.text(l10n.dailyChecklist), findsOneWidget);
      expect(find.text(l10n.incidentReportTitle), findsOneWidget);
      expect(find.text(l10n.busTracking), findsOneWidget);
      expect(find.text(l10n.chats), findsOneWidget);
    });

    testWidgets('3. Driver role renders driver specific menu items', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const driverUser = UserEntity(
        id: 'u_3',
        name: 'السائق ناصر',
        role: UserRole.driver,
        token: 'token_driver',
      );
      fakeAuthCubit.setAuthenticated(driverUser);

      await tester.pumpWidget(createTestWidget(child: const AppDrawer()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('السائق ناصر'), findsOneWidget);
      expect(find.text(l10n.navigation), findsOneWidget);
      expect(find.text(l10n.trips), findsOneWidget);
      expect(find.text(l10n.maintenance), findsOneWidget);
      expect(find.text(l10n.endTrip), findsOneWidget);
    });

    testWidgets('4. Field Supervisor role renders supervisor menu items', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const supervisorUser = UserEntity(
        id: 'u_4',
        name: 'المشرف الميداني أحمد',
        role: UserRole.fieldSupervisor,
        token: 'token_supervisor',
      );
      fakeAuthCubit.setAuthenticated(supervisorUser);

      await tester.pumpWidget(createTestWidget(child: const AppDrawer()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('المشرف الميداني أحمد'), findsOneWidget);
      expect(find.text(l10n.busTracking), findsOneWidget);
      expect(find.text(l10n.driversAndSupervisors), findsOneWidget);
      expect(find.text(l10n.incidentsAndEmergencies), findsOneWidget);
      expect(find.text(l10n.fieldInspection), findsOneWidget);
    });
  });
}
