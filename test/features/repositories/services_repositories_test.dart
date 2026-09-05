import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/driver/maintenance/data/repositories/maintenance_repository_impl.dart';
import 'package:msaratwasel_services/features/driver/home/data/repositories/home_repository_impl.dart';
import 'package:msaratwasel_services/features/driver/trip/data/repositories/trip_repository_impl.dart';
import 'package:msaratwasel_services/features/assistant/core/data/repositories/assistant_repository_impl.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiAdapter mockAdapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'USER_BUS_ID': '12',
      'USER_TOKEN': 'jwt_test_token',
    });
    final prefs = await SharedPreferences.getInstance();
    if (GetIt.instance.isRegistered<SharedPreferences>()) {
      GetIt.instance.unregister<SharedPreferences>();
    }
    GetIt.instance.registerSingleton<SharedPreferences>(prefs);

    mockAdapter = FakeApiAdapter();
    final testDio = Dio(
      BaseOptions(
        baseUrl: 'https://test.wasel.com/api/',
        connectTimeout: const Duration(seconds: 5),
      ),
    );
    testDio.httpClientAdapter = mockAdapter;
    ApiClient.testDio = testDio;
  });

  tearDown(() {
    ApiClient.testDio = null;
  });

  group('Services Repositories Real Implementation Suite', () {
    test('1. MaintenanceRepositoryImpl.getExpenses parses paginated expenses', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('/driver/expenses')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {
                  'id': 1,
                  'bus_id': 12,
                  'type': 'maintenance',
                  'amount': 350.0,
                  'date': '2026-09-01T08:00:00.000',
                  'extra_info': 'Oil change',
                  'receipt_photo': null,
                }
              ]
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = MaintenanceRepositoryImpl();
      final expenses = await repo.getExpenses(page: 1);
      expect(expenses.length, 1);
      expect(expenses.first.amount, 350.0);
      expect(expenses.first.extraInfo, 'Oil change');
    });

    test('2. MaintenanceRepositoryImpl.getExpenses throws Exception on 500 server error', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Server database unreachable'}),
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final repo = MaintenanceRepositoryImpl();
      expect(() => repo.getExpenses(), throwsException);
    });

    test('3. MaintenanceRepositoryImpl.submitFuelRefill posts fuel expense data', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('/driver/expenses') && options.method == 'POST') {
          return ResponseBody.fromString(
            jsonEncode({'status': 'success'}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = MaintenanceRepositoryImpl();
      await expectLater(
        repo.submitFuelRefill(
          amount: 150.0,
          odometer: 85000,
          date: DateTime(2026, 9, 4),
        ),
        completes,
      );
    });

    test('4. HomeRepositoryImpl.getCurrentTripStatus parses passengers & active trip info', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('bus/12/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_status': 'in_progress',
                'has_active_trip': true,
                'trip_id': 'tr-50',
                'departure_time': '06:45 AM',
              },
              'total_count': 15,
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = HomeRepositoryImpl();
      final status = await repo.getCurrentTripStatus();
      expect(status.id, 'tr-50');
      expect(status.isStarted, isTrue);
      expect(status.totalStudents, 15);
    });

    test('5. HomeRepositoryImpl.getMyTrips parses trip list', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('driver/my-trips')) {
          return ResponseBody.fromString(
            jsonEncode({
              'trips': [
                {
                  'id': 100,
                  'type': 'forth',
                  'status': 'finished',
                  'departure_time': '06:30 AM',
                  'total_students': 18,
                }
              ]
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = HomeRepositoryImpl();
      final trips = await repo.getMyTrips();
      expect(trips.length, 1);
      expect(trips.first.id, '100');
    });

    test('6. TripRepositoryImpl.checkTripReadiness succeeds on 200 and fails on 404', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('/bus/12/check-trip-readiness')) {
          return ResponseBody.fromString(
            jsonEncode({'status': 'ready'}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = TripRepositoryImpl();
      await expectLater(repo.checkTripReadiness(), completes);

      // Now set to 404
      mockAdapter.handler = (options) => ResponseBody.fromString(
        jsonEncode({'message': 'Endpoint not found'}),
        404,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
      expect(() => repo.checkTripReadiness(), throwsException);
    });

    test('7. TripRepositoryImpl.updateStudentStatus calls mark-boarded and mark-dropped', () async {
      String? lastEndpoint;
      mockAdapter.handler = (options) {
        lastEndpoint = options.path;
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final repo = TripRepositoryImpl();
      await repo.updateStudentStatus('st-10', isBoarded: true);
      expect(lastEndpoint, contains('mark-boarded'));

      await repo.updateStudentStatus('st-10', isDroppedOff: true);
      expect(lastEndpoint, contains('mark-dropped'));
    });

    test('8. AssistantRepositoryImpl.getActiveTrip returns Right with BusTripEntity', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('/bus/12/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'passengers': [
                {
                  'id': 1,
                  'name_ar': 'علي',
                  'grade': 'الثاني',
                  'parentName': 'محمد',
                  'parentPhone': '0500000',
                  'status': 'onBus',
                }
              ],
              'bus': {
                'trip_id': 'trip-12',
                'bus_number': 'B-12',
                'trip_type': 'morning',
              },
              'driver': {
                'name': 'خالد السائق',
                'phone': '0555555555',
              }
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = AssistantRepositoryImpl();
      final result = await repo.getActiveTrip();
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Expected right but got error: $error'),
        (trip) {
          expect(trip.id, 'trip-12');
          expect(trip.busNumber, 'B-12');
          expect(trip.students.length, 1);
          expect(trip.students.first.status, BusStudentStatus.onBus);
        },
      );
    });

    test('9. AssistantRepositoryImpl.getActiveTrip returns Left when no bus assigned', () async {
      final prefs = GetIt.instance<SharedPreferences>();
      await prefs.remove('USER_BUS_ID');

      final repo = AssistantRepositoryImpl();
      final result = await repo.getActiveTrip();
      expect(result.isLeft(), isTrue);
    });
  });
}

class FakeApiAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
