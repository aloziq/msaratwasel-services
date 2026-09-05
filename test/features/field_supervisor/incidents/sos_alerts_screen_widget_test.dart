import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:msaratwasel_services/config/theme/app_theme.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/field_supervisor/incidents/presentation/screens/sos_alerts_screen.dart';
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
      home: const SosAlertsScreen(),
    );
  }

  final sampleIncidents = [
    {
      'id': 101,
      'type': 'sos',
      'status': 'pending',
      'severity': 'critical',
      'title': 'نداء استغاثة عاجل',
      'description': 'عطل كهربائي وتوقف الحافلة في المسار السريع',
      'bus_code': 'BUS-88',
      'created_at': '2026-09-04T07:15:00',
    },
    {
      'id': 102,
      'type': 'behavioral',
      'status': 'resolved',
      'severity': 'medium',
      'description': 'مشادة كلامية بين طالبين داخل الحافلة',
      'bus_code': 'BUS-14',
      'student_names': ['سالم اليعقوبي', 'مازن الحارثي'],
      'created_at': '2026-09-04T07:30:00',
    },
    {
      'id': 103,
      'type': 'health',
      'status': 'pending',
      'severity': 'medium',
      'description': 'شعور طالب بدوار وغثيان مفاجئ',
      'bus_code': 'BUS-05',
      'created_at': '2026-09-04T07:45:00',
    },
    {
      'id': 104,
      'type': 'technical',
      'status': 'resolved',
      'severity': 'low',
      'description': 'تكييف الحافلة لا يعمل بكفاءة',
      'bus_code': 'BUS-21',
      'created_at': '2026-09-04T08:00:00',
    },
    {
      'id': 105,
      'type': 'traffic',
      'status': 'pending',
      'severity': 'high',
      'description': 'حادث سير خفيف على الطريق الدائري',
      'bus_code': 'BUS-33',
      'created_at': '2026-09-04T08:15:00',
    },
  ];

  group('SosAlertsScreen Comprehensive Tests', () {
    testWidgets('1. Shows empty state when no incidents exist', (tester) async {
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

      expect(find.text(l10n.incidentsAndEmergencies), findsWidgets);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text(l10n.noResultsFound), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('2. Displays active emergency banner when critical pending incident exists', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': sampleIncidents}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Emergency banner should be visible
      expect(find.text(l10n.activeEmergency), findsOneWidget);
      expect(find.textContaining('BUS-88'), findsWidgets);
      expect(find.text(l10n.respond), findsOneWidget);

      // Tap respond button
      await tester.tap(find.text(l10n.respond));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Renders various incident types and handles status labels', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': sampleIncidents}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check all incident descriptions
      expect(find.text('عطل كهربائي وتوقف الحافلة في المسار السريع'), findsOneWidget);
      expect(find.text('مشادة كلامية بين طالبين داخل الحافلة'), findsOneWidget);
      expect(find.text('شعور طالب بدوار وغثيان مفاجئ'), findsOneWidget);
      expect(find.text('تكييف الحافلة لا يعمل بكفاءة'), findsOneWidget);
      expect(find.text('حادث سير خفيف على الطريق الدائري'), findsOneWidget);

      // Verify pending & resolved badges
      expect(find.text(l10n.pending), findsWidgets);
      expect(find.text(l10n.resolved), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('4. Behavioral incident displays student list dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': sampleIncidents}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find 'عرض الطلاب المعنيين (2)' button
      final studentsBtn = find.textContaining('عرض الطلاب المعنيين (2)');
      expect(studentsBtn, findsOneWidget);

      await tester.tap(studentsBtn);
      await tester.pumpAndSettle();

      // Dialog should show both students
      expect(find.text('سالم اليعقوبي'), findsOneWidget);
      expect(find.text('مازن الحارثي'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text(l10n.close));
      await tester.pumpAndSettle();

      expect(find.text('سالم اليعقوبي'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('5. Opens NewIncidentSheet and validates required inputs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        if (options.path.contains('field/incidents')) {
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': []}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/buses')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1, 'bus_code': 'BUS-01'},
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/students')) {
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

      // Tap add incident trailing button
      final addBtn = find.byIcon(Icons.notification_add_rounded);
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Bottom sheet is open
      expect(find.text(l10n.newIncident), findsOneWidget);
      expect(find.text(l10n.sendUrgentReport), findsOneWidget);

      // Try submitting with empty description
      await tester.tap(find.text(l10n.sendUrgentReport));
      await tester.pump();
      expect(find.text(l10n.pleaseDescribeIncident), findsOneWidget);

      // Clear snackbar
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('6. NewIncidentSheet selects behavioral type, selects student, and submits successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool incidentSubmitted = false;

      adapter.handler = (options) {
        if (options.method == 'POST' && options.path.contains('field/incidents')) {
          incidentSubmitted = true;
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': {'id': 201}}),
            201,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/incidents')) {
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': []}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/buses')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1, 'bus_code': 'BUS-01'},
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/students')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 10, 'name': 'فيصل المعمري', 'uuid': 'STD-001'},
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

      await tester.tap(find.byIcon(Icons.notification_add_rounded));
      await tester.pumpAndSettle();

      // Tap 'سلوكي' type chip
      await tester.tap(find.text('سلوكي'));
      await tester.pumpAndSettle();

      // Enter description
      await tester.enterText(find.byType(TextField), 'مخالفة سلوكية داخل الحافلة');
      await tester.pump();

      // Open student selector
      await tester.tap(find.text('اختر الطلاب المعنيين بالبلاغ...'));
      await tester.pumpAndSettle();

      // Select student checkbox
      expect(find.text('فيصل المعمري'), findsOneWidget);
      await tester.tap(find.text('فيصل المعمري'));
      await tester.pumpAndSettle();

      // Confirm selection
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();

      expect(find.text('تم اختيار 1 طالب(ة)'), findsOneWidget);

      // Submit
      await tester.tap(find.text(l10n.sendUrgentReport));
      await tester.pumpAndSettle();

      expect(incidentSubmitted, isTrue);
      expect(find.text(l10n.incidentReportedSuccessfully), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('7. Pull to refresh triggers incident reload', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int loadCount = 0;
      adapter.handler = (options) {
        if (options.path.contains('field/incidents')) {
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

      expect(loadCount, 1);

      // Trigger refresh via RefreshIndicator
      final refreshFinder = find.byType(RefreshIndicator);
      unawaited(tester.widget<RefreshIndicator>(refreshFinder).onRefresh());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(loadCount, greaterThanOrEqualTo(2));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('8. Renders cleanly in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': sampleIncidents}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget(theme: AppTheme.dark));
      await tester.pumpAndSettle();

      expect(find.text(l10n.incidentsAndEmergencies), findsWidgets);
      expect(find.text('عطل كهربائي وتوقف الحافلة في المسار السريع'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
