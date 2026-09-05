import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/assistant/tracking/domain/entities/bus_position.dart';
import 'package:msaratwasel_services/features/assistant/tracking/presentation/cubit/bus_tracking_cubit.dart';
import 'package:msaratwasel_services/features/assistant/core/data/repositories/assistant_repository_impl.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/data/models/bus_student_model.dart';
import 'package:msaratwasel_services/features/assistant/core/data/models/bus_trip_model.dart';

class FakeConnectivityPlatform extends ConnectivityPlatform {
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;

  void triggerConnectivityChange(List<ConnectivityResult> results) {
    _controller.add(results);
  }

  void dispose() {
    _controller.close();
  }
}

class FakeAssistantDioAdapter implements HttpClientAdapter {
  Map<String, dynamic>? customPassengersResponse;
  Map<String, dynamic>? customLocationResponse;
  int statusCode = 200;
  bool throwOnLocation = false;
  RequestOptions? lastRequestOptions;
  dynamic lastRequestBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    lastRequestBody = options.data;

    final path = options.path;

    if (path.contains('/location')) {
      if (throwOnLocation) {
        throw DioException(
          requestOptions: options,
          error: 'Connection timeout for location',
          type: DioExceptionType.connectionTimeout,
        );
      }
      final data = customLocationResponse ?? {
        'latitude': 23.5895,
        'longitude': 58.3845,
        'speed_kmh': 40.0,
        'target_lat': 23.5920,
        'target_lng': 58.3870,
        'students_on_board': 3,
      };
      return ResponseBody.fromString(
        jsonEncode({'data': data}),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('/passengers')) {
      final data = customPassengersResponse ?? {
        'bus': {
          'trip_id': 'trip-99',
          'bus_number': 'Bus-99',
          'trip_type': 'morning',
          'suggested_direction': 'to_school',
          'trip_status': 'active',
          'school_lat': 23.5880,
          'school_lng': 58.3829,
        },
        'driver': {
          'name': 'سالم السائقي',
          'phone': '91000000',
          'photo': null,
        },
        'passengers': [
          {
            'id': 101,
            'name': 'خالد ناصر',
            'parentName': 'ناصر',
            'parentPhone': '92000000',
            'status': 'waiting',
            'latitude': 23.5910,
            'longitude': 58.3860,
          },
          {
            'id': 102,
            'name': 'مريم أحمد',
            'parentName': 'أحمد',
            'parentPhone': '93000000',
            'status': 'onBus',
            'latitude': 23.5920,
            'longitude': 58.3870,
          }
        ],
      };
      return ResponseBody.fromString(
        jsonEncode(data),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('/confirm-trip') ||
        path.contains('/mark-boarded') ||
        path.contains('/mark-dropped') ||
        path.contains('/mark-absent') ||
        path.contains('/group-alight') ||
        path.contains('/group-board') ||
        path.contains('/field/incidents') ||
        path.contains('/field/inspections')) {
      if (statusCode >= 400) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Operation failed on server'}),
          statusCode,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({'status': 'success', 'message': 'Operation successful'}),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': {}}),
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

  late FakeConnectivityPlatform fakeConnectivity;
  late FakeAssistantDioAdapter fakeDioAdapter;
  late Dio testDio;

  setUp(() {
    fakeConnectivity = FakeConnectivityPlatform();
    ConnectivityPlatform.instance = fakeConnectivity;

    fakeDioAdapter = FakeAssistantDioAdapter();
    testDio = Dio(BaseOptions(baseUrl: 'https://test.api/'));
    testDio.httpClientAdapter = fakeDioAdapter;
    ApiClient.testDio = testDio;

    if (GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.unregister<SharedPreferences>();
    }
  });

  tearDown(() {
    ApiClient.testDio = null;
    fakeConnectivity.dispose();
  });

  group('AssistantRepositoryImpl Comprehensive Suite', () {
    test('1. getActiveTrip returns Left when USER_BUS_ID is not configured in prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      final repo = AssistantRepositoryImpl();
      final result = await repo.getActiveTrip();

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, contains('لم يتم العثور على حافلة')),
        (_) => fail('Expected Left'),
      );
    });

    test('2. getActiveTrip returns Right(BusTripModel) on 200 with morning trip mapping', () async {
      SharedPreferences.setMockInitialValues({'USER_BUS_ID': 'bus-88'});
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      final repo = AssistantRepositoryImpl();
      final result = await repo.getActiveTrip();

      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Expected Right: $error'),
        (trip) {
          expect(trip.id, 'trip-99');
          expect(trip.busNumber, 'Bus-99');
          expect(trip.driverName, 'سالم السائقي');
          expect(trip.driverPhone, '91000000');
          expect(trip.suggestedTripType, 'to_school');
          expect(trip.students.length, 2);
          expect(trip.students[0].name, 'خالد ناصر');
          expect(trip.students[0].status, BusStudentStatus.waiting);
          expect(trip.students[1].name, 'مريم أحمد');
          expect(trip.students[1].status, BusStudentStatus.onBus);
          expect(trip.schoolLatitude, 23.5880);
          expect(trip.schoolLongitude, 58.3829);
        },
      );
    });

    test('3. getActiveTrip maps afternoon and back trip_type to to_home', () async {
      SharedPreferences.setMockInitialValues({'USER_BUS_ID': 'bus-88'});
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      fakeDioAdapter.customPassengersResponse = {
        'bus': {
          'trip_id': 'trip-afternoon-1',
          'bus_number': 'Bus-88',
          'trip_type': 'afternoon',
          'suggested_direction': 'to_home',
          'trip_status': 'active',
        },
        'driver': {'name': 'حميد'},
        'passengers': [],
      };

      final repo = AssistantRepositoryImpl();
      final result = await repo.getActiveTrip();

      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Expected Right: $error'),
        (trip) => expect(trip.suggestedTripType, 'to_home'),
      );
    });

    test('4. getActiveTrip returns Left on 500 error response', () async {
      SharedPreferences.setMockInitialValues({'USER_BUS_ID': 'bus-88'});
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      fakeDioAdapter.statusCode = 500;

      final repo = AssistantRepositoryImpl();
      final result = await repo.getActiveTrip();

      expect(result.isLeft(), isTrue);
    });

    test('5. confirmTrip returns Right(null) on 200 and handles 400 error', () async {
      SharedPreferences.setMockInitialValues({'USER_BUS_ID': 'bus-88'});
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      final repo = AssistantRepositoryImpl();

      // Scenario A: Success 200
      fakeDioAdapter.statusCode = 200;
      final resultSuccess = await repo.confirmTrip('trip-99');
      expect(resultSuccess.isRight(), isTrue);
      expect(fakeDioAdapter.lastRequestOptions?.path, '/bus/bus-88/confirm-trip');
      expect(fakeDioAdapter.lastRequestBody, {'trip_id': 'trip-99'});

      // Scenario B: Server failure
      fakeDioAdapter.statusCode = 400;
      final resultFail = await repo.confirmTrip('trip-99');
      expect(resultFail.isLeft(), isTrue);
    });

    test('6. updateStudentStatus dispatches correct endpoint per status', () async {
      SharedPreferences.setMockInitialValues({'USER_BUS_ID': 'bus-88'});
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      final repo = AssistantRepositoryImpl();

      // OnBus -> mark-boarded
      fakeDioAdapter.statusCode = 200;
      final res1 = await repo.updateStudentStatus('101', BusStudentStatus.onBus, 'to_school');
      expect(res1.isRight(), isTrue);
      expect(fakeDioAdapter.lastRequestOptions?.path, '/bus/bus-88/mark-boarded');
      expect(fakeDioAdapter.lastRequestBody['direction'], 'to_school');

      // AtSchool -> mark-dropped (direction to_school)
      final res2 = await repo.updateStudentStatus('101', BusStudentStatus.atSchool, null);
      expect(res2.isRight(), isTrue);
      expect(fakeDioAdapter.lastRequestOptions?.path, '/bus/bus-88/mark-dropped');
      expect(fakeDioAdapter.lastRequestBody['direction'], 'to_school');

      // AtHome -> mark-dropped (direction to_home)
      final res3 = await repo.updateStudentStatus('101', BusStudentStatus.atHome, null);
      expect(res3.isRight(), isTrue);
      expect(fakeDioAdapter.lastRequestOptions?.path, '/bus/bus-88/mark-dropped');
      expect(fakeDioAdapter.lastRequestBody['direction'], 'to_home');

      // Absent -> mark-absent
      final res4 = await repo.updateStudentStatus('101', BusStudentStatus.absent, null);
      expect(res4.isRight(), isTrue);
      expect(fakeDioAdapter.lastRequestOptions?.path, '/bus/bus-88/mark-absent');

      // Waiting / other status returns Right(null) immediately without network call
      fakeDioAdapter.lastRequestOptions = null;
      final res5 = await repo.updateStudentStatus('101', BusStudentStatus.waiting, null);
      expect(res5.isRight(), isTrue);
      expect(fakeDioAdapter.lastRequestOptions, isNull);
    });

    test('7. groupBoard and groupAlight post student arrays correctly', () async {
      SharedPreferences.setMockInitialValues({'USER_BUS_ID': 'bus-88'});
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      final repo = AssistantRepositoryImpl();

      final resBoard = await repo.groupBoard(studentIds: ['101', '102'], direction: 'to_school');
      expect(resBoard.isRight(), isTrue);
      expect(fakeDioAdapter.lastRequestOptions?.path, '/bus/bus-88/group-board');
      expect(fakeDioAdapter.lastRequestBody['student_ids'], ['101', '102']);

      final resAlight = await repo.groupAlight(studentIds: ['101', '102'], direction: 'to_home');
      expect(resAlight.isRight(), isTrue);
      expect(fakeDioAdapter.lastRequestOptions?.path, '/bus/bus-88/group-alight');
      expect(fakeDioAdapter.lastRequestBody['direction'], 'to_home');
    });

    test('8. submitIncidentReport and submitDailyChecklist execute correctly', () async {
      SharedPreferences.setMockInitialValues({'USER_BUS_ID': 'bus-88'});
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      final repo = AssistantRepositoryImpl();

      final resIncident = await repo.submitIncidentReport(
        studentId: '101',
        type: 'behavior',
        description: 'تأخر في الركوب',
      );
      expect(resIncident.isRight(), isTrue);
      expect(fakeDioAdapter.lastRequestOptions?.path, '/field/incidents');
      expect(fakeDioAdapter.lastRequestBody['type'], 'behavior');

      final resChecklist = await repo.submitDailyChecklist({'doors': true, 'seatbelts': true});
      expect(resChecklist.isRight(), isTrue);
      expect(fakeDioAdapter.lastRequestOptions?.path, '/field/inspections');
      expect(fakeDioAdapter.lastRequestBody['bus_id'], 'bus-88');
    });

    test('9. confirmEmptyBus, sendAlertToDriver, and updateBehavioralNote return Right', () async {
      final repo = AssistantRepositoryImpl();

      final res1 = await repo.confirmEmptyBus();
      expect(res1.isRight(), isTrue);

      final res2 = await repo.sendAlertToDriver('توقف عند المحطة القادمة');
      expect(res2.isRight(), isTrue);

      final res3 = await repo.updateBehavioralNote('101', 'ملتزم جداً');
      expect(res3.isRight(), isTrue);
    });

    test('10. Repository methods return Left when bus ID is missing', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      final repo = AssistantRepositoryImpl();

      expect((await repo.confirmTrip('t1')).isLeft(), isTrue);
      expect((await repo.updateStudentStatus('s1', BusStudentStatus.onBus, 'to_school')).isLeft(), isTrue);
      expect((await repo.groupBoard(studentIds: ['s1'], direction: 'to_school')).isLeft(), isTrue);
      expect((await repo.groupAlight(studentIds: ['s1'], direction: 'to_school')).isLeft(), isTrue);
      expect((await repo.submitDailyChecklist({'doors': true})).isLeft(), isTrue);
    });
  });

  group('BusTrackingCubit Real Orchestration Suite', () {
    test('11. startTracking emits BusTrackingLoading then BusTrackingError when bus ID is missing', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      final cubit = BusTrackingCubit();
      expect(cubit.state, isA<BusTrackingInitial>());

      await cubit.startTracking();

      expect(cubit.state, isA<BusTrackingError>());
      final errorState = cubit.state as BusTrackingError;
      expect(errorState.message, contains('لم يتم العثور على حافلة'));

      await cubit.close();
    });

    test('12. startTracking succeeds and emits BusTrackingLoaded with parsed location and students', () async {
      SharedPreferences.setMockInitialValues({
        'USER_BUS_ID': 'bus-99',
        'USER_ID': '123',
      });
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      final cubit = BusTrackingCubit();
      final states = <BusTrackingState>[];
      cubit.stream.listen(states.add);

      await cubit.startTracking();

      expect(cubit.state, isA<BusTrackingLoaded>());
      final loadedState = cubit.state as BusTrackingLoaded;

      expect(loadedState.position, isNotNull);
      expect(loadedState.position?.busId, 'bus-99');
      expect(loadedState.position?.lat, 23.5895);
      expect(loadedState.position?.lng, 58.3845);
      expect(loadedState.position?.speedKmh, 40.0);
      expect(loadedState.students.length, 2);
      expect(loadedState.students[0].name, 'خالد ناصر');

      await cubit.close();
    });

    test('13. startTracking gracefully handles location endpoint failure and still emits BusTrackingLoaded', () async {
      SharedPreferences.setMockInitialValues({
        'USER_BUS_ID': 'bus-99',
        'USER_ID': '123',
      });
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      fakeDioAdapter.throwOnLocation = true;

      final cubit = BusTrackingCubit();
      await cubit.startTracking();

      expect(cubit.state, isA<BusTrackingLoaded>());
      final loadedState = cubit.state as BusTrackingLoaded;

      // Position is null because location endpoint failed, but students loaded successfully
      expect(loadedState.position, isNull);
      expect(loadedState.students.length, 2);

      await cubit.close();
    });

    test('14. startTracking with silent: true does not emit BusTrackingLoading first', () async {
      SharedPreferences.setMockInitialValues({
        'USER_BUS_ID': 'bus-99',
        'USER_ID': '123',
      });
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      final cubit = BusTrackingCubit();
      final states = <BusTrackingState>[];
      cubit.stream.listen(states.add);

      await cubit.startTracking(silent: true);

      // Loading state should NOT be in the emitted states
      expect(states.any((s) => s is BusTrackingLoading), isFalse);
      expect(cubit.state, isA<BusTrackingLoaded>());

      await cubit.close();
    });
  });
}
