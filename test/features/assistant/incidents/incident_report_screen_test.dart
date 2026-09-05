import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/assistant/incidents/presentation/screens/incident_report_screen.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) return handler!(options);
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'passengers': []}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHttpAdapter adapter;
  late Dio dio;
  late SharedPreferences prefs;
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    SharedPreferences.setMockInitialValues({
      'USER_BUS_ID': '5',
      'USER_BUS_CODE': 'BUS-05',
      'USER_DRIVER_NAME': 'سعيد الكعبي',
      'USER_NAME': 'مريم المساعدة',
    });
    prefs = await SharedPreferences.getInstance();

    if (GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.unregister<SharedPreferences>();
    }
    GetIt.I.registerSingleton<SharedPreferences>(prefs);

    adapter = _FakeHttpAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://test.msaratwasel.com/api/'));
    dio.httpClientAdapter = adapter;
    ApiClient.testDio = dio;
  });

  tearDown(() async {
    ApiClient.testDio = null;
    await GetIt.I.reset();
  });

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  group('IncidentReportScreen UI Suite', () {
    testWidgets('1. Loads bus info and displays incident form', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'passengers': [
                {
                  'id': 101,
                  'name': 'محمد سعيد',
                  'uuid': 'u101',
                },
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'passengers': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(wrapWithMaterial(const IncidentReportScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n.incidentReportTitle), findsWidgets);
      expect(find.text('حافلة BUS-05'), findsOneWidget);
      expect(find.text('سعيد الكعبي'), findsOneWidget);
    });

    testWidgets('2. Validates empty description on submit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithMaterial(const IncidentReportScreen()));
      await tester.pumpAndSettle();

      // Find submit button
      final submitBtn = find.text(l10n.sendUrgentReport);
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('يرجى كتابة وصف البلاغ'), findsOneWidget);
    });

    testWidgets('3. Selects technical incident and submits successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool postReceived = false;

      adapter.handler = (options) {
        if (options.path.contains('incidents') || options.method == 'POST') {
          postReceived = true;
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'message': 'تم تسجيل البلاغ'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'passengers': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
              ),
              child: const Text('OpenIncidentScreen'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('OpenIncidentScreen'));
      await tester.pumpAndSettle();

      // Tap on technical incident type (عطل فني)
      final technicalChip = find.text(l10n.incidentTypeTechnical);
      expect(technicalChip, findsOneWidget);
      await tester.tap(technicalChip);
      await tester.pumpAndSettle();

      // Enter description
      final descField = find.byType(TextField).first;
      await tester.enterText(descField, 'تسريب زيت في المحرك');
      await tester.pumpAndSettle();

      // Submit
      final submitBtn = find.text(l10n.sendUrgentReport);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(postReceived, isTrue);
      expect(find.text('تم إرسال البلاغ بنجاح ✅'), findsWidgets);
    });

    testWidgets('4. Opens student selection sheet for behavioral incident', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      adapter.handler = (options) {
        if (options.path.contains('/bus/5/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'passengers': [
                {
                  'id': 101,
                  'name': 'محمد سعيد',
                  'uuid': 'u101',
                },
                {
                  'id': 102,
                  'name': 'خالد أحمد',
                  'uuid': 'u102',
                },
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'passengers': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(wrapWithMaterial(const IncidentReportScreen()));
      await tester.pumpAndSettle();

      // Open student selection sheet (default incident type is behavioral)
      final selectStudentTrigger = find.text('اختر الطلاب المعنيين بالبلاغ...');
      expect(selectStudentTrigger, findsOneWidget);
      await tester.tap(selectStudentTrigger);
      await tester.pumpAndSettle();

      // Verify bottom sheet content
      expect(find.text('اختيار الطلاب المعنيين'), findsOneWidget);
      expect(find.text('محمد سعيد'), findsOneWidget);
      expect(find.text('خالد أحمد'), findsOneWidget);

      // Tap on student checkbox
      await tester.tap(find.text('محمد سعيد'));
      await tester.pumpAndSettle();

      // Close bottom sheet with 'تم'
      final doneBtn = find.text('تم');
      expect(doneBtn, findsOneWidget);
      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Verify bottom sheet closed and selected count is shown on main screen
      expect(find.text('اختيار الطلاب المعنيين'), findsNothing);
      expect(find.text('تم اختيار 1 طلاب'), findsOneWidget);
    });
  });
}
