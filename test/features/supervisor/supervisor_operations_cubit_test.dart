import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/driver/route/domain/entities/student_stop.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/presentation/cubit/supervisor_tracking_cubit.dart';

class FakeDioAdapter implements HttpClientAdapter {
  Map<String, dynamic> passengersResponse = {
    'bus': {
      'trip_type': 'morning',
      'bus_number': 'Bus-42',
      'has_active_trip': true,
      'school_lat': 23.5880,
      'school_lng': 58.3829,
    },
    'passengers': [
      {
        'id': 1,
        'name': 'محمد سعيد',
        'parentName': 'سعيد الوهيبي',
        'latitude': 23.5900,
        'longitude': 58.3850,
        'status': 'onBus',
        'isOnBus': true,
      },
      {
        'id': 2,
        'name': 'فاطمة علي',
        'parentName': 'علي المعمري',
        'latitude': 23.5910,
        'longitude': 58.3860,
        'status': 'absent',
        'isAbsent': true,
      },
      {
        'id': 3,
        'name': 'أحمد ناصر',
        'parentName': 'ناصر العامري',
        'latitude': 23.5920,
        'longitude': 58.3870,
        'status': 'atSchool',
      },
    ],
  };

  Map<String, dynamic> locationResponse = {
    'latitude': 23.5895,
    'longitude': 58.3845,
    'speed_kmh': 45.5,
    'heading': 180.0,
    'target_lat': 23.5920,
    'target_lng': 58.3870,
  };

  int statusCode = 200;
  bool shouldThrow = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (shouldThrow) {
      throw DioException(
        requestOptions: options,
        error: 'Network failure',
        type: DioExceptionType.connectionError,
      );
    }

    if (options.path.contains('maps.googleapis.com')) {
      return ResponseBody.fromString(
        jsonEncode({
          'status': 'OK',
          'routes': [
            {
              'overview_polyline': {
                'points': '_p~iF~ps|U_ulLnnqC_mqNvxq`@'
              }
            }
          ]
        }),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path.contains('passengers')) {
      return ResponseBody.fromString(
        jsonEncode(passengersResponse),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode(locationResponse),
      statusCode,
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

  late FakeDioAdapter fakeAdapter;
  late Dio testDio;
  late SupervisorTrackingCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'USER_ID': '10'});
    final prefs = await SharedPreferences.getInstance();
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
    }

    fakeAdapter = FakeDioAdapter();
    testDio = Dio(BaseOptions(baseUrl: 'https://test.api/'));
    testDio.httpClientAdapter = fakeAdapter;
    ApiClient.testDio = testDio;

    cubit = SupervisorTrackingCubit(busId: 10);
  });

  tearDown(() async {
    ApiClient.testDio = null;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cubit.close();
  });

  group('Agent 2 (srv-supervisor) — SupervisorTrackingCubit Suite', () {
    test('1. Initial state is SupervisorTrackingInitial', () {
      expect(cubit.state, isA<SupervisorTrackingInitial>());
      expect(cubit.busId, 10);
    });

    test('2. init() loads passengers, bus location, and emits SupervisorTrackingLoaded', () async {
      await cubit.init();

      expect(cubit.state, isA<SupervisorTrackingLoaded>());
      final loaded = cubit.state as SupervisorTrackingLoaded;

      expect(loaded.busNumber, 'Bus-42');
      expect(loaded.tripType, 'morning');
      expect(loaded.hasActiveTrip, isTrue);
      expect(loaded.stops.length, 3);

      // Verify student statuses
      expect(loaded.stops[0].nameAr, 'محمد سعيد');
      expect(loaded.stops[0].isBoarded, isTrue);

      expect(loaded.stops[1].nameAr, 'فاطمة علي');
      expect(loaded.stops[1].isAbsent, isTrue);

      expect(loaded.stops[2].nameAr, 'أحمد ناصر');
      expect(loaded.stops[2].isDroppedOff, isTrue);

      // Verify positions and navigation metrics
      expect(loaded.busPosition?.latitude, 23.5895);
      expect(loaded.busPosition?.longitude, 58.3845);
      expect(loaded.schoolPosition?.latitude, 23.5880);
      expect(loaded.speed, 45.5);
      expect(loaded.heading, 180.0);
    });

    test('3. Fallback to school position when bus GPS coordinates are zero or null', () async {
      fakeAdapter.locationResponse = {
        'latitude': 0,
        'longitude': 0,
        'speed_kmh': 0,
        'heading': 0,
      };

      await cubit.init();

      expect(cubit.state, isA<SupervisorTrackingLoaded>());
      final loaded = cubit.state as SupervisorTrackingLoaded;

      // When bus latitude is 0, it safely falls back to school position
      expect(loaded.busPosition?.latitude, loaded.schoolPosition?.latitude);
      expect(loaded.busPosition?.longitude, loaded.schoolPosition?.longitude);
    });

    test('4. Afternoon trip type maps correctly and checks dropoff atHome', () async {
      fakeAdapter.passengersResponse['bus']['trip_type'] = 'afternoon';
      fakeAdapter.passengersResponse['passengers'] = [
        {
          'id': 5,
          'name': 'عمر سالم',
          'parentName': 'سالم',
          'latitude': 23.6000,
          'longitude': 58.4000,
          'status': 'atHome',
        }
      ];

      await cubit.init();

      expect(cubit.state, isA<SupervisorTrackingLoaded>());
      final loaded = cubit.state as SupervisorTrackingLoaded;
      expect(loaded.tripType, 'afternoon');
      expect(loaded.stops.first.isDroppedOff, isTrue);
    });

    test('5. init() emits SupervisorTrackingError on network failure', () async {
      fakeAdapter.shouldThrow = true;

      await cubit.init();

      expect(cubit.state, isA<SupervisorTrackingError>());
      final err = cubit.state as SupervisorTrackingError;
      expect(err.message.isNotEmpty, isTrue);
    });

    test('6. SupervisorTrackingLoaded copyWith updates targeted fields cleanly', () {
      final initial = SupervisorTrackingLoaded(
        stops: const [],
        tripType: 'morning',
        busNumber: 'Bus-1',
        speed: 30.0,
        heading: 90.0,
      );

      final updated = initial.copyWith(
        speed: 65.0,
        heading: 270.0,
        hasActiveTrip: false,
      );

      expect(updated.speed, 65.0);
      expect(updated.heading, 270.0);
      expect(updated.hasActiveTrip, isFalse);
      expect(updated.busNumber, 'Bus-1');
      expect(updated.tripType, 'morning');
    });
  });
}
