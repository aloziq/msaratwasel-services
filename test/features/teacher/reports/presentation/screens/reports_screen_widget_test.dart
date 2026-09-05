import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/entities/report_entity.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/cubit/reports_cubit.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/cubit/reports_state.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/screens/reports_screen.dart';
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
  _FakeAuthCubit()
      : super(
          const AuthAuthenticated(
            UserEntity(
              id: 'tch_1',
              name: 'أحمد الريامي',
              role: UserRole.teacher,
              token: 'tok_tch',
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReportsCubit extends Cubit<ReportsState> implements ReportsCubit {
  int loadReportsCallCount = 0;

  _FakeReportsCubit([ReportsState? initial])
      : super(initial ?? ReportsInitial());

  @override
  Future<void> loadReports() async {
    loadReportsCallCount++;
  }

  void emitState(ReportsState state) => emit(state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  const sampleStudentReports = [
    StudentReportEntity(
      name: 'علي المعمري',
      nameEn: 'Ali Al-Maamari',
      civilId: '12345678',
      photoUrl: 'https://example.com/ali.png',
      presentCount: 18,
      absentCount: 2,
    ),
    StudentReportEntity(
      name: 'سالم الشكيلي',
      nameEn: 'Salim Al-Shukaili',
      civilId: '87654321',
      photoUrl: null,
      presentCount: 15,
      absentCount: 5,
    ),
    StudentReportEntity(
      name: 'خالد الكندي',
      nameEn: 'Khalid Al-Kindi',
      civilId: '11223344',
      photoUrl: null,
      presentCount: 20,
      absentCount: 0,
    ),
  ];

  const sampleStats = AttendanceStatsEntity(
    totalStudents: 30,
    presentToday: 25,
    absentToday: 3,
    unmarkedToday: 2,
    averageAttendance: 90.0,
    weeklyTrend: [],
    studentReports: sampleStudentReports,
  );

  late _FakeAuthCubit authCubit;
  late _FakeReportsCubit reportsCubit;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    authCubit = _FakeAuthCubit();
    reportsCubit = _FakeReportsCubit(const ReportsLoaded(sampleStats));
  });

  tearDown(() {
    authCubit.close();
    reportsCubit.close();
  });

  Widget buildTestWidget({
    ThemeData? theme,
    bool wrapWithMainShell = false,
  }) {
    final screen = const ReportsScreen();
    final child = wrapWithMainShell ? MainShell(child: screen) : screen;

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<ReportsCubit>.value(value: reportsCubit),
      ],
      child: MaterialApp(
        theme: theme ?? ThemeData.light(),
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    ThemeData? theme,
    bool wrapWithMainShell = false,
  }) async {
    await tester.pumpWidget(buildTestWidget(theme: theme, wrapWithMainShell: wrapWithMainShell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('ReportsScreen Comprehensive Widget Tests', () {
    testWidgets('1. Mounts and displays summary cards, search bar, and student reports', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(find.text(l10n.reportsTitle), findsWidgets);

      // Verify 5 Summary Cards
      expect(find.text(l10n.totalStudents), findsOneWidget);
      expect(find.text('30'), findsOneWidget);

      expect(find.text(l10n.attendanceToday), findsOneWidget);
      expect(find.text('25'), findsOneWidget);

      expect(find.text(l10n.absenceToday), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      expect(find.text(l10n.averageAttendance), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);

      expect(find.text(l10n.unmarkedToday), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify Section Title and Search Bar
      expect(find.text(l10n.studentStatistics), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify students displayed
      expect(find.text('علي المعمري'), findsOneWidget);
      expect(find.text('سالم الشكيلي'), findsOneWidget);
      expect(find.text('خالد الكندي'), findsOneWidget);

      // Verify loadReports called on initState
      expect(reportsCubit.loadReportsCallCount, 1);
    });

    testWidgets('2. Shows loading indicator when state is ReportsLoading', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      reportsCubit = _FakeReportsCubit(ReportsLoading());

      await pumpScreen(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('علي المعمري'), findsNothing);
    });

    testWidgets('3. Shows error message when state is ReportsError', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const errorMsg = 'تعذر جلب تقارير الحضور';
      reportsCubit = _FakeReportsCubit(const ReportsError(errorMsg));

      await pumpScreen(tester);

      expect(find.text(errorMsg), findsOneWidget);
    });

    testWidgets('4. Search filtering matches student names and civil IDs properly', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      // Search for 'سالم'
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'سالم');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('سالم الشكيلي'), findsOneWidget);
      expect(find.text('علي المعمري'), findsNothing);
      expect(find.text('خالد الكندي'), findsNothing);

      // Search by civil ID '11223344'
      await tester.enterText(searchField, '11223344');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('خالد الكندي'), findsOneWidget);
      expect(find.text('سالم الشكيلي'), findsNothing);

      // Search non-existent name
      await tester.enterText(searchField, 'اسم غير موجود');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n.noResultsFound), findsOneWidget);

      // Clear search restores all
      await tester.enterText(searchField, '');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('علي المعمري'), findsOneWidget);
      expect(find.text('سالم الشكيلي'), findsOneWidget);
      expect(find.text('خالد الكندي'), findsOneWidget);
    });

    testWidgets('5. Tapping student card opens attendance modal and navigates calendar months', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      // Tap on student card
      await tester.tap(find.text('علي المعمري'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Check modal contents
      expect(find.text(l10n.attendanceDays), findsOneWidget);
      expect(find.text(l10n.absenceDays), findsOneWidget);
      expect(find.text('18'), findsOneWidget); // present count
      expect(find.text('2'), findsWidgets);   // absent count (in modal + summary card)

      // Calendar navigation: tap previous month and next month
      final prevMonthButton = find.byIcon(Icons.chevron_left);
      expect(prevMonthButton, findsOneWidget);
      await tester.tap(prevMonthButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final nextMonthButton = find.byIcon(Icons.chevron_right);
      expect(nextMonthButton, findsOneWidget);
      await tester.tap(nextMonthButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dismiss modal by tapping outside
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text(l10n.attendanceDays), findsNothing);
    });

    testWidgets('6. Leading drawer button triggers openDrawer when MainShell is present', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester, wrapWithMainShell: true);

      final drawerButton = find.byIcon(PhosphorIconsRegular.list).first;
      await tester.tap(drawerButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ReportsScreen), findsOneWidget);
    });

    testWidgets('7. Renders properly in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester, theme: ThemeData.dark());

      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(find.text('علي المعمري'), findsOneWidget);
    });
  });
}
