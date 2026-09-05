import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';
import 'package:msaratwasel_services/features/assistant/tracking/domain/entities/bus_position.dart';
import 'package:msaratwasel_services/features/assistant/tracking/presentation/cubit/bus_tracking_cubit.dart';

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

BusStudentEntity makeStudent({
  String id = 's1',
  String name = 'أحمد محمد',
  String? nameEn = 'Ahmed',
  String grade = 'الأول ابتدائي',
  BusStudentStatus status = BusStudentStatus.atHome,
}) {
  return BusStudentEntity(
    id: id,
    studentCode: 'SC$id',
    name: name,
    nameEn: nameEn,
    grade: grade,
    schoolId: 'SCH1',
    parentName: 'محمد علي',
    parentPhone: '0501234567',
    status: status,
  );
}

BusPosition makePosition({
  String busId = '42',
  double lat = 24.68,
  double lng = 46.72,
  double speedKmh = 0.0,
}) {
  return BusPosition(
    busId: busId,
    lat: lat,
    lng: lng,
    speedKmh: speedKmh,
    distanceKm: 0.0,
    etaMinutes: 0,
    studentsOnBoard: 0,
    state: BusState.enRoute,
    updatedAt: DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BusPosition entity', () {
    test('1. BusPosition props equality', () {
      final dt = DateTime(2025, 1, 1);
      final p1 = BusPosition(busId: '1', lat: 24.0, lng: 46.0, speedKmh: 60.0, distanceKm: 5.2, etaMinutes: 8, studentsOnBoard: 20, state: BusState.enRoute, updatedAt: dt);
      final p2 = BusPosition(busId: '1', lat: 24.0, lng: 46.0, speedKmh: 60.0, distanceKm: 5.2, etaMinutes: 8, studentsOnBoard: 20, state: BusState.enRoute, updatedAt: dt);
      expect(p1, equals(p2));
    });

    test('2. BusPosition copyWith changes only specified fields', () {
      final original = makePosition();
      final updated = original.copyWith(lat: 25.0, speedKmh: 80.0);
      expect(updated.lat, 25.0);
      expect(updated.speedKmh, 80.0);
      expect(updated.busId, original.busId);
    });

    test('3. BusState enum contains all expected values', () {
      expect(BusState.values, containsAll([BusState.atStation, BusState.enRoute, BusState.arrived]));
    });

    test('4. BusPosition optional targetLat/Lng nullable then settable', () {
      final pos = makePosition();
      expect(pos.targetLat, isNull);
      final withTarget = pos.copyWith(targetLat: 24.9, targetLng: 46.8);
      expect(withTarget.targetLat, 24.9);
    });
  });

  group('BusStudentEntity', () {
    test('5. getLocalizedName returns Arabic by default', () {
      expect(makeStudent(name: 'خالد', nameEn: 'Khalid').getLocalizedName('ar'), 'خالد');
    });
    test('6. getLocalizedName returns English when locale is en', () {
      expect(makeStudent(name: 'خالد', nameEn: 'Khalid').getLocalizedName('en'), 'Khalid');
    });
    test('7. getLocalizedName falls back to Arabic when nameEn is null', () {
      expect(makeStudent(name: 'خالد', nameEn: null).getLocalizedName('en'), 'خالد');
    });
    test('8. getLocalizedName falls back when nameEn is blank', () {
      final s = BusStudentEntity(id: 'x', studentCode: 'SC', name: 'فيصل', nameEn: '  ', grade: 'ثانوي', schoolId: 'S1', parentName: 'الوالد', parentPhone: '05');
      expect(s.getLocalizedName('en'), 'فيصل');
    });
    test('9. getLocalizedGrade returns Arabic when locale is ar', () {
      expect(makeStudent(grade: 'الأول ابتدائي').getLocalizedGrade('ar'), 'الأول ابتدائي');
    });
    test('10. getLocalizedGrade translates primary stage to English', () {
      expect(makeStudent(grade: 'الأول ابتدائي').getLocalizedGrade('en'), contains('Primary'));
    });
    test('11. getLocalizedGrade translates حضانة to Nursery', () {
      expect(makeStudent(grade: 'حضانة').getLocalizedGrade('en'), 'Nursery');
    });
    test('12. getLocalizedGrade translates روضة to Kindergarten', () {
      expect(makeStudent(grade: 'الروضة').getLocalizedGrade('en'), 'Kindergarten');
    });
    test('13. getLocalizedGrade translates متوسط to Intermediate', () {
      expect(makeStudent(grade: 'المتوسط').getLocalizedGrade('en'), 'Intermediate');
    });
    test('14. getLocalizedGrade translates ثانوي to Secondary', () {
      expect(makeStudent(grade: 'الثانوي').getLocalizedGrade('en'), 'Secondary');
    });
    test('15. getLocalizedGrade returns Not Specified for empty/غير محدد', () {
      expect(makeStudent(grade: 'غير محدد').getLocalizedGrade('en'), 'Not Specified');
    });
    test('16. getLocalizedGrade handles ordinal + stage combination', () {
      final result = makeStudent(grade: 'الثاني ابتدائي').getLocalizedGrade('en');
      expect(result, contains('2nd'));
      expect(result, contains('Primary'));
    });
    test('17. BusStudentStatus labelAr returns correct Arabic labels', () {
      expect(BusStudentStatus.atHome.labelAr, 'في المنزل');
      expect(BusStudentStatus.onBus.labelAr, 'في الحافلة');
      expect(BusStudentStatus.atSchool.labelAr, 'في المدرسة');
      expect(BusStudentStatus.absent.labelAr, 'غائب');
      expect(BusStudentStatus.waiting.labelAr, 'انتظار');
      expect(BusStudentStatus.unknown.labelAr, 'غير محدد');
    });
    test('18. copyWith updates only specified fields', () {
      final original = makeStudent();
      final updated = original.copyWith(name: 'سعد', status: BusStudentStatus.onBus, forthLatitude: 24.5);
      expect(updated.name, 'سعد');
      expect(updated.status, BusStudentStatus.onBus);
      expect(updated.forthLatitude, 24.5);
      expect(updated.id, original.id);
    });
    test('19. Equatable equality works correctly', () {
      expect(makeStudent(id: 'a'), equals(makeStudent(id: 'a')));
      expect(makeStudent(id: 'a'), isNot(equals(makeStudent(id: 'b'))));
    });
    test('20. GPS coordinate fields are settable via copyWith', () {
      final s = makeStudent().copyWith(forthLatitude: 24.68, forthLongitude: 46.72, backLatitude: 24.70, latitude: 24.69);
      expect(s.forthLatitude, 24.68);
      expect(s.backLatitude, 24.70);
      expect(s.latitude, 24.69);
    });
  });

  group('BusTrackingCubit state machine', () {
    late BusTrackingCubit cubit;
    setUp(() => cubit = BusTrackingCubit());
    tearDown(() => cubit.close());

    test('21. Initial state is BusTrackingInitial', () {
      expect(cubit.state, isA<BusTrackingInitial>());
    });
    test('22. Emit BusTrackingLoaded stores position and students', () {
      final pos = makePosition();
      final students = [makeStudent()];
      cubit.emit(BusTrackingLoaded(pos, students));
      final state = cubit.state as BusTrackingLoaded;
      expect(state.position, pos);
      expect(state.students.length, 1);
    });
    test('23. BusTrackingLoaded with null position is valid', () {
      cubit.emit(const BusTrackingLoaded(null, []));
      final state = cubit.state as BusTrackingLoaded;
      expect(state.position, isNull);
      expect(state.students, isEmpty);
    });
    test('24. BusTrackingError stores message', () {
      cubit.emit(const BusTrackingError('خطأ في الاتصال'));
      expect((cubit.state as BusTrackingError).message, 'خطأ في الاتصال');
    });
    test('25. BusTrackingLoaded Equatable comparison', () {
      final pos = makePosition();
      final students = [makeStudent()];
      expect(BusTrackingLoaded(pos, students), equals(BusTrackingLoaded(pos, students)));
    });
    test('26. updateStudents replaces student list keeping position', () {
      final pos = makePosition();
      cubit.emit(BusTrackingLoaded(pos, [makeStudent(id: 'old')]));
      cubit.updateStudents([makeStudent(id: 'new1'), makeStudent(id: 'new2')]);
      final state = cubit.state as BusTrackingLoaded;
      expect(state.students.length, 2);
      expect(state.students.first.id, 'new1');
      expect(state.position, pos);
    });
    test('27. updateStudents is no-op when state is not BusTrackingLoaded', () {
      cubit.updateStudents([makeStudent()]);
      expect(cubit.state, isA<BusTrackingInitial>());
    });
    test('28. Cubit closes safely', () async {
      await cubit.close();
      expect(cubit.isClosed, isTrue);
    });
  });

  group('BusTrackingCubit - startTracking() API Integration', () {
    late _FakeHttpAdapter adapter;
    late Dio testDio;
    late SharedPreferences prefs;
    late BusTrackingCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'USER_ID': '50',
        'USER_BUS_ID': '7',
      });
      prefs = await SharedPreferences.getInstance();
      if (GetIt.I.isRegistered<SharedPreferences>()) {
        GetIt.I.unregister<SharedPreferences>();
      }
      GetIt.I.registerSingleton<SharedPreferences>(prefs);

      adapter = _FakeHttpAdapter();
      testDio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
      testDio.httpClientAdapter = adapter;
      ApiClient.testDio = testDio;

      cubit = BusTrackingCubit();
    });

    tearDown(() async {
      ApiClient.testDio = null;
      await cubit.close();
    });

    test('29. startTracking() loads passengers and bus location successfully', () async {
      adapter.handler = (options) {
        if (options.path.contains('/bus/7/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_id': 'trip_77',
                'bus_number': 'B7',
              },
              'driver': {
                'name': 'سائق الحافلة',
                'phone': '0555555555',
              },
              'passengers': [
                {
                  'id': 'st_1',
                  'student_id': 'st_1',
                  'name': 'علي أحمد',
                  'student_name': 'علي أحمد',
                  'status': 'onBus',
                  'is_on_bus': true,
                  'parent_name': 'أحمد',
                  'parent_phone': '0501111111',
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('/bus/7/location')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'latitude': 24.7136,
                'longitude': 46.6753,
                'speed_kmh': 55.0,
                'students_on_board': 1,
              }
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.startTracking();

      expect(cubit.state, isA<BusTrackingLoaded>());
      final loaded = cubit.state as BusTrackingLoaded;
      expect(loaded.students.length, 1);
      expect(loaded.students.first.name, 'علي أحمد');
      expect(loaded.position, isNotNull);
      expect(loaded.position!.lat, 24.7136);
      expect(loaded.position!.lng, 46.6753);
      expect(loaded.position!.speedKmh, 55.0);
    });

    test('30. startTracking() emits BusTrackingError when bus ID is not found in prefs', () async {
      await prefs.remove('USER_BUS_ID');

      await cubit.startTracking();

      expect(cubit.state, isA<BusTrackingError>());
      final err = cubit.state as BusTrackingError;
      expect(err.message, contains('لم يتم العثور على حافلة'));
    });

    test('31. startTracking() continues and emits loaded with null position when location fails', () async {
      adapter.handler = (options) {
        if (options.path.contains('/bus/7/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {'trip_id': 'trip_77'},
              'passengers': []
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('/bus/7/location')) {
          return ResponseBody.fromString('Location Service Unavailable', 503);
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.startTracking();

      expect(cubit.state, isA<BusTrackingLoaded>());
      final loaded = cubit.state as BusTrackingLoaded;
      expect(loaded.position, isNull);
      expect(loaded.students, isEmpty);
    });
    test('32. startTracking() handles active trip failure and emits BusTrackingError', () async {
      adapter.handler = (options) {
        if (options.path.contains('/bus/7/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({'message': 'لا توجد رحلة نشطة حالياً'}),
            404,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.startTracking();

      expect(cubit.state, isA<BusTrackingError>());
      final err = cubit.state as BusTrackingError;
      expect(err.message, isNotEmpty);
    });

    test('33. startTracking() handles unnested location data and target coordinates', () async {
      adapter.handler = (options) {
        if (options.path.contains('/bus/7/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {'trip_id': 'trip_99'},
              'passengers': []
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('/bus/7/location')) {
          // Unnested data format
          return ResponseBody.fromString(
            jsonEncode({
              'latitude': 23.5880,
              'longitude': 58.3829,
              'target_lat': 23.6000,
              'target_lng': 58.4000,
              'speed_kmh': 40.0,
              'students_on_board': 5,
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.startTracking();

      expect(cubit.state, isA<BusTrackingLoaded>());
      final loaded = cubit.state as BusTrackingLoaded;
      expect(loaded.position?.lat, 23.5880);
      expect(loaded.position?.lng, 58.3829);
      expect(loaded.position?.targetLat, 23.6000);
      expect(loaded.position?.targetLng, 58.4000);
      expect(loaded.position?.studentsOnBoard, 5);
    });

    test('34. startTracking(silent: true) does not emit BusTrackingLoading', () async {
      final states = <BusTrackingState>[];
      cubit.stream.listen(states.add);

      adapter.handler = (options) => throw DioException(requestOptions: options);

      await cubit.startTracking(silent: true);

      expect(states.whereType<BusTrackingLoading>(), isEmpty);
    });

    test('35. startTracking() with zero coordinates leaves position as null', () async {
      adapter.handler = (options) {
        if (options.path.contains('/bus/7/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {'trip_id': 'trip_100'},
              'passengers': []
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('/bus/7/location')) {
          return ResponseBody.fromString(
            jsonEncode({
              'latitude': 0.0,
              'longitude': 0.0,
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await cubit.startTracking();

      expect(cubit.state, isA<BusTrackingLoaded>());
      final loaded = cubit.state as BusTrackingLoaded;
      expect(loaded.position, isNull);
    });

    test('36. BusTrackingState props verification', () {
      expect(BusTrackingInitial().props, isEmpty);
      expect(BusTrackingLoading().props, isEmpty);
      expect(const BusTrackingError('err').props, ['err']);
      const loaded = BusTrackingLoaded(null, []);
      expect(loaded.props, [null, <BusStudentEntity>[]]);
    });
  });
}

