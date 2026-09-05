import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/features/driver/home/data/repositories/home_repository_impl.dart';
import 'package:msaratwasel_services/features/driver/home/domain/entities/trip_status.dart';
import 'package:msaratwasel_services/features/driver/maintenance/data/repositories/maintenance_repository_impl.dart';
import 'package:msaratwasel_services/features/driver/maintenance/data/models/bus_expense_model.dart';
import 'package:msaratwasel_services/features/driver/trip/data/repositories/trip_repository_impl.dart';
import 'package:msaratwasel_services/features/driver/trip/data/datasources/trip_history_remote_datasource.dart';
import 'package:msaratwasel_services/features/driver/trip/domain/repositories/trip_history_repository.dart';
import 'package:msaratwasel_services/features/assistant/core/data/repositories/assistant_repository_impl.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
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
      jsonEncode({'data': {}, 'status': 'success'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHttpAdapter adapter;
  late Dio dio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'USER_BUS_ID': '15',
      'USER_ID': '7',
    });
    final prefs = await SharedPreferences.getInstance();
    if (GetIt.instance.isRegistered<SharedPreferences>()) {
      GetIt.instance.unregister<SharedPreferences>();
    }
    GetIt.instance.registerSingleton<SharedPreferences>(prefs);

    adapter = _FakeHttpAdapter();
    dio = Dio(
      BaseOptions(baseUrl: 'https://test.msaratwasel.com/api/'),
    );
    dio.httpClientAdapter = adapter;
    ApiClient.testDio = dio;
  });

  tearDown(() {
    ApiClient.testDio = null;
  });

  group('HomeRepositoryImpl Suite', () {
    late HomeRepositoryImpl repo;

    setUp(() {
      repo = HomeRepositoryImpl();
    });

    test('1. getCurrentTripStatus parses passenger response and maps TripStatus', () async {
      adapter.handler = (options) {
        if (options.path.contains('bus/15/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_id': 'trip_15_morning',
                'departure_time': '06:45 AM',
                'trip_status': 'in_progress',
                'has_active_trip': true,
              },
              'total_count': 22,
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final status = await repo.getCurrentTripStatus();
      expect(status.id, 'trip_15_morning');
      expect(status.departureTime, '06:45 AM');
      expect(status.totalStudents, 22);
      expect(status.isStarted, isTrue);
      expect(status.isCompleted, isFalse);
    });

    test('2. getCurrentTripStatus falls back to API auth/user when local bus_id is absent', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      GetIt.instance.unregister<SharedPreferences>();
      GetIt.instance.registerSingleton<SharedPreferences>(prefs);

      final freshRepo = HomeRepositoryImpl();

      adapter.handler = (options) {
        if (options.path.contains('auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'bus_id': 99},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        if (options.path.contains('bus/99/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {'trip_id': 99, 'trip_status': 'idle', 'has_active_trip': false},
              'total_count': 5,
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final status = await freshRepo.getCurrentTripStatus();
      expect(status.id, '99');
      expect(status.isStarted, isFalse);
      expect(status.isCompleted, isTrue);
    });

    test('3. getMyTrips parses trip array from driver/my-trips', () async {
      adapter.handler = (options) {
        if (options.path.contains('driver/my-trips')) {
          return ResponseBody.fromString(
            jsonEncode({
              'trips': [
                {
                  'id': 't1',
                  'departure_time': '07:00 AM',
                  'total_students': 18,
                  'is_started': true,
                  'is_completed': false,
                },
                {
                  'id': 't2',
                  'departure_time': '01:30 PM',
                  'total_students': 18,
                  'is_started': false,
                  'is_completed': false,
                },
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final trips = await repo.getMyTrips();
      expect(trips.length, 2);
      expect(trips[0].id, 't1');
      expect(trips[1].departureTime, '01:30 PM');
    });

    test('4. confirmTrip posts trip_id to bus/15/confirm-trip', () async {
      bool confirmCalled = false;
      adapter.handler = (options) {
        if (options.path.contains('bus/15/confirm-trip')) {
          confirmCalled = true;
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'message': 'Trip confirmed'}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      await expectLater(repo.confirmTrip('trip_15_morning'), completes);
      expect(confirmCalled, isTrue);
    });

    test('5. confirmTrip throws descriptive exception on API error', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Invalid trip ID'}),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      expect(() => repo.confirmTrip('bad_id'), throwsA(isA<Exception>()));
    });
  });

  group('MaintenanceRepositoryImpl Suite', () {
    late MaintenanceRepositoryImpl repo;

    setUp(() {
      repo = MaintenanceRepositoryImpl();
    });

    test('6. getExpenses parses list of BusExpenseModel', () async {
      adapter.handler = (options) {
        if (options.path.contains('/driver/expenses')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {
                  'id': 1,
                  'bus_id': 15,
                  'type': 'fuel',
                  'amount': 45.5,
                  'date': '2026-09-04T10:00:00.000Z',
                  'extra_info': '124500',
                  'receipt_photo': 'https://example.com/receipt.jpg',
                },
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final expenses = await repo.getExpenses(page: 1);
      expect(expenses.length, 1);
      expect(expenses[0].id, 1);
      expect(expenses[0].type, 'fuel');
      expect(expenses[0].amount, 45.5);
    });

    test('7. submitFuelRefill and submitMaintenanceRequest post form data without photo', () async {
      int postCount = 0;
      adapter.handler = (options) {
        if (options.path.contains('/driver/expenses')) {
          postCount++;
          return ResponseBody.fromString(
            jsonEncode({'success': true}),
            201,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      await expectLater(
        repo.submitFuelRefill(
          amount: 30.0,
          odometer: 110000,
          date: DateTime(2026, 9, 4),
        ),
        completes,
      );

      await expectLater(
        repo.submitMaintenanceRequest(
          description: 'Oil change and filter',
          date: DateTime(2026, 9, 4),
          cost: 25.0,
        ),
        completes,
      );

      expect(postCount, 2);
    });
  });

  group('TripRepositoryImpl Suite', () {
    late TripRepositoryImpl repo;

    setUp(() {
      repo = TripRepositoryImpl();
    });

    test('8. checkTripReadiness completes on 200 and handles 404 or backend errors', () async {
      adapter.handler = (options) {
        if (options.path.contains('/bus/15/check-trip-readiness')) {
          return ResponseBody.fromString(
            jsonEncode({'success': true}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      await expectLater(repo.checkTripReadiness(), completes);

      // 404 scenario
      adapter.handler = (options) {
        return ResponseBody.fromString('Not found', 404);
      };
      expect(() => repo.checkTripReadiness(), throwsA(isA<Exception>()));
    });

    test('9. updateStudentStatus calls mark-boarded or mark-dropped', () async {
      String? lastEndpoint;
      adapter.handler = (options) {
        lastEndpoint = options.path;
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      await repo.updateStudentStatus('st_1', isBoarded: true);
      expect(lastEndpoint, contains('/bus/15/mark-boarded'));

      await repo.updateStudentStatus('st_1', isDroppedOff: true);
      expect(lastEndpoint, contains('/bus/15/mark-dropped'));
    });
  });

  group('TripHistoryRepository & RemoteDataSource Suite', () {
    test('10. RemoteDataSource queries driver/trips-history and Repository wraps Right', () async {
      adapter.handler = (options) {
        if (options.path.contains('driver/trips-history')) {
          return ResponseBody.fromString(
            jsonEncode({
              'trips': [
                {
                  'id': 101,
                  'type': 'morning',
                  'type_label': 'Morning',
                  'status': 'completed',
                  'trip_date': '2026-09-04',
                  'total_students': 14,
                  'departure_time': '07:00 AM',
                  'arrival_time': '08:00 AM',
                }
              ],
              'pagination': {
                'current_page': 1,
                'last_page': 1,
                'total': 1,
              },
              'filters': {
                'start_date': '2026-09-01',
                'end_date': '2026-09-04',
                'status': 'completed',
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final remoteDs = TripHistoryRemoteDataSourceImpl(dio);
      final repo = TripHistoryRepositoryImpl(remoteDs);

      final result = await repo.getTripsHistory(status: 'completed', page: 1);
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right'),
        (response) {
          expect(response.trips.length, 1);
          expect(response.trips[0].id, 101);
          expect(response.trips[0].status, 'completed');
        },
      );
    });

    test('11. TripHistoryRepository returns Left(ServerFailure) on exception', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString('Internal Server Error', 500);
      };

      final remoteDs = TripHistoryRemoteDataSourceImpl(dio);
      final repo = TripHistoryRepositoryImpl(remoteDs);

      final result = await repo.getTripsHistory();
      expect(result.isLeft(), isTrue);
      expect(result.swap().getOrElse(() => const ServerFailure('')), isA<ServerFailure>());
    });
  });

  group('AssistantRepositoryImpl Suite', () {
    late AssistantRepositoryImpl repo;

    setUp(() {
      repo = AssistantRepositoryImpl();
    });

    test('12. getActiveTrip parses bus, passengers, and driver details', () async {
      adapter.handler = (options) {
        if (options.path.contains('/bus/15/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_id': 'trip_asst_15',
                'bus_number': 'Bus-15',
                'suggested_direction': 'to_school',
                'trip_type': 'morning',
                'trip_status': 'active',
                'school_lat': '23.5880',
                'school_lng': '58.3829',
              },
              'driver': {
                'name': 'Salim Al-Harthy',
                'phone': '+96899112233',
                'photo': 'https://example.com/salim.png',
              },
              'passengers': [
                {
                  'id': 1,
                  'name': 'Rashid',
                  'class_name': 'Grade 3A',
                  'status': 'waiting',
                },
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final tripResult = await repo.getActiveTrip();
      expect(tripResult.isRight(), isTrue);

      final studentsResult = await repo.getStudents();
      expect(studentsResult.isRight(), isTrue);
      studentsResult.fold(
        (f) => fail('Expected Right'),
        (students) {
          expect(students.length, 1);
          expect(students[0].name, 'Rashid');
        },
      );
    });

    test('13. confirmTrip and updateStudentStatus invoke endpoints properly', () async {
      final calledEndpoints = <String>[];
      adapter.handler = (options) {
        calledEndpoints.add(options.path);
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final confirmResult = await repo.confirmTrip('trip_asst_15');
      expect(confirmResult.isRight(), isTrue);
      expect(calledEndpoints, contains('/bus/15/confirm-trip'));

      final boardResult = await repo.updateStudentStatus('1', BusStudentStatus.onBus, 'to_school');
      expect(boardResult.isRight(), isTrue);
      expect(calledEndpoints, contains('/bus/15/mark-boarded'));

      final dropResult = await repo.updateStudentStatus('1', BusStudentStatus.atSchool, null);
      expect(dropResult.isRight(), isTrue);
      expect(calledEndpoints, contains('/bus/15/mark-dropped'));

      final absentResult = await repo.updateStudentStatus('1', BusStudentStatus.absent, null);
      expect(absentResult.isRight(), isTrue);
      expect(calledEndpoints, contains('/bus/15/mark-absent'));
    });

    test('14. groupBoard, groupAlight, submitIncidentReport, submitDailyChecklist execute smoothly', () async {
      final calledEndpoints = <String>[];
      adapter.handler = (options) {
        calledEndpoints.add(options.path);
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final gBoardResult = await repo.groupBoard(studentIds: ['1', '2'], direction: 'to_school');
      expect(gBoardResult.isRight(), isTrue);
      expect(calledEndpoints, contains('/bus/15/group-board'));

      final gAlightResult = await repo.groupAlight(studentIds: ['1', '2'], direction: 'to_school');
      expect(gAlightResult.isRight(), isTrue);
      expect(calledEndpoints, contains('/bus/15/group-alight'));

      final incidentResult = await repo.submitIncidentReport(
        studentId: '1',
        type: 'behavioral',
        description: 'Disruptive during boarding',
      );
      expect(incidentResult.isRight(), isTrue);
      expect(calledEndpoints, contains('/field/incidents'));

      final checklistResult = await repo.submitDailyChecklist({'doors_closed': true, 'seatbelts': true});
      expect(checklistResult.isRight(), isTrue);
      expect(calledEndpoints, contains('/field/inspections'));

      expect(await repo.confirmEmptyBus(), equals(const Right(null)));
      expect(await repo.sendAlertToDriver('Wait for student'), equals(const Right(null)));
      expect(await repo.updateBehavioralNote('1', 'Good behavior'), equals(const Right(null)));
    });
  });
}
