import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:msaratwasel_services/config/theme/app_theme.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/field_supervisor/delays/presentation/screens/delays_screen.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

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

class _FakeDioAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) return handler!(options);
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': []}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();

  late _FakeDioAdapter adapter;
  late Dio dio;
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    adapter = _FakeDioAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://test.msaratwasel.com/api/'));
    dio.httpClientAdapter = adapter;
    ApiClient.testDio = dio;
  });

  tearDown(() {
    ApiClient.testDio = null;
  });

  Widget buildTestWidget({ThemeData? theme}) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme ?? AppTheme.light,
      home: const DelaysScreen(),
    );
  }

  final sampleStudentDelays = [
    {
      'id': 1,
      'student_name': 'سعيد الكندي',
      'bus_code': 'BUS-07',
      'duration_minutes': 15,
      'created_at': '2026-09-04T07:10:00',
      'reason': 'تأخر في الاستيقاظ',
    },
    {
      'id': 2,
      'student_name': 'فاطمة الزدجالي',
      'bus_code': 'BUS-12',
      'duration_minutes': 20,
      'created_at': '2026-09-04T07:25:00',
      'reason': 'ظرف عائلي طارئ',
    },
  ];

  final sampleBusDelays = [
    {
      'id': 3,
      'bus_code': 'BUS-99',
      'duration_minutes': 35,
      'created_at': '2026-09-04T07:40:00',
      'reason': 'ازدحام مروري عند الدوار',
    },
  ];

  group('DelaysScreen Comprehensive Widget Tests', () {
    testWidgets('1. Initial loading and empty states for student and bus delays', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text(l10n.registerDelays), findsWidgets);
      expect(find.text(l10n.studentDelays), findsOneWidget);
      expect(find.text(l10n.busDelays), findsOneWidget);

      // In student tab, empty state
      expect(find.text('لا توجد تأخيرات مسجلة'), findsOneWidget);
      expect(find.byIcon(Icons.person_off), findsOneWidget);

      // Switch to bus delays tab
      final busTab = find.text(l10n.busDelays);
      await tester.tap(busTab);
      await tester.pumpAndSettle();

      // Bus tab empty state
      expect(find.byIcon(Icons.no_transfer), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('2. Loads and renders student delays with duration, bus code, and reason', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        if (options.path.contains('field/delays')) {
          final isStudent = options.queryParameters['type'] == 'student';
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': isStudent ? sampleStudentDelays : sampleBusDelays,
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check student delay records
      expect(find.text('سعيد الكندي'), findsOneWidget);
      expect(find.text('فاطمة الزدجالي'), findsOneWidget);
      expect(find.textContaining('15'), findsWidgets);
      expect(find.textContaining('20'), findsWidgets);
      expect(find.text('تأخر في الاستيقاظ'), findsOneWidget);
      expect(find.text('ظرف عائلي طارئ'), findsOneWidget);

      // Switch to Bus Delays tab
      await tester.tap(find.text(l10n.busDelays));
      await tester.pumpAndSettle();

      expect(find.text('BUS-99'), findsOneWidget);
      expect(find.textContaining('35'), findsWidgets);
      expect(find.text('ازدحام مروري عند الدوار'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Opens NewDelaySheet and validates required duration and selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap add delay button
      final addBtn = find.byIcon(Icons.add_circle_outline_rounded);
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text(l10n.registerNewDelay), findsOneWidget);
      expect(find.text(l10n.saveAndSend), findsOneWidget);

      // Tap Save without inputs
      await tester.tap(find.text(l10n.saveAndSend));
      await tester.pump();

      expect(find.text('يرجى إدخال مدة التأخير'), findsOneWidget);

      // Clear snackbar
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('4. Searches and selects student in NewDelaySheet, and submits student delay', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool delaySubmitted = false;

      adapter.handler = (options) {
        if (options.method == 'POST' && options.path.contains('field/delays')) {
          delaySubmitted = true;
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': {'id': 50}}),
            201,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/students')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 10, 'name': 'ناصر الوهيبي', 'code': 'STD-77'},
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open new delay sheet
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      // Tap select student decorator to open StudentSearchSheet
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(find.text('ناصر الوهيبي'), findsOneWidget);
      await tester.tap(find.text('ناصر الوهيبي'));
      await tester.pumpAndSettle();

      // Student is now selected
      expect(find.text('ناصر الوهيبي'), findsOneWidget);

      // Enter duration
      await tester.enterText(find.widgetWithText(TextField, ''), '25');
      await tester.pump();

      // Select reason
      final reasonDropdown = find.byType(DropdownButtonFormField<String>);
      expect(reasonDropdown, findsOneWidget);
      await tester.tap(reasonDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.studentLate).last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text(l10n.saveAndSend));
      await tester.pumpAndSettle();

      expect(delaySubmitted, isTrue);
      expect(find.text(l10n.delaySavedAndReported), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('5. Switches to bus delay segment in NewDelaySheet, selects bus, and submits', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool busDelaySubmitted = false;

      adapter.handler = (options) {
        if (options.method == 'POST' && options.path.contains('field/delays')) {
          busDelaySubmitted = true;
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': {'id': 51}}),
            201,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/buses')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 5, 'bus_code': 'BUS-05', 'driver_name': 'علي الحبسي'},
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      // Tap 'حافلة' segment button in SegmentedButton
      final busSegment = find.text(l10n.bus);
      expect(busSegment, findsOneWidget);
      await tester.tap(busSegment);
      await tester.pumpAndSettle();

      // Open bus search sheet
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(find.text('BUS-05'), findsOneWidget);
      await tester.tap(find.text('BUS-05'));
      await tester.pumpAndSettle();

      // Enter duration
      await tester.enterText(find.widgetWithText(TextField, ''), '40');
      await tester.pump();

      // Submit
      await tester.tap(find.text(l10n.saveAndSend));
      await tester.pumpAndSettle();

      expect(busDelaySubmitted, isTrue);
      expect(find.text(l10n.delaySavedAndReported), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('6. RefreshIndicator reloads delays', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int loadCount = 0;
      adapter.handler = (options) {
        if (options.path.contains('field/delays')) {
          loadCount++;
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': []}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final initialCount = loadCount;
      expect(initialCount, greaterThan(0));

      final refreshFinder = find.byType(RefreshIndicator);
      expect(refreshFinder, findsOneWidget);
      unawaited(tester.widget<RefreshIndicator>(refreshFinder).onRefresh());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(loadCount, greaterThan(initialCount));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('7. Renders cleanly in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': sampleStudentDelays,
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget(theme: AppTheme.dark));
      await tester.pumpAndSettle();

      expect(find.text(l10n.registerDelays), findsWidgets);
      expect(find.text('سعيد الكندي'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
