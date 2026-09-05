import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/entities/report_entity.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/cubit/reports_cubit.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/cubit/reports_state.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';
import 'package:msaratwasel_services/features/teacher/teacher/presentation/cubit/teacher_cubit.dart';
import 'package:msaratwasel_services/features/teacher/teacher/presentation/cubit/teacher_state.dart';
import 'package:msaratwasel_services/features/teacher/teacher/presentation/screens/teacher_home_screen.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse implements HttpClientResponse {
  static final _transparentImage = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
    0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
    0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ]);

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit([AuthState? initial])
      : super(
          initial ??
              const AuthAuthenticated(
                UserEntity(
                  id: 'tch_10',
                  name: 'أحمد الريامي',
                  nameEn: 'Ahmed Al-Riyami',
                  role: UserRole.teacher,
                  token: 'tok_tch_10',
                  avatar: 'https://example.com/avatar.png',
                ),
              ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTeacherCubit extends Cubit<TeacherState> implements TeacherCubit {
  int loadClassroomCount = 0;

  _FakeTeacherCubit([TeacherState? initial])
      : super(
          initial ??
              const TeacherClassLoaded(
                ClassroomEntity(
                  id: 'class_grade_4a',
                  name: 'الصف الرابع أ',
                  grade: '4',
                  studentCount: 25,
                ),
              ),
        );

  @override
  Future<void> loadClassroom() async {
    loadClassroomCount++;
  }

  void emitState(TeacherState newState) => emit(newState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReportsCubit extends Cubit<ReportsState> implements ReportsCubit {
  int loadReportsCount = 0;

  _FakeReportsCubit([ReportsState? initial])
      : super(
          initial ??
              const ReportsLoaded(
                AttendanceStatsEntity(
                  totalStudents: 25,
                  presentToday: 22,
                  absentToday: 2,
                  unmarkedToday: 1,
                  averageAttendance: 88.0,
                  weeklyTrend: [],
                  studentReports: [],
                ),
              ),
        );

  @override
  Future<void> loadReports() async {
    loadReportsCount++;
  }

  void emitState(ReportsState newState) => emit(newState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  late _FakeAuthCubit authCubit;
  late _FakeTeacherCubit teacherCubit;
  late _FakeReportsCubit reportsCubit;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    authCubit = _FakeAuthCubit();
    teacherCubit = _FakeTeacherCubit();
    reportsCubit = _FakeReportsCubit();
  });

  tearDown(() {
    authCubit.close();
    teacherCubit.close();
    reportsCubit.close();
  });

  Widget buildTestWidget({
    GoRouter? router,
    bool wrapWithMainShell = false,
  }) {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: AppRoutes.teacherHome,
          routes: [
            GoRoute(
              path: AppRoutes.teacherHome,
              builder: (context, state) {
                final screen = const TeacherHomeScreen();
                return wrapWithMainShell ? MainShell(child: screen) : screen;
              },
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (context, state) => const Scaffold(
                body: Text('LoginDestination'),
              ),
            ),
            GoRoute(
              path: AppRoutes.myClasses,
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('BackFromMyClasses'),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.qrScan,
              builder: (context, state) {
                final extraClassId = state.extra as String?;
                return Scaffold(
                  body: Column(
                    children: [
                      Text('QrScanExtra: $extraClassId'),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('BackFromQrScan'),
                      ),
                    ],
                  ),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.attendanceHistory,
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('BackFromAttendanceHistory'),
                ),
              ),
            ),
            GoRoute(
              name: 'reports',
              path: AppRoutes.reports,
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('BackFromReports'),
                ),
              ),
            ),
          ],
        );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<TeacherCubit>.value(value: teacherCubit),
        BlocProvider<ReportsCubit>.value(value: reportsCubit),
      ],
      child: MaterialApp.router(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: effectiveRouter,
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester, {GoRouter? router, bool wrapWithMainShell = false}) async {
    await tester.pumpWidget(buildTestWidget(router: router, wrapWithMainShell: wrapWithMainShell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('TeacherHomeScreen Comprehensive Widget Tests', () {
    testWidgets('1. Mounts and displays welcome header, greeting, and loaded statistics', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      expect(find.byType(TeacherHomeScreen), findsOneWidget);
      expect(find.text('أحمد الريامي'), findsOneWidget);
      expect(find.text(l10n.welcome), findsOneWidget);
      expect(find.text(l10n.greetingAfternoon), findsOneWidget);

      // Verify Stats Section values
      expect(find.text('25'), findsOneWidget); // total students
      expect(find.text('22'), findsOneWidget); // present today
      expect(find.text('2'), findsOneWidget);  // absent today
      expect(find.text('1'), findsOneWidget);  // unmarked today

      // Labels
      expect(find.text(l10n.studentCount), findsOneWidget);
      expect(find.text(l10n.presentToday), findsOneWidget);
      expect(find.text(l10n.absentToday), findsOneWidget);
      expect(find.text(l10n.unmarked), findsOneWidget);

      // Verify Quick Actions Section
      expect(find.text(l10n.quickActions), findsOneWidget);
      expect(find.text(l10n.myStudents), findsOneWidget);
      expect(find.text(l10n.scanAttendance), findsOneWidget);
      expect(find.text(l10n.attendanceHistory), findsOneWidget);
      expect(find.text(l10n.reports), findsOneWidget);

      // Cubits should have been triggered on initState
      expect(teacherCubit.loadClassroomCount, 1);
      expect(reportsCubit.loadReportsCount, 1);
    });

    testWidgets('2. Displays placeholder dashes when reports are not loaded yet', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      reportsCubit = _FakeReportsCubit(ReportsLoading());

      await pumpScreen(tester);

      // With ReportsLoading, all 4 stats cards display '-'
      expect(find.text('-'), findsNWidgets(4));
    });

    testWidgets('3. Renders loading indicator in Quick Actions when TeacherLoading', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      teacherCubit = _FakeTeacherCubit(TeacherLoading());

      await pumpScreen(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(l10n.myStudents), findsNothing);
    });

    testWidgets('4. Renders error message in Quick Actions when TeacherError', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const errorMsg = 'فشل في تحميل بيانات الفصل الدراسي';
      teacherCubit = _FakeTeacherCubit(const TeacherError(errorMsg));

      await pumpScreen(tester);

      expect(find.text(errorMsg), findsOneWidget);
      expect(find.text(l10n.myStudents), findsNothing);
    });

    testWidgets('5. Tapping My Students action card navigates and reloads on pop', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      expect(teacherCubit.loadClassroomCount, 1);
      expect(reportsCubit.loadReportsCount, 1);

      await tester.tap(find.text(l10n.myStudents));
      await tester.pumpAndSettle();

      expect(find.text('BackFromMyClasses'), findsOneWidget);

      // Pop back
      await tester.tap(find.text('BackFromMyClasses'));
      await tester.pumpAndSettle();

      // Verify that returning refreshed the screen
      expect(teacherCubit.loadClassroomCount, 2);
      expect(reportsCubit.loadReportsCount, 2);
    });

    testWidgets('6. Tapping Scan Attendance action card pushes qrScan with classId and reloads on pop', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      await tester.tap(find.text(l10n.scanAttendance));
      await tester.pumpAndSettle();

      expect(find.text('QrScanExtra: class_grade_4a'), findsOneWidget);

      // Pop back
      await tester.tap(find.text('BackFromQrScan'));
      await tester.pumpAndSettle();

      expect(teacherCubit.loadClassroomCount, 2);
      expect(reportsCubit.loadReportsCount, 2);
    });

    testWidgets('7. Tapping Attendance History action card navigates and reloads on pop', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      await tester.tap(find.text(l10n.attendanceHistory));
      await tester.pumpAndSettle();

      expect(find.text('BackFromAttendanceHistory'), findsOneWidget);

      await tester.tap(find.text('BackFromAttendanceHistory'));
      await tester.pumpAndSettle();

      expect(teacherCubit.loadClassroomCount, 2);
      expect(reportsCubit.loadReportsCount, 2);
    });

    testWidgets('8. Tapping Reports action card navigates via pushNamed and reloads on pop', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      await tester.tap(find.text(l10n.reports));
      await tester.pumpAndSettle();

      expect(find.text('BackFromReports'), findsOneWidget);

      await tester.tap(find.text('BackFromReports'));
      await tester.pumpAndSettle();

      expect(teacherCubit.loadClassroomCount, 2);
      expect(reportsCubit.loadReportsCount, 2);
    });

    testWidgets('9. Pull to refresh triggers loadClassroom and loadReports', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      final initialClassroomCalls = teacherCubit.loadClassroomCount;
      final initialReportsCalls = reportsCubit.loadReportsCount;

      final refreshFinder = find.byType(RefreshIndicator);
      expect(refreshFinder, findsOneWidget);

      unawaited(tester.widget<RefreshIndicator>(refreshFinder).onRefresh());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(teacherCubit.loadClassroomCount, initialClassroomCalls + 1);
      expect(reportsCubit.loadReportsCount, initialReportsCalls + 1);
    });

    testWidgets('10. Auth listener navigates to login when AuthUnauthenticated is emitted', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      authCubit.emit(AuthUnauthenticated());
      await tester.pumpAndSettle();

      expect(find.text('LoginDestination'), findsOneWidget);
    });

    testWidgets('11. PopScope handles double-back exit prevention cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      // Trigger pop scope callback
      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScope = tester.widget<PopScope<Object?>>(popScopeFinder);
      popScope.onPopInvokedWithResult?.call(false, null);
      await tester.pump();

      expect(find.text('اضغط مرة أخرى للخروج من التطبيق'), findsOneWidget);
    });

    testWidgets('12. AppBar drawer icon opens drawer when wrapped with MainShell', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester, wrapWithMainShell: true);

      final drawerButton = find.byIcon(PhosphorIconsRegular.list);
      expect(drawerButton, findsOneWidget);

      await tester.tap(drawerButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TeacherHomeScreen), findsOneWidget);
    });
  });
}
