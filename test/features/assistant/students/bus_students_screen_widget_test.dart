import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/config/theme/app_theme.dart';
import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_trip_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/repositories/assistant_repository.dart';
import 'package:msaratwasel_services/features/assistant/core/presentation/cubit/bus_trip_cubit.dart';
import 'package:msaratwasel_services/features/assistant/students/presentation/screens/bus_students_screen.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
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

class _FakeAssistantRepository implements AssistantRepository {
  List<String> groupAlightCalledWith = [];
  List<String> groupBoardCalledWith = [];

  @override
  Future<Either<String, BusTripEntity>> getActiveTrip() async =>
      Left('Not implemented');

  @override
  Future<Either<String, void>> groupAlight({
    required List<String> studentIds,
    required String direction,
  }) async {
    groupAlightCalledWith = studentIds;
    return const Right(null);
  }

  @override
  Future<Either<String, void>> groupBoard({
    required List<String> studentIds,
    required String direction,
  }) async {
    groupBoardCalledWith = studentIds;
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBusTripCubit extends Cubit<BusTripState> implements BusTripCubit {
  final _FakeAssistantRepository repository;
  _FakeBusTripCubit(this.repository, super.initialState);

  @override
  Future<void> loadTrip({bool silent = false}) async {}

  @override
  Future<void> groupAlight(List<String> studentIds, String direction) async {
    await repository.groupAlight(studentIds: studentIds, direction: direction);
  }

  @override
  Future<void> groupBoard(List<String> studentIds, String direction) async {
    await repository.groupBoard(studentIds: studentIds, direction: direction);
  }

  void emitState(BusTripState state) => emit(state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit([AuthState? initial])
      : super(
          initial ??
              const AuthAuthenticated(
                UserEntity(
                  id: 'ast_1',
                  name: 'منى المساعدة',
                  role: UserRole.assistant,
                  token: 'tok_ast',
                  busId: null, // null busId to bypass Reverb socket
                ),
              ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeController themeController;
  late SettingsController settingsController;
  late _FakeAuthCubit authCubit;
  late _FakeAssistantRepository assistantRepo;
  late _FakeBusTripCubit busTripCubit;

  final sampleStudents = [
    const BusStudentEntity(
      id: 's1',
      studentCode: 'STD001',
      name: 'عبدالله محمد',
      grade: 'الصف الثالث',
      schoolId: 'sch_1',
      parentName: 'محمد أحمد',
      parentPhone: '0501112233',
      status: BusStudentStatus.onBus,
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
      status: BusStudentStatus.atSchool,
      waitingElapsedSeconds: 120,
    ),
    const BusStudentEntity(
      id: 's3',
      studentCode: 'STD003',
      name: 'خالد يوسف',
      grade: 'الصف الرابع',
      schoolId: 'sch_1',
      parentName: 'يوسف خليل',
      parentPhone: '0503334455',
      status: BusStudentStatus.atHome,
      waitingElapsedSeconds: 0,
    ),
    const BusStudentEntity(
      id: 's4',
      studentCode: 'STD004',
      name: 'نورة سعيد',
      grade: 'الصف الثاني',
      schoolId: 'sch_1',
      parentName: 'سعيد سالم',
      parentPhone: '0504445566',
      status: BusStudentStatus.absent,
      waitingElapsedSeconds: 0,
    ),
  ];

  final sampleTrip = BusTripEntity(
    id: 'trip_100',
    busNumber: 'Bus-42',
    driverName: 'سعيد السائق',
    assistantName: 'منى المرافقة',
    students: sampleStudents,
    startTime: DateTime(2026, 9, 5, 7, 0),
    tripStatus: 'in_progress',
    suggestedDirection: 'to_school',
    suggestedTripType: 'to_school',
  );

  setUp(() async {
    HttpOverrides.global = _MockHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
    }

    themeController = ThemeController();
    await themeController.load();
    settingsController = SettingsController();
    await settingsController.load();

    assistantRepo = _FakeAssistantRepository();
    busTripCubit = _FakeBusTripCubit(assistantRepo, BusTripInitial());
    authCubit = _FakeAuthCubit();
  });

  tearDown(() {
    authCubit.close();
    busTripCubit.close();
  });

  Widget buildTestWidget({ThemeData? theme}) {
    return ThemeProvider(
      controller: themeController,
      child: SettingsProvider(
        controller: settingsController,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<BusTripCubit>.value(value: busTripCubit),
          ],
          child: MaterialApp(
            theme: theme ?? AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: const BusStudentsScreen(),
          ),
        ),
      ),
    );
  }

  group('BusStudentsScreen Comprehensive Widget Tests', () {
    testWidgets('1. Shows loading indicator when state is BusTripLoading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      busTripCubit.emitState(BusTripLoading());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('2. Shows error message when state is BusTripError', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      busTripCubit.emitState(const BusTripError('تعذر جلب تفاصيل الرحلة'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('تعذر جلب تفاصيل الرحلة'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Renders trip progress, search bar, and all student cards in loaded state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      busTripCubit.emitState(BusTripLoaded(sampleTrip));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify student cards
      expect(find.text('عبدالله محمد'), findsOneWidget);
      expect(find.text('سارة علي'), findsOneWidget);
      expect(find.text('خالد يوسف'), findsOneWidget);
      expect(find.text('نورة سعيد'), findsOneWidget);

      // Verify search input field
      expect(find.byType(TextField), findsOneWidget);

      // Verify filter chips exist
      expect(find.byType(FilterChip), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('4. Filters student list using search query and shows empty message on no match', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      busTripCubit.emitState(BusTripLoaded(sampleTrip));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Enter search query matching single student
      await tester.enterText(find.byType(TextField), 'سارة');
      await tester.pump();

      expect(find.text('سارة علي'), findsOneWidget);
      expect(find.text('عبدالله محمد'), findsNothing);

      // Enter query matching no students
      await tester.enterText(find.byType(TextField), 'اسم غير موجود');
      await tester.pump();

      expect(find.text('لا يوجد طلاب يطابقون البحث'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('5. Filters student list using FilterChips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      busTripCubit.emitState(BusTripLoaded(sampleTrip));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Find FilterChip for onBus (في الحافلة)
      final onBusChip = find.widgetWithText(FilterChip, 'في الحافلة');
      expect(onBusChip, findsOneWidget);
      await tester.tap(onBusChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Only onBus student 'عبدالله محمد' should be visible
      expect(find.text('عبدالله محمد'), findsOneWidget);
      expect(find.text('سارة علي'), findsNothing);

      // Select 'الكل' to restore all students
      final allChip = find.widgetWithText(FilterChip, 'الكل');
      await tester.tap(allChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('عبدالله محمد'), findsOneWidget);
      expect(find.text('سارة علي'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('6. Batch selection mode and group alight execution', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      busTripCubit.emitState(BusTripLoaded(sampleTrip));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap select all icon button in app bar
      final selectAllBtn = find.byIcon(Icons.select_all_rounded);
      expect(selectAllBtn, findsOneWidget);
      await tester.tap(selectAllBtn);
      await tester.pump();

      // Batch action header should be visible
      expect(find.textContaining('نزول للمحددين'), findsOneWidget);

      // Tap group action button
      await tester.tap(find.textContaining('نزول للمحددين'));
      await tester.pump();

      // Verify groupAlight was dispatched
      expect(assistantRepo.groupAlightCalledWith, isNotEmpty);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('7. Listener shows snackbars on update success and error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      busTripCubit.emitState(BusTripLoaded(sampleTrip));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Trigger update success
      busTripCubit.emitState(const BusTripUpdateSuccess('تم تسجيل ركوب الطالب'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('تم تسجيل ركوب الطالب'), findsOneWidget);

      // Clear first snackbar before showing next
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 300));

      // Trigger update error
      busTripCubit.emitState(const BusTripUpdateError('فشل تسجيل النزول'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('فشل تسجيل النزول'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('8. Renders cleanly in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      busTripCubit.emitState(BusTripLoaded(sampleTrip));

      await tester.pumpWidget(buildTestWidget(theme: AppTheme.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('عبدالله محمد'), findsOneWidget);
      expect(find.text('سارة علي'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
