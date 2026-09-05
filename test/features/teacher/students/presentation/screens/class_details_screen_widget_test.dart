import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_button.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/class_details_cubit.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/class_details_state.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/screens/class_details_screen.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';
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

class _FakeClassDetailsCubit extends Cubit<ClassDetailsState> implements ClassDetailsCubit {
  int loadStudentsCallCount = 0;
  String? lastLoadedClassId;
  String? lastMarkedStudentId;
  AttendanceStatus? lastMarkedStatus;
  String? lastMarkedClassId;
  int markAttendanceCount = 0;
  bool submitReportReturnValue = true;
  int submitReportCallCount = 0;

  _FakeClassDetailsCubit([ClassDetailsState? initial])
      : super(initial ?? ClassDetailsInitial());

  @override
  Future<void> loadStudents(String classId) async {
    loadStudentsCallCount++;
    lastLoadedClassId = classId;
  }

  @override
  Future<void> markAttendance(
    String studentId,
    AttendanceStatus status,
    String classId,
  ) async {
    markAttendanceCount++;
    lastMarkedStudentId = studentId;
    lastMarkedStatus = status;
    lastMarkedClassId = classId;
  }

  @override
  Future<bool> submitDailyReport() async {
    submitReportCallCount++;
    return submitReportReturnValue;
  }

  void emitState(ClassDetailsState state) => emit(state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  const sampleClassroom = ClassroomEntity(
    id: 'class_4a',
    name: 'الصف الرابع أ',
    grade: '4',
    studentCount: 3,
  );

  final sampleStudents = [
    const StudentEntity(
      id: 'std_1',
      name: 'علي المعمري',
      parentName: 'سعيد المعمري',
      parentPhone: '96891234567',
      photoUrl: 'https://example.com/ali.png',
      parentPhotoUrl: 'https://example.com/parent.png',
      status: AttendanceStatus.present,
      isLocked: false,
    ),
    const StudentEntity(
      id: 'std_2',
      name: 'سالم الشكيلي',
      parentName: 'حمد الشكيلي',
      parentPhone: '96898765432',
      status: AttendanceStatus.absent,
      isLocked: true, // Locked and already marked
    ),
    const StudentEntity(
      id: 'std_3',
      name: 'خالد الكندي',
      parentName: 'محمد الكندي',
      parentPhone: '96891112233',
      status: AttendanceStatus.unknown,
      isLocked: false,
    ),
  ];

  late _FakeClassDetailsCubit cubit;
  late _FakeAuthCubit authCubit;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    authCubit = _FakeAuthCubit();
    cubit = _FakeClassDetailsCubit(ClassDetailsLoaded(sampleStudents, 'class_4a'));
  });

  tearDown(() {
    authCubit.close();
    cubit.close();
  });

  GoRouter createTestRouter({bool wrapWithMainShell = false}) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push(AppRoutes.classDetailsPath('class_4a')),
              child: const Text('GoToClassDetails'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.classDetails,
          builder: (context, state) {
            final screen = const ClassDetailsScreen(classroom: sampleClassroom);
            return wrapWithMainShell ? MainShell(child: screen) : screen;
          },
        ),
        GoRoute(
          path: AppRoutes.qrScan,
          builder: (context, state) {
            final extra = state.extra as String?;
            return Scaffold(
              body: Column(
                children: [
                  Text('QrScanClassId: $extra'),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('BackFromQrScan'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildTestWidget({
    GoRouter? router,
    ThemeData? theme,
    bool wrapWithMainShell = false,
  }) {
    final effectiveRouter = router ?? createTestRouter(wrapWithMainShell: wrapWithMainShell);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<ClassDetailsCubit>.value(value: cubit),
      ],
      child: MaterialApp.router(
        theme: theme ?? ThemeData.light(),
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: effectiveRouter,
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    GoRouter? router,
    ThemeData? theme,
    bool wrapWithMainShell = false,
  }) async {
    final effectiveRouter = router ?? createTestRouter(wrapWithMainShell: wrapWithMainShell);
    await tester.pumpWidget(buildTestWidget(router: effectiveRouter, theme: theme, wrapWithMainShell: wrapWithMainShell));
    await tester.pump();
    // Navigate from '/' to class details screen
    effectiveRouter.push(AppRoutes.classDetailsPath('class_4a'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('ClassDetailsScreen Comprehensive Widget Tests', () {
    testWidgets('1. Mounts and displays classroom name, student cards, and finish button', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      expect(find.byType(ClassDetailsScreen), findsOneWidget);
      expect(find.text('الصف الرابع أ'), findsWidgets);

      // Verify all students are displayed
      expect(find.text('علي المعمري'), findsOneWidget);
      expect(find.text('سعيد المعمري'), findsOneWidget);
      expect(find.text('سالم الشكيلي'), findsOneWidget);
      expect(find.text('حمد الشكيلي'), findsOneWidget);
      expect(find.text('خالد الكندي'), findsOneWidget);
      expect(find.text('محمد الكندي'), findsOneWidget);

      // Bottom bar button
      expect(find.byType(PremiumButton), findsOneWidget);
      expect(find.text(l10n.finishAttendance), findsOneWidget);

      // Verify loadStudents called on initState
      expect(cubit.loadStudentsCallCount, 1);
      expect(cubit.lastLoadedClassId, 'class_4a');
    });

    testWidgets('2. Shows loading indicator when state is ClassDetailsLoading', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      cubit = _FakeClassDetailsCubit(ClassDetailsLoading());

      await pumpScreen(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('علي المعمري'), findsNothing);
    });

    testWidgets('3. Shows error message when state is ClassDetailsError', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const errorMsg = 'تعذر تحميل قائمة الطلاب';
      cubit = _FakeClassDetailsCubit(const ClassDetailsError(errorMsg));

      await pumpScreen(tester);

      expect(find.text(errorMsg), findsOneWidget);
    });

    testWidgets('4. Tapping Present/Absent buttons marks attendance for unlocked student', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      // Student 1 (unlocked): tap Absent ('غائب')
      final absentButtons = find.text(l10n.absent);
      expect(absentButtons, findsNWidgets(3));

      await tester.tap(absentButtons.at(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cubit.markAttendanceCount, 1);
      expect(cubit.lastMarkedStudentId, 'std_1');
      expect(cubit.lastMarkedStatus, AttendanceStatus.absent);
      expect(cubit.lastMarkedClassId, 'class_4a');

      // Student 3 (unlocked): tap Present ('حاضر')
      final presentButtons = find.text(l10n.present);
      expect(presentButtons, findsNWidgets(3));

      await tester.tap(presentButtons.at(2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cubit.markAttendanceCount, 2);
      expect(cubit.lastMarkedStudentId, 'std_3');
      expect(cubit.lastMarkedStatus, AttendanceStatus.present);
    });

    testWidgets('5. Locked student with recorded status cannot be toggled', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      // Student 2 is locked with status absent. Tapping present on student 2:
      final presentButtons = find.text(l10n.present);
      await tester.tap(presentButtons.at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // markAttendanceCount must remain 0
      expect(cubit.markAttendanceCount, 0);
    });

    testWidgets('6. Tapping student card opens bottom sheet with details', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      // Tap student 1 card
      await tester.tap(find.text('علي المعمري'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Modal bottom sheet should be displayed
      expect(find.text(l10n.parentGuardian), findsOneWidget);
      expect(find.text(l10n.parentPhone), findsOneWidget);
      expect(find.text(l10n.whatsapp), findsOneWidget);
      expect(find.text('96891234567'), findsNWidgets(2));

      // Tap phone row and whatsapp row
      await tester.tap(find.text('96891234567').first);
      await tester.pump();
      await tester.tap(find.text('96891234567').last);
      await tester.pump();

      // Dismiss modal by tapping outside
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text(l10n.parentGuardian), findsNothing);
    });

    testWidgets('7. Confirmation dialog displays summary, warning, and handles cancel', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      // Tap Finish Attendance button
      await tester.tap(find.text(l10n.finishAttendance));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirmation dialog is open
      expect(find.text(l10n.attendanceSummary), findsOneWidget);
      expect(find.text(l10n.confirmSendReport), findsOneWidget);

      // Stats check: total: 3, present: 1, absent: 1, unmarked: 1
      expect(find.text('3'), findsOneWidget); // total
      expect(find.text('1'), findsNWidgets(3)); // present: 1, absent: 1, unmarked: 1

      // Warning banner for 1 unmarked student
      expect(find.text(l10n.unmarkedStudentsWarning(1)), findsOneWidget);

      // Tap Cancel ('إلغاء')
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.attendanceSummary), findsNothing);
      expect(cubit.submitReportCallCount, 0);
    });

    testWidgets('8. Confirmation dialog confirm submission shows success snackbar', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      cubit.submitReportReturnValue = true;

      await pumpScreen(tester);

      await tester.tap(find.text(l10n.finishAttendance));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Confirm ('تأكيد وإرسال')
      await tester.tap(find.text(l10n.confirmSend));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cubit.submitReportCallCount, 1);
      expect(find.text(l10n.dailyReportSentSuccess), findsOneWidget);
    });

    testWidgets('9. Confirmation dialog failure shows error snackbar', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      cubit.submitReportReturnValue = false;

      await pumpScreen(tester);

      await tester.tap(find.text(l10n.finishAttendance));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(l10n.confirmSend));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cubit.submitReportCallCount, 1);
      expect(find.text('فشل تأكيد وإرسال التقرير، يرجى المحاولة لاحقاً'), findsOneWidget);
    });

    testWidgets('10. Trailing QR button pushes qrScan route with classId and reloads on pop', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester);

      expect(cubit.loadStudentsCallCount, 1);

      // Tap QR code icon button in sliver app bar
      final qrButton = find.byIcon(PhosphorIconsRegular.qrCode);
      expect(qrButton, findsOneWidget);

      await tester.tap(qrButton);
      await tester.pumpAndSettle();

      expect(find.text('QrScanClassId: class_4a'), findsOneWidget);

      // Pop back
      await tester.tap(find.text('BackFromQrScan'));
      await tester.pumpAndSettle();

      expect(cubit.loadStudentsCallCount, 2);
    });

    testWidgets('11. Leading drawer button triggers openDrawer when MainShell is present', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester, wrapWithMainShell: true);

      final drawerButton = find.byIcon(PhosphorIconsRegular.list).first;
      await tester.tap(drawerButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ClassDetailsScreen), findsOneWidget);
    });

    testWidgets('12. Renders properly in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(tester, theme: ThemeData.dark());

      expect(find.text('الصف الرابع أ'), findsWidgets);
      expect(find.text('علي المعمري'), findsOneWidget);
    });
  });
}
