import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/field_supervisor/delays/presentation/screens/delays_screen.dart';
import 'package:msaratwasel_services/features/field_supervisor/field_trips/presentation/screens/field_trips_screen.dart';
import 'package:msaratwasel_services/features/field_supervisor/incidents/presentation/screens/sos_alerts_screen.dart';
import 'package:msaratwasel_services/features/field_supervisor/inspection/presentation/screens/field_inspection_screen.dart';
import 'package:msaratwasel_services/features/field_supervisor/staff/presentation/screens/drivers_list_screen.dart';
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

  late _FakeHttpAdapter adapter;
  late Dio dio;
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    adapter = _FakeHttpAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://test.msaratwasel.com/api/'));
    dio.httpClientAdapter = adapter;
    ApiClient.testDio = dio;
  });

  tearDown(() {
    ApiClient.testDio = null;
  });

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  group('Field Supervisor Screens UI Suite', () {
    testWidgets('1. FieldInspectionScreen loads and renders inspections and new inspection form', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      adapter.handler = (options) {
        if (options.path.contains('field/inspections')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'bus_id': 101,
                  'bus_code': 'BUS-01',
                  'created_at': '2026-09-04T08:30:00',
                  'overall_status': 'pass',
                  'total_items': 12,
                  'passed_items': 12,
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/buses')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 101, 'code': 'BUS-01'}
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/inspection-items')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1, 'name': 'سلامة الإطارات', 'category': 'safety'},
                {'id': 2, 'name': 'أحزمة الأمان', 'category': 'safety'},
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

      await tester.pumpWidget(wrapWithMaterial(const FieldInspectionScreen()));
      await tester.pumpAndSettle();

      // Check header and list
      expect(find.text(l10n.fieldInspection), findsWidgets);
      expect(find.text('BUS-01'), findsOneWidget);
      expect(find.textContaining('12/12'), findsOneWidget);
    });

    testWidgets('2. DriversListScreen loads drivers and supervisors tabs and searches', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      adapter.handler = (options) {
        if (options.path.contains('field/staff')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'drivers': [
                  {
                    'name': 'محمود البلوشي',
                    'is_active': true,
                    'bus_code': 'BUS-11',
                    'phone': '96891112222',
                  },
                ],
                'supervisors': [
                  {
                    'name': 'سعاد الوهيبية',
                    'is_active': true,
                    'bus_code': 'BUS-11',
                    'phone': '96893334444',
                  },
                ],
              }
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

      await tester.pumpWidget(wrapWithMaterial(const DriversListScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n.driversAndSupervisors), findsWidgets);
      expect(find.text('محمود البلوشي'), findsOneWidget);
      expect(find.textContaining('BUS-11'), findsOneWidget);

      // Switch tab to supervisors
      final tabs = find.byType(Tab);
      expect(tabs, findsNWidgets(2));
      await tester.tap(tabs.last);
      await tester.pumpAndSettle();

      expect(find.text('سعاد الوهيبية'), findsOneWidget);
    });

    testWidgets('3. FieldTripsScreen loads and renders scheduled trips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      adapter.handler = (options) {
        if (options.path.contains('field/field-trips')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'trip_name': 'رحلة المتحف الوطني',
                  'trip_date': '2026-09-15T09:00:00',
                  'school': 'مدرسة مسقط',
                  'bus_code': 'BUS-20',
                  'status': 'approved',
                  'destination': 'المتحف الوطني',
                  'students': 30,
                },
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

      await tester.pumpWidget(wrapWithMaterial(const FieldTripsScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n.fieldTrips), findsWidgets);
      expect(find.text('رحلة المتحف الوطني'), findsOneWidget);
      expect(find.textContaining('المتحف الوطني'), findsWidgets);
      expect(find.textContaining('BUS-20'), findsOneWidget);
    });

    testWidgets('4. DelaysScreen loads student/bus delays and toggles tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      adapter.handler = (options) {
        if (options.path.contains('field/delays')) {
          final isStudent = options.queryParameters['type'] == 'student';
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': isStudent
                  ? [
                      {
                        'id': 1,
                        'student_name': 'يوسف المحمودي',
                        'bus_code': 'BUS-05',
                        'duration_minutes': 15,
                        'created_at': '2026-09-04T07:10:00',
                        'reason': 'استيقاظ متأخر',
                      }
                    ]
                  : [
                      {
                        'id': 2,
                        'bus_code': 'BUS-12',
                        'duration_minutes': 25,
                        'created_at': '2026-09-04T07:30:00',
                        'reason': 'ازدحام مروري',
                      }
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

      await tester.pumpWidget(wrapWithMaterial(const DelaysScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n.registerDelays), findsWidgets);
      expect(find.text('يوسف المحمودي'), findsOneWidget);
      expect(find.textContaining('15'), findsWidgets);

      // Switch tab to bus delays
      final tabs = find.byType(Tab);
      expect(tabs, findsNWidgets(2));
      await tester.tap(tabs.last);
      await tester.pumpAndSettle();

      expect(find.text('BUS-12'), findsOneWidget);
      expect(find.textContaining('25'), findsWidgets);
    });

    testWidgets('5. SosAlertsScreen loads incidents, renders emergency banner and cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      adapter.handler = (options) {
        if (options.path.contains('field/incidents')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 501,
                  'type': 'sos',
                  'status': 'pending',
                  'severity': 'critical',
                  'title': 'عطل مفاجئ في المحرك',
                  'description': 'توقف الحافلة على الطريق السريع',
                  'bus_code': 'BUS-99',
                  'created_at': '2026-09-04T08:00:00',
                },
                {
                  'id': 502,
                  'type': 'behavioral',
                  'status': 'resolved',
                  'severity': 'low',
                  'title': 'سلوك غير منضبط',
                  'description': 'مشاجرة خفيفة بين طالبين',
                  'bus_code': 'BUS-02',
                  'created_at': '2026-09-04T07:45:00',
                }
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

      await tester.pumpWidget(wrapWithMaterial(const SosAlertsScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n.incidentsAndEmergencies), findsWidgets);
      expect(find.text(l10n.allIncidents), findsOneWidget);
      expect(find.text(l10n.activeEmergency), findsOneWidget);
      expect(find.text('توقف الحافلة على الطريق السريع'), findsOneWidget);
      expect(find.text('مشاجرة خفيفة بين طالبين'), findsOneWidget);
      expect(find.textContaining('BUS-99'), findsWidgets);
    });
  });
}
