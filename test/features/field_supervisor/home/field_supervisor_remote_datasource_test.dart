import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/data/field_supervisor_remote_datasource.dart';

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
      jsonEncode({'success': true, 'data': {}}),
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

  setUp(() {
    adapter = _FakeHttpAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://test.msaratwasel.com/api/'));
    dio.httpClientAdapter = adapter;
    ApiClient.testDio = dio;
  });

  tearDown(() {
    ApiClient.testDio = null;
  });

  group('FieldSupervisorRemoteDataSource Exhaustive Suite', () {
    test('1. getDashboardStats success and fallback branches', () async {
      // 200 success
      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'active_buses': 12,
                'active_drivers': 10,
                'active_trips': 8,
              }
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );

      final stats = await FieldSupervisorRemoteDataSource.getDashboardStats();
      expect(stats['active_buses'], 12);
      expect(stats['active_drivers'], 10);
      expect(stats['active_trips'], 8);

      // non-200 failure
      adapter.handler = (options) => ResponseBody.fromString('Error', 500);
      final failedStats = await FieldSupervisorRemoteDataSource.getDashboardStats();
      expect(failedStats['active_buses'], 0);
      expect(failedStats['active_drivers'], 0);
      expect(failedStats['active_trips'], 0);

      // exception thrown
      adapter.handler = (options) => throw DioException(requestOptions: options);
      final exStats = await FieldSupervisorRemoteDataSource.getDashboardStats();
      expect(exStats['active_buses'], 0);
    });

    test('2. getBuses and getStaff success and error branches', () async {
      // getBuses success
      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1, 'code': 'BUS-01'}
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );

      final buses = await FieldSupervisorRemoteDataSource.getBuses();
      expect(buses.length, 1);
      expect(buses.first['code'], 'BUS-01');

      // getBuses exception
      adapter.handler = (options) => throw Exception('Network issue');
      expect(await FieldSupervisorRemoteDataSource.getBuses(), isEmpty);

      // getStaff success
      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'drivers': [{'id': 1, 'name': 'سالم'}],
                'supervisors': [{'id': 2, 'name': 'نورة'}],
              }
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );

      final staff = await FieldSupervisorRemoteDataSource.getStaff();
      expect(staff['drivers']!.length, 1);
      expect(staff['supervisors']!.length, 1);

      // getStaff error
      adapter.handler = (options) => ResponseBody.fromString('Bad request', 400);
      final emptyStaff = await FieldSupervisorRemoteDataSource.getStaff();
      expect(emptyStaff['drivers'], isEmpty);
      expect(emptyStaff['supervisors'], isEmpty);
    });

    test('3. getInspectionItems success and error branches', () async {
      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1, 'title': 'فحص الإطارات'},
                {'id': 2, 'title': 'حزام الأمان'},
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );

      final items = await FieldSupervisorRemoteDataSource.getInspectionItems();
      expect(items.length, 2);

      adapter.handler = (options) => throw DioException(requestOptions: options);
      expect(await FieldSupervisorRemoteDataSource.getInspectionItems(), isEmpty);
    });

    test('4. submitInspection with and without photos', () async {
      // Without photos
      adapter.handler = (options) {
        expect(options.data, isA<Map<String, dynamic>>());
        final data = options.data as Map<String, dynamic>;
        expect(data['bus_id'], 10);
        expect(data['overall_status'], 'pass');
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'id': 99, 'status': 'completed'}
          }),
          201,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final res1 = await FieldSupervisorRemoteDataSource.submitInspection(
        busId: 10,
        overallStatus: 'pass',
        results: [
          {'item_id': 1, 'is_passed': true, 'notes': 'سليم'},
        ],
        notes: 'ملاحظة عامة',
      );
      expect(res1?['id'], 99);

      // Non-201 response
      adapter.handler = (options) => ResponseBody.fromString('Invalid', 422);
      final resFail = await FieldSupervisorRemoteDataSource.submitInspection(
        busId: 10,
        overallStatus: 'fail',
        results: [],
      );
      expect(resFail, isNull);

      // With photos (FormData)
      final tempDir = Directory.systemTemp.createTempSync();
      final testFile = File('${tempDir.path}/test_photo.jpg')..writeAsStringSync('fake_image_bytes');

      adapter.handler = (options) {
        expect(options.data, isA<FormData>());
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'id': 100, 'has_photos': true}
          }),
          201,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final resPhotos = await FieldSupervisorRemoteDataSource.submitInspection(
        busId: 10,
        overallStatus: 'pass',
        results: [
          {'item_id': 2, 'is_passed': null, 'notes': null},
        ],
        photos: [testFile],
      );
      expect(resPhotos?['id'], 100);

      // Exception branch
      adapter.handler = (options) => throw Exception('Upload error');
      final resEx = await FieldSupervisorRemoteDataSource.submitInspection(
        busId: 10,
        overallStatus: 'pass',
        results: [],
        photos: [testFile],
      );
      expect(resEx, isNull);

      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('5. reportIncident with all parameters, studentIds, and photos', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final photoFile = File('${tempDir.path}/incident.jpg')..writeAsStringSync('dummy_photo');

      adapter.handler = (options) {
        expect(options.data, isA<FormData>());
        final formData = options.data as FormData;
        expect(formData.fields.any((f) => f.key == 'bus_id' && f.value == '5'), isTrue);
        expect(formData.fields.any((f) => f.key == 'type' && f.value == 'accident'), isTrue);
        expect(formData.fields.any((f) => f.key == 'severity' && f.value == 'high'), isTrue);
        expect(formData.fields.any((f) => f.key == 'location_lat'), isTrue);
        expect(formData.fields.any((f) => f.key == 'location_lng'), isTrue);
        expect(formData.fields.any((f) => f.key == 'student_ids[0]' && f.value == '101'), isTrue);
        expect(formData.files.any((f) => f.key == 'photos[0]'), isTrue);

        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'incident_id': 888, 'status': 'reported'}
          }),
          201,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final incident = await FieldSupervisorRemoteDataSource.reportIncident(
        busId: 5,
        type: 'accident',
        severity: 'high',
        description: 'حادث مروري بسيط',
        locationLat: 23.5880,
        locationLng: 58.3829,
        studentIds: [101, 102],
        photos: [photoFile],
      );

      expect(incident?['incident_id'], 888);

      // Non-201 error
      adapter.handler = (options) => ResponseBody.fromString('Server error', 500);
      final failedIncident = await FieldSupervisorRemoteDataSource.reportIncident(
        type: 'sos',
        severity: 'critical',
        description: 'طوارئ',
      );
      expect(failedIncident, isNull);

      // Exception
      adapter.handler = (options) => throw Exception('Crash');
      final crashIncident = await FieldSupervisorRemoteDataSource.reportIncident(
        type: 'sos',
        severity: 'critical',
        description: 'طوارئ',
      );
      expect(crashIncident, isNull);

      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('6. submitViolation success, failure, and exception', () async {
      adapter.handler = (options) {
        final data = options.data as Map<String, dynamic>;
        expect(data['bus_id'], 15);
        expect(data['type'], 'speeding');
        expect(data['description'], 'تجاوز السرعة القانونية');
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'violation_id': 55}
          }),
          201,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final violation = await FieldSupervisorRemoteDataSource.submitViolation(
        busId: 15,
        type: 'speeding',
        description: 'تجاوز السرعة القانونية',
      );
      expect(violation?['violation_id'], 55);

      adapter.handler = (options) => ResponseBody.fromString('Forbidden', 403);
      expect(
        await FieldSupervisorRemoteDataSource.submitViolation(
          busId: 15,
          type: 'speeding',
          description: 'تجاوز السرعة القانونية',
        ),
        isNull,
      );

      adapter.handler = (options) => throw DioException(requestOptions: options);
      expect(
        await FieldSupervisorRemoteDataSource.submitViolation(
          busId: 15,
          type: 'speeding',
          description: 'تجاوز السرعة القانونية',
        ),
        isNull,
      );
    });

    test('7. getIncidents, getInspections, getFieldTrips, getDashboardReport', () async {
      // 200 Responses
      adapter.handler = (options) {
        if (options.path.contains('incidents')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [{'id': 1, 'title': 'حادث'}]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('inspections')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [{'id': 2, 'title': 'فحص شهري'}]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field-trips')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [{'id': 3, 'destination': 'المتحف الوطني'}]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('report')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {'total_trips': 45, 'on_time_rate': 95}
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      expect((await FieldSupervisorRemoteDataSource.getIncidents()).length, 1);
      expect((await FieldSupervisorRemoteDataSource.getInspections()).length, 1);
      expect((await FieldSupervisorRemoteDataSource.getFieldTrips()).length, 1);
      final report = await FieldSupervisorRemoteDataSource.getDashboardReport();
      expect(report['total_trips'], 45);

      // Failure / Exception cases
      adapter.handler = (options) => throw Exception('Fetch failed');
      expect(await FieldSupervisorRemoteDataSource.getIncidents(), isEmpty);
      expect(await FieldSupervisorRemoteDataSource.getInspections(), isEmpty);
      expect(await FieldSupervisorRemoteDataSource.getFieldTrips(), isEmpty);
      expect(await FieldSupervisorRemoteDataSource.getDashboardReport(), isEmpty);
    });

    test('8. getDelays, storeDelay, and getStudents', () async {
      adapter.handler = (options) {
        if (options.path.contains('delays')) {
          if (options.method == 'GET') {
            return ResponseBody.fromString(
              jsonEncode({
                'success': true,
                'data': [
                  {'id': 1, 'type': 'traffic', 'duration': 15}
                ]
              }),
              200,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          } else if (options.method == 'POST') {
            return ResponseBody.fromString(
              jsonEncode({
                'success': true,
                'data': {'delay_id': 77, 'saved': true}
              }),
              201,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
        }
        if (options.path.contains('students')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 201, 'name': 'أحمد بن خالد'}
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      final delays = await FieldSupervisorRemoteDataSource.getDelays(type: 'traffic');
      expect(delays.length, 1);
      expect(delays.first['type'], 'traffic');

      final delaysNoFilter = await FieldSupervisorRemoteDataSource.getDelays();
      expect(delaysNoFilter.length, 1);

      final savedDelay = await FieldSupervisorRemoteDataSource.storeDelay(
        type: 'student_late',
        studentId: 201,
        busId: 5,
        durationMinutes: 10,
        reason: 'تأخر في الخروج',
        notes: 'تم إشعار ولي الأمر',
      );
      expect(savedDelay?['delay_id'], 77);

      final studentsSearch = await FieldSupervisorRemoteDataSource.getStudents(search: 'أحمد');
      expect(studentsSearch.length, 1);

      final studentsNoSearch = await FieldSupervisorRemoteDataSource.getStudents();
      expect(studentsNoSearch.length, 1);

      // Exception branches
      adapter.handler = (options) => throw Exception('Timeout');
      expect(await FieldSupervisorRemoteDataSource.getDelays(), isEmpty);
      expect(
        await FieldSupervisorRemoteDataSource.storeDelay(
          type: 'traffic',
          durationMinutes: 5,
        ),
        isNull,
      );
      expect(await FieldSupervisorRemoteDataSource.getStudents(), isEmpty);
    });
  });
}
