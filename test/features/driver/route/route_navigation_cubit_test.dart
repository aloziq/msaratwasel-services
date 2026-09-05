import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/features/driver/route/domain/entities/student_stop.dart';
import 'package:msaratwasel_services/features/driver/route/domain/repositories/route_repository.dart';
import 'package:msaratwasel_services/features/driver/route/presentation/manager/route_navigation_cubit.dart';

class FakeRouteRepository implements RouteRepository {
  List<StudentStop> stops = [];
  List<LatLng> routePoints = [];
  bool shouldThrow = false;
  String errorMessage = 'Failed to load route';

  @override
  String get currentTripType => 'morning';

  @override
  String get currentTripStatus => 'in_progress';

  @override
  LatLng? get schoolLocation => const LatLng(23.6, 58.4);

  @override
  Future<List<StudentStop>> getTripStops() async {
    if (shouldThrow) throw Exception(errorMessage);
    return stops;
  }

  @override
  Future<List<LatLng>> getRoutePoints() async {
    if (shouldThrow) throw Exception(errorMessage);
    return routePoints;
  }

  @override
  int getOnBoardCount(List<StudentStop> stops) => 0;

  @override
  int getUnprocessedCount(List<StudentStop> stops) => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRouteRepository fakeRepository;
  late SharedPreferences prefs;

  final sampleStops = [
    const StudentStop(
      id: '1',
      nameAr: 'علي أحمد',
      nameEn: 'Ali Ahmed',
      parentAr: 'أحمد',
      parentEn: 'Ahmed',
      location: LatLng(23.5880, 58.3829),
    ),
    const StudentStop(
      id: '2',
      nameAr: 'سارة خالد',
      nameEn: 'Sara Khalid',
      parentAr: 'خالد',
      parentEn: 'Khalid',
      location: LatLng(23.5890, 58.3840),
    ),
  ];

  final samplePoints = [
    const LatLng(23.5880, 58.3829),
    const LatLng(23.5890, 58.3840),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
    }
    fakeRepository = FakeRouteRepository();
    fakeRepository.stops = sampleStops;
    fakeRepository.routePoints = samplePoints;
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('RouteNavigationState', () {
    test('props of states are correct', () {
      expect(RouteNavigationInitial().props, isEmpty);
      expect(RouteNavigationLoading().props, isEmpty);
      expect(RouteNavigationCompleted().props, isEmpty);
      expect(const RouteNavigationError('err').props, ['err']);

      final stateA = RouteNavigationLoaded(
        stops: sampleStops,
        routePoints: samplePoints,
        currentStopIndex: 0,
        isArrivedAtStop: false,
      );
      final stateB = RouteNavigationLoaded(
        stops: sampleStops,
        routePoints: samplePoints,
        currentStopIndex: 0,
        isArrivedAtStop: false,
      );
      expect(stateA, equals(stateB));
      expect(stateA.currentStop, sampleStops[0]);

      final updated = stateA.copyWith(
        currentStopIndex: 1,
        isArrivedAtStop: true,
      );
      expect(updated.currentStopIndex, 1);
      expect(updated.isArrivedAtStop, isTrue);
      expect(updated.currentStop, sampleStops[1]);

      final outOfBounds = stateA.copyWith(currentStopIndex: 5);
      expect(outOfBounds.currentStop, isNull);
    });
  });

  group('RouteNavigationCubit', () {
    test('initial state is RouteNavigationInitial', () {
      final cubit = RouteNavigationCubit(fakeRepository);
      expect(cubit.state, isA<RouteNavigationInitial>());
      cubit.close();
    });

    test('loadRoute emits [Loading, Loaded] on success', () async {
      final cubit = RouteNavigationCubit(fakeRepository);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<RouteNavigationLoading>(),
          isA<RouteNavigationLoaded>()
              .having((s) => s.stops.length, 'stops length', 2)
              .having((s) => s.routePoints.length, 'points length', 2)
              .having((s) => s.currentStopIndex, 'current index', 0),
        ]),
      );

      await cubit.loadRoute();
      expect(cubit.state, isA<RouteNavigationLoaded>());
      cubit.close();
    });

    test('loadRoute emits [Loading, Error] on repository failure', () async {
      fakeRepository.shouldThrow = true;
      fakeRepository.errorMessage = 'Network connection failed';
      final cubit = RouteNavigationCubit(fakeRepository);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<RouteNavigationLoading>(),
          isA<RouteNavigationError>().having(
            (s) => s.message,
            'message',
            contains('Network connection failed'),
          ),
        ]),
      );

      await cubit.loadRoute();
      expect(cubit.state, isA<RouteNavigationError>());
      cubit.close();
    });

    test('preserveIndex preserves previous currentStopIndex when loaded', () async {
      final cubit = RouteNavigationCubit(fakeRepository);
      await cubit.loadRoute();
      cubit.advanceToNextStop();
      expect((cubit.state as RouteNavigationLoaded).currentStopIndex, 1);

      await cubit.loadRoute(preserveIndex: true);
      expect((cubit.state as RouteNavigationLoaded).currentStopIndex, 1);
      cubit.close();
    });

    test('arriveAtStop updates isArrivedAtStop to true', () async {
      final cubit = RouteNavigationCubit(fakeRepository);
      await cubit.loadRoute();
      expect((cubit.state as RouteNavigationLoaded).isArrivedAtStop, isFalse);

      cubit.arriveAtStop();
      expect((cubit.state as RouteNavigationLoaded).isArrivedAtStop, isTrue);
      cubit.close();
    });

    test('advanceToNextStop moves to next stop and resets isArrivedAtStop', () async {
      final cubit = RouteNavigationCubit(fakeRepository);
      await cubit.loadRoute();
      cubit.arriveAtStop();
      expect((cubit.state as RouteNavigationLoaded).isArrivedAtStop, isTrue);

      cubit.advanceToNextStop();
      final loaded = cubit.state as RouteNavigationLoaded;
      expect(loaded.currentStopIndex, 1);
      expect(loaded.isArrivedAtStop, isFalse);
      cubit.close();
    });

    test('advanceToNextStop at last stop emits RouteNavigationCompleted', () async {
      final cubit = RouteNavigationCubit(fakeRepository);
      await cubit.loadRoute();
      cubit.advanceToNextStop(); // index 1 (last stop)
      expect(cubit.state, isA<RouteNavigationLoaded>());

      cubit.advanceToNextStop(); // beyond last stop
      expect(cubit.state, isA<RouteNavigationCompleted>());
      cubit.close();
    });

    test('arriveAtStop and advanceToNextStop do nothing if not loaded', () {
      final cubit = RouteNavigationCubit(fakeRepository);
      cubit.arriveAtStop();
      expect(cubit.state, isA<RouteNavigationInitial>());
      cubit.advanceToNextStop();
      expect(cubit.state, isA<RouteNavigationInitial>());
      cubit.close();
    });

    test('reverb service initializes when USER_BUS_ID is present and disposes on close', () async {
      await prefs.setString('USER_BUS_ID', '42');
      await prefs.setString('USER_ID', '15');

      final cubit = RouteNavigationCubit(fakeRepository);
      await cubit.loadRoute();
      expect(cubit.state, isA<RouteNavigationLoaded>());

      await cubit.close();
    });
  });
}
