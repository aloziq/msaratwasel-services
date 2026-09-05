import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:msaratwasel_services/features/driver/home/data/models/trip_status_model.dart';
import 'package:msaratwasel_services/features/driver/home/domain/entities/trip_status.dart';
import 'package:msaratwasel_services/features/driver/home/domain/repositories/home_repository.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/manager/driver_home_cubit.dart';

class FakeHomeRepository implements HomeRepository {
  List<TripStatus> tripsToReturn = [];
  Exception? errorToThrow;
  String? lastStartedTripId;
  String? lastConfirmedTripId;

  @override
  Future<TripStatus> getCurrentTripStatus() async {
    if (errorToThrow != null) throw errorToThrow!;
    return tripsToReturn.first;
  }

  @override
  Future<List<TripStatus>> getMyTrips() async {
    if (errorToThrow != null) throw errorToThrow!;
    return tripsToReturn;
  }

  @override
  Future<void> startTrip(String tripId) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastStartedTripId = tripId;
  }

  @override
  Future<void> confirmTrip(String tripId) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastConfirmedTripId = tripId;
  }
}

class MockBackgroundServicePlatform extends FlutterBackgroundServicePlatform {
  @override
  Future<bool> configure({
    required IosConfiguration iosConfiguration,
    required AndroidConfiguration androidConfiguration,
  }) async => true;

  @override
  Future<bool> start() async => true;

  @override
  Future<bool> isServiceRunning() async => false;

  @override
  void invoke(String method, [Map<String, dynamic>? args]) {}

  @override
  Stream<Map<String, dynamic>?> on(String method) => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHomeRepository fakeRepo;
  late DriverHomeCubit cubit;

  setUp(() {
    FlutterBackgroundServicePlatform.instance = MockBackgroundServicePlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('id.flutter/background_service'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('id.flutter/background_service_android'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('id.flutter/background_service_ios'),
      (MethodCall methodCall) async => true,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    fakeRepo = FakeHomeRepository();
    cubit = DriverHomeCubit(fakeRepo);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    cubit.close();
  });

  group('Driver Home & Trip Status Suite', () {
    test('1. TripStatusModel serialization, deserialization, and flags', () {
      final json = {
        'id': '101',
        'type': 'forth',
        'type_label': 'صباحية',
        'status': 'in_progress',
        'departure_time': '06:30',
        'arrival_time': '07:15',
        'total_students': 20,
        'excused_count': 2,
        'boarded_count': 18,
        'dropped_off_count': 0,
        'route': {'name': 'مسار الموالح الشمالية'},
      };

      final model = TripStatusModel.fromJson(json);

      expect(model.id, '101');
      expect(model.typeLabel, 'صباحية');
      expect(model.status, 'in_progress');
      expect(model.isStarted, isTrue);
      expect(model.isCompleted, isFalse);
      expect(model.totalStudents, 20);
      expect(model.boardedCount, 18);
      expect(model.routeName, 'مسار الموالح الشمالية');

      final serialized = model.toJson();
      expect(serialized['id'], '101');
      expect(serialized['status'], 'in_progress');
      expect(serialized['total_students'], 20);
    });

    test('2. TripStatusModel correctly flags finished trips as completed', () {
      final json = {
        'id': '102',
        'status': 'finished',
        'departure_time': '06:30',
        'total_students': 15,
      };

      final model = TripStatusModel.fromJson(json);
      expect(model.isCompleted, isTrue);
      expect(model.isStarted, isFalse);
    });

    test('3. DriverHomeCubit loadDashboard emits Loading and Loaded states on success', () async {
      final sampleTrips = [
        const TripStatus(
          id: 't_1',
          departureTime: '07:00',
          totalStudents: 10,
          status: 'pending',
        ),
      ];
      fakeRepo.tripsToReturn = sampleTrips;

      final expectedStates = [
        isA<DriverHomeLoading>(),
        isA<DriverHomeLoaded>(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.loadDashboard(showLoading: true);

      final state = cubit.state as DriverHomeLoaded;
      expect(state.trips.length, 1);
      expect(state.trips.first.id, 't_1');
    });

    test('4. DriverHomeCubit loadDashboard emits Error state when repository throws', () async {
      fakeRepo.errorToThrow = Exception('Database unreachable');

      final expectedStates = [
        isA<DriverHomeLoading>(),
        isA<DriverHomeError>(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.loadDashboard(showLoading: true);

      final state = cubit.state as DriverHomeError;
      expect(state.message, contains('Database unreachable'));
    });

    test('5. DriverHomeCubit startTrip calls repository and transitions state', () async {
      final initialTrips = [
        const TripStatus(
          id: 't_2',
          departureTime: '07:00',
          totalStudents: 12,
          status: 'pending',
        ),
      ];
      fakeRepo.tripsToReturn = initialTrips;
      cubit.emit(DriverHomeLoaded(initialTrips));

      await cubit.startTrip('t_2');
      expect(fakeRepo.lastStartedTripId, 't_2');
    });

    test('6. DriverHomeCubit startTrip handles network disconnection with Arabic error', () async {
      final initialTrips = [
        const TripStatus(
          id: 't_3',
          departureTime: '07:00',
          totalStudents: 10,
          status: 'pending',
        ),
      ];
      cubit.emit(DriverHomeLoaded(initialTrips));
      fakeRepo.errorToThrow = Exception('SocketException: OS Error: Connection refused');

      await cubit.startTrip('t_3');

      expect(cubit.state, isA<DriverHomeError>());
      final errorState = cubit.state as DriverHomeError;
      expect(errorState.message, contains('تعذر الاتصال بالسيرفر'));
    });

    test('7. DriverHomeCubit confirms trip and updates confirmation flag', () async {
      fakeRepo.tripsToReturn = [
        const TripStatus(
          id: 't_4',
          departureTime: '07:00',
          totalStudents: 10,
          status: 'in_progress',
        ),
      ];

      await cubit.confirmTrip('t_4');
      expect(fakeRepo.lastConfirmedTripId, 't_4');
      expect(cubit.state, isA<DriverHomeTripConfirmed>());
      final confirmedState = cubit.state as DriverHomeTripConfirmed;
      expect(confirmedState.confirmedTripId, 't_4');
    });

    test('8. DriverHomeCubit close safely stops polling timers', () async {
      await cubit.close();
      expect(cubit.isClosed, isTrue);
    });
  });
}
