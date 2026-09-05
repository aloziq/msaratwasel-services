import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/driver/home/data/repositories/home_repository_impl.dart';
import 'package:msaratwasel_services/features/driver/trip/data/repositories/trip_repository_impl.dart';

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
      jsonEncode({'success': true}),
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
  late Dio testDio;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'USER_BUS_ID': '7',
      'USER_ID': '10',
    });
    prefs = await SharedPreferences.getInstance();
    if (GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.unregister<SharedPreferences>();
    }
    GetIt.I.registerSingleton<SharedPreferences>(prefs);

    adapter = _FakeHttpAdapter();
    testDio = Dio(BaseOptions(baseUrl: 'https://api.test.com/'));
    testDio.httpClientAdapter = adapter;
    ApiClient.testDio = testDio;
  });

  tearDown(() {
    ApiClient.testDio = null;
  });

  group('HomeRepositoryImpl - Full API Integration', () {
    test('1. getCurrentTripStatus successfully parses bus info and counts', () async {
      adapter.handler = (options) {
        if (options.path.contains('bus/7/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_id': 'trip_99',
                'trip_status': 'in_progress',
                'has_active_trip': true,
                'departure_time': '07:15 AM',
              },
              'total_count': 15,
              'passengers': [],
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      final repo = HomeRepositoryImpl();
      final status = await repo.getCurrentTripStatus();

      expect(status.id, 'trip_99');
      expect(status.departureTime, '07:15 AM');
      expect(status.totalStudents, 15);
      expect(status.isStarted, isTrue);
      expect(status.isCompleted, isFalse);
    });

    test('2. getCurrentTripStatus falls back to auth/user if USER_BUS_ID not in prefs', () async {
      await prefs.remove('USER_BUS_ID');

      adapter.handler = (options) {
        if (options.path.contains('auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'bus_id': 14}
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('bus/14/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_id': 'trip_14',
                'trip_status': 'idle',
                'has_active_trip': false,
              },
              'total_count': 8,
              'passengers': [],
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      final repo = HomeRepositoryImpl();
      final status = await repo.getCurrentTripStatus();

      expect(status.id, 'trip_14');
      expect(status.isStarted, isFalse);
      expect(status.isCompleted, isTrue);
      expect(prefs.getString('USER_BUS_ID'), '14');
    });

    test('3. getCurrentTripStatus throws when no bus assigned anywhere', () async {
      await prefs.remove('USER_BUS_ID');
      adapter.handler = (options) {
        if (options.path.contains('auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({'data': {'bus_id': null}}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      final repo = HomeRepositoryImpl();
      expect(
        () => repo.getCurrentTripStatus(),
        throwsA(predicate((e) => e.toString().contains('No bus assigned'))),
      );
    });

    test('4. getMyTrips parses list of trips from driver/my-trips', () async {
      adapter.handler = (options) {
        if (options.path.contains('driver/my-trips')) {
          return ResponseBody.fromString(
            jsonEncode({
              'trips': [
                {
                  'id': 1,
                  'name': 'رحلة الصباح',
                  'status': 'in_progress',
                  'departure_time': '06:45 AM',
                  'total_students': 20,
                  'type': 'morning',
                },
                {
                  'id': 2,
                  'name': 'رحلة المساء',
                  'status': 'completed',
                  'departure_time': '01:30 PM',
                  'total_students': 20,
                  'type': 'afternoon',
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      final repo = HomeRepositoryImpl();
      final trips = await repo.getMyTrips();

      expect(trips.length, 2);
      expect(trips[0].id, '1');
      expect(trips[0].status, 'in_progress');
      expect(trips[1].status, 'completed');
    });

    test('5. startTrip and confirmTrip send correct POST requests', () async {
      final paths = <String>[];
      final postedData = <dynamic>[];

      adapter.handler = (options) {
        paths.add(options.path);
        postedData.add(options.data);
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final repo = HomeRepositoryImpl();
      await repo.startTrip('trip_100');
      expect(paths.any((p) => p.contains('bus/7/start-trip')), isTrue);

      await repo.confirmTrip('trip_100');
      expect(paths.any((p) => p.contains('bus/7/confirm-trip')), isTrue);
      expect(postedData.any((d) => d is Map && d['trip_id'] == 'trip_100'), isTrue);
    });

    test('6. startTrip and confirmTrip handle DioException', () async {
      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({'message': 'لا يمكن بدء الرحلة حالياً'}),
            400,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );

      final repo = HomeRepositoryImpl();
      expect(
        () => repo.startTrip('trip_1'),
        throwsA(predicate((e) => e.toString().contains('لا يمكن بدء الرحلة حالياً'))),
      );

      expect(
        () => repo.confirmTrip('trip_1'),
        throwsA(predicate((e) => e.toString().contains('لا يمكن بدء الرحلة حالياً'))),
      );
    });
  });

  group('TripRepositoryImpl - Full API Integration', () {
    test('7. checkTripReadiness success (200) and error branches', () async {
      await prefs.setString('USER_BUS_ID', '7');

      // 1. Success
      adapter.handler = (options) {
        if (options.path.contains('check-trip-readiness')) {
          return ResponseBody.fromString(
            jsonEncode({'ready': true}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      final repo = TripRepositoryImpl();
      await repo.checkTripReadiness();

      // 2. Server message error
      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({'message': 'الطلاب لم ينزلوا بعد'}),
            422,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );

      await expectLater(
        repo.checkTripReadiness(),
        throwsA(predicate((e) => e.toString().contains('الطلاب لم ينزلوا بعد'))),
      );

      // 3. 404 route not found error
      adapter.handler = (options) => ResponseBody.fromString(
            'Not Found',
            404,
            headers: {Headers.contentTypeHeader: [Headers.textPlainContentType]},
          );

      await expectLater(
        repo.checkTripReadiness(),
        throwsA(predicate((e) => e.toString().contains('المسار غير موجود على السيرفر'))),
      );
    });

    test('8. updateStudentStatus posts to mark-boarded and mark-dropped', () async {
      final paths = <String>[];
      final postedData = <dynamic>[];

      adapter.handler = (options) {
        paths.add(options.path);
        postedData.add(options.data);
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final repo = TripRepositoryImpl();

      // Boarded
      await repo.updateStudentStatus('st_1', isBoarded: true);
      expect(paths.any((p) => p.contains('/bus/7/mark-boarded')), isTrue);
      expect(postedData.any((d) => d is Map && d['student_id'] == 'st_1'), isTrue);

      // Dropped off
      await repo.updateStudentStatus('st_2', isDroppedOff: true);
      expect(paths.any((p) => p.contains('/bus/7/mark-dropped')), isTrue);
      expect(postedData.any((d) => d is Map && d['student_id'] == 'st_2'), isTrue);
    });

    test('9. endTrip uploads video and QR data via multipart FormData', () async {
      final tempDir = Directory.systemTemp.createTempSync('trip_verify');
      final tempFile = File('${tempDir.path}/verify.mp4');
      tempFile.writeAsBytesSync([10, 20, 30, 40]);

      try {
        bool endTripCalled = false;
        adapter.handler = (options) {
          if (options.path.contains('/bus/7/end-trip')) {
            endTripCalled = true;
            expect(options.data, isA<FormData>());
            return ResponseBody.fromString(
              jsonEncode({'success': true, 'message': 'تم إنهاء الرحلة بنجاح'}),
              200,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
          return ResponseBody.fromString('', 404);
        };

        final repo = TripRepositoryImpl();
        await repo.endTrip(
          videoPath: tempFile.path,
          startQrData: 'QR_START_123',
          endQrData: 'QR_END_456',
        );

        expect(endTripCalled, isTrue);

        // DioException failure
        adapter.handler = (options) => ResponseBody.fromString(
              jsonEncode({'message': 'فيديو التحقق غير صالح'}),
              422,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );

        expect(
          () => repo.endTrip(
            videoPath: tempFile.path,
            startQrData: 'QR_START_123',
            endQrData: 'QR_END_456',
          ),
          throwsA(predicate((e) => e.toString().contains('فيديو التحقق غير صالح'))),
        );
      } finally {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });
  });
}
