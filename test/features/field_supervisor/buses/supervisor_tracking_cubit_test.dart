import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/driver/route/domain/entities/student_stop.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/presentation/cubit/supervisor_tracking_cubit.dart';

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

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

StudentStop makeStop({
  String id = '1',
  double lat = 24.68,
  double lng = 46.72,
  bool isBoarded = false,
  bool isAbsent = false,
  bool isDroppedOff = false,
}) {
  return StudentStop(
    id: id,
    nameAr: 'طالب $id',
    nameEn: 'Student $id',
    parentAr: 'ولي الأمر',
    parentEn: 'Parent',
    location: LatLng(lat, lng),
    isBoarded: isBoarded,
    isAbsent: isAbsent,
    isDroppedOff: isDroppedOff,
  );
}

SupervisorTrackingLoaded makeLoaded({
  List<StudentStop>? stops,
  LatLng? busPosition,
  LatLng? schoolPosition,
  String tripType = 'morning',
  String busNumber = '#42',
}) {
  return SupervisorTrackingLoaded(
    stops: stops ?? [makeStop()],
    busPosition: busPosition ?? const LatLng(24.68, 46.72),
    schoolPosition: schoolPosition ?? const LatLng(24.70, 46.75),
    tripType: tripType,
    busNumber: busNumber,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── StudentStop entity ───────────────────────────────────────────────────

  group('StudentStop entity', () {
    test('1. StudentStop has correct default flags', () {
      final stop = makeStop();
      expect(stop.isBoarded, isFalse);
      expect(stop.isAbsent, isFalse);
      expect(stop.isDroppedOff, isFalse);
      expect(stop.isWaiting, isFalse);
    });

    test('2. StudentStop copyWith updates boolean flags', () {
      final stop = makeStop();
      final updated = stop.copyWith(isBoarded: true, isDroppedOff: true);
      expect(updated.isBoarded, isTrue);
      expect(updated.isDroppedOff, isTrue);
      expect(updated.isAbsent, isFalse); // unchanged
    });

    test('3. StudentStop preserves location in copyWith', () {
      final stop = makeStop(lat: 24.68, lng: 46.72);
      final updated = stop.copyWith(isAbsent: true);
      expect(updated.location.latitude, 24.68);
      expect(updated.location.longitude, 46.72);
    });

    test('4. StudentStop waitingElapsedSeconds defaults to 0', () {
      expect(makeStop().waitingElapsedSeconds, 0);
    });
  });

  // ── SupervisorTrackingLoaded state ────────────────────────────────────────

  group('SupervisorTrackingLoaded state', () {
    test('5. Default polylinePoints is empty', () {
      final state = makeLoaded();
      expect(state.polylinePoints, isEmpty);
    });

    test('6. Default hasActiveTrip is true', () {
      expect(makeLoaded().hasActiveTrip, isTrue);
    });

    test('7. Default speed and heading are 0', () {
      final state = makeLoaded();
      expect(state.speed, 0);
      expect(state.heading, 0);
    });

    test('8. copyWith updates busPosition only', () {
      final original = makeLoaded();
      const newPos = LatLng(25.0, 47.0);
      final updated = original.copyWith(busPosition: newPos);
      expect(updated.busPosition, newPos);
      expect(updated.tripType, original.tripType); // unchanged
    });

    test('9. copyWith updates speed and heading', () {
      final state = makeLoaded().copyWith(speed: 60.0, heading: 90.0);
      expect(state.speed, 60.0);
      expect(state.heading, 90.0);
    });

    test('10. copyWith updates stops list', () {
      final original = makeLoaded(stops: [makeStop(id: 'a')]);
      final newStops = [makeStop(id: 'x'), makeStop(id: 'y')];
      final updated = original.copyWith(stops: newStops);
      expect(updated.stops.length, 2);
      expect(updated.stops.first.id, 'x');
    });

    test('11. copyWith updates polylinePoints', () {
      final state = makeLoaded().copyWith(polylinePoints: [
        const LatLng(24.0, 46.0),
        const LatLng(24.5, 46.5),
      ]);
      expect(state.polylinePoints.length, 2);
    });

    test('12. copyWith can set hasActiveTrip to false', () {
      final state = makeLoaded().copyWith(hasActiveTrip: false);
      expect(state.hasActiveTrip, isFalse);
    });

    test('13. copyWith updates tripType', () {
      final state = makeLoaded(tripType: 'morning').copyWith(tripType: 'afternoon');
      expect(state.tripType, 'afternoon');
    });

    test('14. SupervisorTrackingLoaded carries school position', () {
      const school = LatLng(24.70, 46.75);
      final state = makeLoaded(schoolPosition: school);
      expect(state.schoolPosition, school);
    });

    test('15. targetPosition is nullable and defaults null', () {
      final state = makeLoaded();
      expect(state.targetPosition, isNull);
    });

    test('16. busNumber is stored correctly', () {
      final state = makeLoaded(busNumber: '42-A');
      expect(state.busNumber, '42-A');
    });
  });

  // ── SupervisorTrackingCubit state machine ─────────────────────────────────

  group('SupervisorTrackingCubit state machine', () {
    late SupervisorTrackingCubit cubit;

    setUp(() => cubit = SupervisorTrackingCubit(busId: 42));
    tearDown(() => cubit.close());

    test('17. Initial state is SupervisorTrackingInitial', () {
      expect(cubit.state, isA<SupervisorTrackingInitial>());
    });

    test('18. Emit SupervisorTrackingLoading transitions state', () {
      cubit.emit(SupervisorTrackingLoading());
      expect(cubit.state, isA<SupervisorTrackingLoading>());
    });

    test('19. Emit SupervisorTrackingLoaded stores correct data', () {
      final loaded = makeLoaded();
      cubit.emit(loaded);
      final state = cubit.state as SupervisorTrackingLoaded;
      expect(state.busNumber, '#42');
      expect(state.tripType, 'morning');
      expect(state.stops.length, 1);
    });

    test('20. Emit SupervisorTrackingError stores message', () {
      cubit.emit(SupervisorTrackingError('فشل الاتصال'));
      final state = cubit.state as SupervisorTrackingError;
      expect(state.message, 'فشل الاتصال');
    });

    test('21. busId is stored on construction', () {
      expect(cubit.busId, 42);
    });

    test('22. Cubit transitions: Initial → Loading → Loaded', () async {
      final states = <SupervisorTrackingState>[];
      cubit.stream.listen(states.add);

      cubit.emit(SupervisorTrackingLoading());
      cubit.emit(makeLoaded());

      await Future.delayed(Duration.zero);
      expect(states[0], isA<SupervisorTrackingLoading>());
      expect(states[1], isA<SupervisorTrackingLoaded>());
    });

    test('23. Multiple consecutive state emissions are tracked', () async {
      final states = <SupervisorTrackingState>[];
      cubit.stream.listen(states.add);

      cubit.emit(SupervisorTrackingLoading());
      cubit.emit(SupervisorTrackingError('error'));
      cubit.emit(SupervisorTrackingLoading());
      cubit.emit(makeLoaded());

      await Future.delayed(Duration.zero);
      expect(states.length, 4);
      expect(states.last, isA<SupervisorTrackingLoaded>());
    });

    test('24. Cubit closes safely and isClosed returns true', () async {
      await cubit.close();
      expect(cubit.isClosed, isTrue);
    });
  });

  // ── Morning/Afternoon stop logic ─────────────────────────────────────────

  group('Stop status semantics', () {
    test('25. Morning trip: unboarded stop is the next pickup target', () {
      final stops = [
        makeStop(id: '1', isBoarded: true),
        makeStop(id: '2', isBoarded: false, isAbsent: false, lat: 24.5, lng: 46.5),
        makeStop(id: '3', isBoarded: false),
      ];
      // Simulate what cubit does: find first unboarded non-absent with valid coords
      final next = stops.firstWhere((s) => !s.isBoarded && !s.isAbsent && s.location.latitude != 0.0);
      expect(next.id, '2');
    });

    test('26. All boarded → target becomes school', () {
      final stops = [
        makeStop(id: '1', isBoarded: true),
        makeStop(id: '2', isBoarded: true),
      ];
      final hasUnboarded = stops.any((s) => !s.isBoarded && !s.isAbsent);
      expect(hasUnboarded, isFalse);
    });

    test('27. Afternoon trip: first un-dropped-off student is next target', () {
      final stops = [
        makeStop(id: '1', isDroppedOff: true),
        makeStop(id: '2', isDroppedOff: false, isAbsent: false, lat: 24.5, lng: 46.5),
      ];
      final next = stops.firstWhere((s) => !s.isDroppedOff && !s.isAbsent && s.location.latitude != 0.0);
      expect(next.id, '2');
    });

    test('28. All dropped off → no next target (trip finished)', () {
      final stops = [
        makeStop(id: '1', isDroppedOff: true),
        makeStop(id: '2', isDroppedOff: true),
      ];
      try {
        stops.firstWhere((s) => !s.isDroppedOff && !s.isAbsent);
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<StateError>());
      }
    });
  });

  // ── init() Integration Tests ─────────────────────────────────────────────

  group('SupervisorTrackingCubit init() workflow', () {
    late _FakeHttpAdapter adapter;
    late Dio testDio;
    late SharedPreferences prefs;
    late SupervisorTrackingCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'USER_ID': '123'});
      prefs = await SharedPreferences.getInstance();
      if (GetIt.I.isRegistered<SharedPreferences>()) {
        GetIt.I.unregister<SharedPreferences>();
      }
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      adapter = _FakeHttpAdapter();
      testDio = Dio(BaseOptions(baseUrl: 'https://api.test.com/'));
      testDio.httpClientAdapter = adapter;
      ApiClient.testDio = testDio;

      cubit = SupervisorTrackingCubit(busId: 5);
    });

    tearDown(() async {
      ApiClient.testDio = null;
      await cubit.close();
    });

    test('29. init() successfully loads morning passengers and bus location', () async {
      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_type': 'morning',
                'bus_number': 'BUS-05',
                'has_active_trip': true,
                'school_lat': 24.7136,
                'school_lng': 46.6753,
              },
              'passengers': [
                {
                  'id': 101,
                  'name': 'طالب 1',
                  'parentName': 'ولي 1',
                  'forth_latitude': 24.7000,
                  'forth_longitude': 46.6800,
                  'status': 'onBus',
                  'isOnBus': true,
                },
                {
                  'id': 102,
                  'name': 'طالب 2',
                  'parentName': 'ولي 2',
                  'forth_latitude': 24.7100,
                  'forth_longitude': 46.6900,
                  'status': 'waiting',
                  'isOnBus': false,
                },
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('location')) {
          return ResponseBody.fromString(
            jsonEncode({
              'latitude': 24.7050,
              'longitude': 46.6850,
              'speed_kmh': 45.0,
              'heading': 180.0,
              'target_lat': 24.7100,
              'target_lng': 46.6900,
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.init();

      expect(cubit.state, isA<SupervisorTrackingLoaded>());
      final loaded = cubit.state as SupervisorTrackingLoaded;
      expect(loaded.busNumber, 'BUS-05');
      expect(loaded.tripType, 'morning');
      expect(loaded.hasActiveTrip, isTrue);
      expect(loaded.stops.length, 2);
      expect(loaded.stops[0].isBoarded, isTrue);
      expect(loaded.stops[1].isBoarded, isFalse);
      expect(loaded.busPosition?.latitude, 24.7050);
      expect(loaded.speed, 45.0);
      expect(loaded.heading, 180.0);
    });

    test('30. init() successfully loads afternoon trip with fallback coordinates', () async {
      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_type': 'afternoon',
                'bus_number': 'BUS-05',
                'has_active_trip': false,
              },
              'passengers': [
                {
                  'id': 201,
                  'name': 'سعيد',
                  'status': 'dropped',
                  'latitude': 24.6000,
                  'longitude': 46.5000,
                },
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('location')) {
          return ResponseBody.fromString(
            jsonEncode({
              'latitude': null, // missing location fallback
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.init();

      expect(cubit.state, isA<SupervisorTrackingLoaded>());
      final loaded = cubit.state as SupervisorTrackingLoaded;
      expect(loaded.tripType, 'afternoon');
      expect(loaded.hasActiveTrip, isFalse);
      expect(loaded.stops.first.isDroppedOff, isTrue);
      expect(loaded.stops.first.location.latitude, 24.6000);
    });

    test('31. init() handles non-200 passengers response with SupervisorTrackingError', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'الحافلة غير موجودة'}),
          404,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await cubit.init();

      expect(cubit.state, isA<SupervisorTrackingError>());
      final error = cubit.state as SupervisorTrackingError;
      expect(error.message, contains('الحافلة غير موجودة'));
    });

    test('33. init() with error payload in response emits SupervisorTrackingError with error field', () async {
      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode({'error': 'خطأ بالخادم الداخلي'}),
            500,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.init();

      expect(cubit.state, isA<SupervisorTrackingError>());
      final error = cubit.state as SupervisorTrackingError;
      expect(error.message, contains('خطأ بالخادم الداخلي'));
    });

    test('34. init() uses school location as fallback when bus location is missing', () async {
      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_type': 'morning',
                'bus_number': 'BUS-FALLBACK',
                'school_lat': 23.6100,
                'school_lng': 58.5400,
              },
              'passengers': []
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('location')) {
          return ResponseBody.fromString(
            jsonEncode({'latitude': 0, 'longitude': 0}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.init();

      expect(cubit.state, isA<SupervisorTrackingLoaded>());
      final loaded = cubit.state as SupervisorTrackingLoaded;
      expect(loaded.busPosition?.latitude, 23.6100);
      expect(loaded.busPosition?.longitude, 58.5400);
      expect(loaded.schoolPosition?.latitude, 23.6100);
    });

    test('35. init() parses student lastEvent alighting to school as dropped off', () async {
      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {'trip_type': 'morning', 'bus_number': 'B1'},
              'passengers': [
                {
                  'id': 505,
                  'name': 'حمزة',
                  'forth_latitude': 23.5,
                  'forth_longitude': 58.4,
                  'lastEvent': {
                    'type': 'alighting',
                    'direction': 'to_school',
                  },
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('location')) {
          return ResponseBody.fromString(
            jsonEncode({'latitude': 23.5, 'longitude': 58.4}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.init();

      final loaded = cubit.state as SupervisorTrackingLoaded;
      expect(loaded.stops.first.isDroppedOff, isTrue);
      expect(loaded.stops.first.isBoarded, isFalse);
    });

    test('36. init() parses student boarded and absent status', () async {
      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {'trip_type': 'morning', 'bus_number': 'B2'},
              'passengers': [
                {
                  'id': 601,
                  'name': 'طالب صاعد',
                  'status': 'boarded',
                  'forth_latitude': 23.5,
                  'forth_longitude': 58.4,
                },
                {
                  'id': 602,
                  'name': 'طالب غائب',
                  'isAbsent': true,
                  'forth_latitude': 23.6,
                  'forth_longitude': 58.5,
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('location')) {
          return ResponseBody.fromString(
            jsonEncode({'latitude': 23.5, 'longitude': 58.4}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.init();

      final loaded = cubit.state as SupervisorTrackingLoaded;
      expect(loaded.stops[0].isBoarded, isTrue);
      expect(loaded.stops[1].isAbsent, isTrue);
    });

    test('37. copyWith updates targetPosition and schoolPosition', () {
      final initial = makeLoaded();
      const newTarget = LatLng(23.7, 58.6);
      const newSchool = LatLng(23.8, 58.7);
      final updated = initial.copyWith(
        targetPosition: newTarget,
        schoolPosition: newSchool,
      );
      expect(updated.targetPosition, newTarget);
      expect(updated.schoolPosition, newSchool);
    });
  });
}

