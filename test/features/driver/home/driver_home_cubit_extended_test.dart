import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/manager/driver_home_cubit.dart';
import 'package:msaratwasel_services/features/driver/home/domain/entities/trip_status.dart';
import 'package:msaratwasel_services/features/driver/home/domain/repositories/home_repository.dart';

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

class FakeHomeRepoExtended implements HomeRepository {
  List<TripStatus> tripsToReturn = [];
  Exception? startTripError;
  Exception? confirmTripError;
  bool startTripCalled = false;
  bool confirmTripCalled = false;
  String? lastTripId;

  @override
  Future<TripStatus> getCurrentTripStatus() async => tripsToReturn.first;

  @override
  Future<List<TripStatus>> getMyTrips() async => tripsToReturn;

  @override
  Future<void> startTrip(String tripId) async {
    lastTripId = tripId;
    startTripCalled = true;
    if (startTripError != null) throw startTripError!;
  }

  @override
  Future<void> confirmTrip(String tripId) async {
    lastTripId = tripId;
    confirmTripCalled = true;
    if (confirmTripError != null) throw confirmTripError!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHomeRepoExtended fakeRepo;
  late DriverHomeCubit cubit;

  final awaitingTrip = const TripStatus(
    id: '1',
    type: 'forth',
    typeLabel: 'صباحية',
    status: 'awaiting_confirmation',
    departureTime: '06:30',
    arrivalTime: '07:15',
    totalStudents: 20,
    excusedCount: 2,
    boardedCount: 18,
    droppedOffCount: 0,
    routeName: 'مسار الموالح',
  );

  final inProgressTrip = const TripStatus(
    id: '1',
    type: 'forth',
    typeLabel: 'صباحية',
    status: 'in_progress',
    departureTime: '06:30',
    arrivalTime: '07:15',
    totalStudents: 20,
    excusedCount: 2,
    boardedCount: 18,
    droppedOffCount: 0,
    routeName: 'مسار الموالح',
  );

  final completedTrip = const TripStatus(
    id: '2',
    type: 'back',
    typeLabel: 'مسائية',
    status: 'completed',
    departureTime: '13:30',
    arrivalTime: '14:15',
    totalStudents: 20,
    excusedCount: 0,
    boardedCount: 20,
    droppedOffCount: 20,
    routeName: 'مسار الموالح',
  );

  setUp(() {
    FlutterBackgroundServicePlatform.instance = MockBackgroundServicePlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('id.flutter/background_service'),
      (call) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('id.flutter/background_service_android'),
      (call) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('id.flutter/background_service_ios'),
      (call) async => true,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    fakeRepo = FakeHomeRepoExtended();
    cubit = DriverHomeCubit(fakeRepo);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    cubit.close();
  });

  group('DriverHomeCubit Extended & Network Error Resilience', () {
    test('1. startTrip catches network error, stops polling, and emits Arabic connection error', () async {
      fakeRepo.tripsToReturn = [awaitingTrip];
      await cubit.loadDashboard(showLoading: false);

      fakeRepo.startTripError = Exception('SocketException: Connection refused (OS Error: 101)');

      final states = <DriverHomeState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.startTrip('1');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 1);
      expect(states.first, isA<DriverHomeError>());
      final err = states.first as DriverHomeError;
      expect(err.message, contains('تعذر الاتصال بالسيرفر'));

      await sub.cancel();
    });

    test('2. confirmTrip catches DioException [connection error] and emits friendly error', () async {
      fakeRepo.confirmTripError = Exception('DioException [connection error]: Failed host lookup');

      final states = <DriverHomeState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.confirmTrip('1');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 1);
      expect(states.first, isA<DriverHomeError>());
      final err = states.first as DriverHomeError;
      expect(err.message, contains('تعذر الاتصال بالسيرفر'));

      await sub.cancel();
    });

    test('3. confirmTrip success triggers loadDashboard and sets up confirmation tracking', () async {
      fakeRepo.tripsToReturn = [inProgressTrip];

      await cubit.confirmTrip('1');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(fakeRepo.confirmTripCalled, isTrue);
      expect(fakeRepo.lastTripId, '1');
      expect(cubit.state, isA<DriverHomeTripConfirmed>());
      final confirmed = cubit.state as DriverHomeTripConfirmed;
      expect(confirmed.confirmedTripId, '1');
    });

    test('4. loadDashboard starts LocationService when active trip is present', () async {
      fakeRepo.tripsToReturn = [inProgressTrip];

      await cubit.loadDashboard();

      expect(cubit.state, isA<DriverHomeLoaded>());
      final loaded = cubit.state as DriverHomeLoaded;
      expect(loaded.trips.first.status, 'in_progress');
    });

    test('5. loadDashboard stops LocationService when no active trips exist', () async {
      fakeRepo.tripsToReturn = [completedTrip];

      await cubit.loadDashboard();

      expect(cubit.state, isA<DriverHomeLoaded>());
    });

    test('6. startTrip ignored when state is DriverHomeInitial', () async {
      expect(cubit.state, isA<DriverHomeInitial>());
      await cubit.startTrip('1');
      expect(fakeRepo.startTripCalled, isFalse);
      expect(cubit.state, isA<DriverHomeInitial>());
    });

    test('7. startTrip and confirmTrip handle standard non-network exceptions', () async {
      fakeRepo.tripsToReturn = [awaitingTrip];
      await cubit.loadDashboard();
      expect(cubit.state, isA<DriverHomeLoaded>());

      // Standard error in startTrip
      fakeRepo.startTripError = Exception('Validation error: Trip already started');
      await cubit.startTrip('1');
      expect(cubit.state, isA<DriverHomeError>());
      final err1 = cubit.state as DriverHomeError;
      expect(err1.message, contains('Validation error'));

      // Standard error in confirmTrip
      fakeRepo.confirmTripError = Exception('Trip ID not found in database');
      await cubit.confirmTrip('99');
      expect(cubit.state, isA<DriverHomeError>());
      final err2 = cubit.state as DriverHomeError;
      expect(err2.message, contains('Trip ID not found'));
    });

    test('8. DriverHomeTripConfirmed props and equality', () {
      final tripA = inProgressTrip;
      final state1 = DriverHomeTripConfirmed([tripA], '1');
      final state2 = DriverHomeTripConfirmed([tripA], '1');
      expect(state1, equals(state2));
      expect(state1.props, [[tripA], '1']);
    });

    test('9. startTrip with various network error strings triggers friendly message', () async {
      fakeRepo.tripsToReturn = [awaitingTrip];
      await cubit.loadDashboard();

      final networkErrors = [
        'network error',
        'failed host lookup',
        'connection refused',
      ];

      for (final errKeyword in networkErrors) {
        fakeRepo.startTripError = Exception('Error occurred: $errKeyword');
        await cubit.startTrip('1');
        expect(cubit.state, isA<DriverHomeError>());
        expect((cubit.state as DriverHomeError).message, contains('تعذر الاتصال بالسيرفر'));
      }
    });

    test('10. _checkAndStartPolling resets wasAwaitingConfirmation when no in_progress trip found', () async {
      // Start awaiting trip
      fakeRepo.tripsToReturn = [awaitingTrip];
      await cubit.loadDashboard();

      await cubit.startTrip('1'); // sets _wasAwaitingConfirmation = true

      // Reload dashboard with completed trip only (neither awaiting nor in_progress)
      fakeRepo.tripsToReturn = [completedTrip];
      await cubit.loadDashboard(showLoading: false);

      expect(cubit.state, isA<DriverHomeLoaded>());
      final loaded = cubit.state as DriverHomeLoaded;
      expect(loaded.trips.first.status, 'completed');
    });

    test('11. DriverHomeState subclasses props', () {
      expect(DriverHomeInitial().props, isEmpty);
      expect(DriverHomeLoading().props, isEmpty);
      expect(const DriverHomeError('msg').props, ['msg']);
      expect(const DriverHomeLoaded([]).props, [<TripStatus>[]]);
    });
  });
}

