import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/usecases/usecase.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/domain/entities/fleet_bus.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/data/models/fleet_bus_model.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/domain/repositories/fleet_repository.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/domain/usecases/get_fleet_buses_usecase.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/presentation/cubit/fleet_tracking_cubit.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/data/datasources/fleet_remote_datasource.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/data/repositories/fleet_repository_impl.dart';

class _FakeFleetHttpAdapter implements HttpClientAdapter {
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
      jsonEncode({'data': [], 'success': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeFleetRepository implements FleetRepository {
  Either<Failure, List<FleetBus>>? resultToReturn;

  @override
  Future<Either<Failure, List<FleetBus>>> getFleetBuses() async {
    return resultToReturn ?? const Right([]);
  }

  @override
  Future<Either<Failure, dynamic>> getBusDetails(String busId) async {
    return const Right(null);
  }
}

void main() {
  late FakeFleetRepository fakeRepo;
  late GetFleetBusesUseCase usecase;
  late FleetTrackingCubit cubit;

  final testDate = DateTime.parse('2026-09-04T08:30:00.000Z');

  final busActive = FleetBusModel(
    id: 'bus_1',
    name: 'Bus 101',
    driverName: 'Driver Ahmed',
    supervisorName: 'Assistant Mona',
    schoolName: 'Al-Rowad School',
    driverPhone: '0551234567',
    route: 'Northern Route',
    lat: 24.7136,
    lng: 46.6753,
    speedKmh: 45.0,
    studentsOnBoard: 12,
    status: FleetBusStatus.active,
    updatedAt: testDate,
  );

  final busStopped = FleetBusModel(
    id: 'bus_2',
    name: 'Bus 102',
    driverName: 'Driver Khaled',
    supervisorName: 'Assistant Sara',
    schoolName: 'Al-Rowad School',
    driverPhone: '0557654321',
    route: 'Southern Route',
    lat: 24.7200,
    lng: 46.6800,
    speedKmh: 0.0,
    studentsOnBoard: 0,
    status: FleetBusStatus.stopped,
    updatedAt: testDate,
  );

  final busMaintenance = FleetBusModel(
    id: 'bus_3',
    name: 'Bus 103',
    driverName: 'Driver Omar',
    supervisorName: 'Assistant Fatima',
    schoolName: 'Al-Rowad School',
    driverPhone: '0559876543',
    route: 'Eastern Route',
    lat: 24.7300,
    lng: 46.6900,
    speedKmh: 0.0,
    studentsOnBoard: 0,
    status: FleetBusStatus.maintenance,
    updatedAt: testDate,
  );

  setUp(() {
    fakeRepo = FakeFleetRepository();
    usecase = GetFleetBusesUseCase(fakeRepo);
    cubit = FleetTrackingCubit(usecase);
  });

  tearDown(() {
    cubit.close();
  });

  group('FleetBusModel Parsing & Serialization', () {
    test('1. fromJson correctly parses full payload with snake_case and camelCase fallbacks', () {
      final json = {
        'id': 1234,
        'bus_code': 'Bus 55',
        'driver': 'Driver Tariq',
        'supervisor': 'Assistant Huda',
        'field_supervisor': 'Supervisor Fahad',
        'front_qr': 'https://api.msaratwasel.com/qr/front55.png',
        'back_qr': 'https://api.msaratwasel.com/qr/back55.png',
        'school': 'King Fahd Academy',
        'driverPhone': '0550001111',
        'route': 'Central Route',
        'location_lat': 24.75,
        'location_lng': 46.72,
        'speed_kmh': 55.5,
        'studentsOnBoard': 18,
        'status': 'active',
        'last_update': '2026-09-04T08:30:00.000Z',
      };

      final model = FleetBusModel.fromJson(json);

      expect(model.id, '1234');
      expect(model.name, 'Bus 55');
      expect(model.driverName, 'Driver Tariq');
      expect(model.supervisorName, 'Assistant Huda');
      expect(model.fieldSupervisorName, 'Supervisor Fahad');
      expect(model.frontQrUrl, 'https://api.msaratwasel.com/qr/front55.png');
      expect(model.backQrUrl, 'https://api.msaratwasel.com/qr/back55.png');
      expect(model.schoolName, 'King Fahd Academy');
      expect(model.lat, 24.75);
      expect(model.lng, 46.72);
      expect(model.speedKmh, 55.5);
      expect(model.studentsOnBoard, 18);
      expect(model.status, FleetBusStatus.active);
      expect(model.updatedAt, testDate);
    });

    test('2. fromJson correctly falls back to stopped/defaults when fields are missing', () {
      final json = <String, dynamic>{
        'id': 'bus_fallback',
      };

      final model = FleetBusModel.fromJson(json);

      expect(model.id, 'bus_fallback');
      expect(model.name, '');
      expect(model.driverName, 'N/A');
      expect(model.supervisorName, 'N/A');
      expect(model.schoolName, 'N/A');
      expect(model.lat, 0.0);
      expect(model.lng, 0.0);
      expect(model.status, FleetBusStatus.stopped);
    });

    test('3. toJson formats FleetBusModel matching outgoing contract', () {
      final json = busActive.toJson();

      expect(json['id'], 'bus_1');
      expect(json['name'], 'Bus 101');
      expect(json['driverName'], 'Driver Ahmed');
      expect(json['schoolName'], 'Al-Rowad School');
      expect(json['lat'], 24.7136);
      expect(json['lng'], 46.6753);
      expect(json['speedKmh'], 45.0);
      expect(json['studentsOnBoard'], 12);
      expect(json['status'], 'active');
      expect(json['updatedAt'], testDate.toIso8601String());
    });
  });

  group('FleetTrackingCubit & State Machine', () {
    test('4. Initial state is FleetTrackingInitial', () {
      expect(cubit.state, equals(FleetTrackingInitial()));
    });

    test('5. loadFleet emits FleetTrackingLoading and FleetTrackingLoaded on success', () async {
      fakeRepo.resultToReturn = Right([busActive, busStopped, busMaintenance]);

      final states = <FleetTrackingState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadFleet();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<FleetTrackingLoading>());
      expect(states[1], isA<FleetTrackingLoaded>());

      final loaded = states[1] as FleetTrackingLoaded;
      expect(loaded.buses.length, 3);
      expect(loaded.activeCount, 1);
      expect(loaded.stoppedCount, 1);
      expect(loaded.maintenanceCount, 1);
      expect(loaded.selectedBusId, isNull);
      expect(loaded.selectedBus, isNull);

      await subscription.cancel();
    });

    test('6. loadFleet emits FleetTrackingError when repository returns Failure', () async {
      fakeRepo.resultToReturn = const Left(ServerFailure('Connection error with fleet server'));

      final states = <FleetTrackingState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadFleet();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<FleetTrackingLoading>());
      expect(states[1], isA<FleetTrackingError>());

      final err = states[1] as FleetTrackingError;
      expect(err.message, contains('Connection error with fleet server'));

      await subscription.cancel();
    });

    test('7. selectBus and clearSelection update selection state accurately', () async {
      fakeRepo.resultToReturn = Right([busActive, busStopped, busMaintenance]);
      await cubit.loadFleet();

      cubit.selectBus('bus_2');
      expect(cubit.state, isA<FleetTrackingLoaded>());
      var loaded = cubit.state as FleetTrackingLoaded;
      expect(loaded.selectedBusId, 'bus_2');
      expect(loaded.selectedBus?.name, 'Bus 102');

      cubit.clearSelection();
      loaded = cubit.state as FleetTrackingLoaded;
      expect(loaded.selectedBusId, isNull);
      expect(loaded.selectedBus, isNull);
    });

    test('8. copyWith correctly handles partial and clearSelection updates', () {
      final initialLoaded = FleetTrackingLoaded([busActive], selectedBusId: 'bus_1');

      final updated = initialLoaded.copyWith(clearSelection: true);
      expect(updated.selectedBusId, isNull);

      final reSelected = updated.copyWith(selectedBusId: 'bus_1');
      expect(reSelected.selectedBusId, 'bus_1');
    });
  });

  group('FleetRemoteDataSourceImpl & FleetRepositoryImpl Direct Suite', () {
    late _FakeFleetHttpAdapter fakeHttp;
    late Dio testDio;

    setUp(() {
      fakeHttp = _FakeFleetHttpAdapter();
      testDio = Dio(BaseOptions(baseUrl: 'https://test.msaratwasel.com/api/'));
      testDio.httpClientAdapter = fakeHttp;
      ApiClient.testDio = testDio;
    });

    tearDown(() {
      ApiClient.testDio = null;
    });

    test('9. FleetRemoteDataSourceImpl fetches and maps fleet buses on 200 success', () async {
      fakeHttp.handler = (options) {
        if (options.path.contains('field/buses')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 701,
                  'bus_code': 'حافلة 701',
                  'bus_number': '701',
                  'driver': 'سالم السائق',
                  'supervisor': 'فاطمة المشرفة',
                  'field_supervisor': 'مشرف الميدان',
                  'front_qr': 'https://example.com/qr1.png',
                  'back_qr': 'https://example.com/qr2.png',
                  'school': 'مدرسة الأمل',
                  'location_lat': 23.5880,
                  'location_lng': 58.3820,
                  'speed_kmh': 42.0,
                  'status': 'active',
                  'last_update': '2026-09-04T08:00:00.000Z',
                },
                {
                  'id': 702,
                  'status': 'maintenance',
                  'last_update': null,
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final dataSource = FleetRemoteDataSourceImpl();
      final buses = await dataSource.getFleetBuses();

      expect(buses.length, 2);
      expect(buses[0].id, '701');
      expect(buses[0].name, 'حافلة 701');
      expect(buses[0].driverName, 'سالم السائق');
      expect(buses[0].supervisorName, 'فاطمة المشرفة');
      expect(buses[0].fieldSupervisorName, 'مشرف الميدان');
      expect(buses[0].lat, 23.5880);
      expect(buses[0].lng, 58.3820);
      expect(buses[0].speedKmh, 42.0);
      expect(buses[0].status, FleetBusStatus.active);

      expect(buses[1].id, '702');
      expect(buses[1].status, FleetBusStatus.maintenance);
    });

    test('10. FleetRemoteDataSourceImpl returns empty list on network failure or non-200', () async {
      fakeHttp.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Server down'}),
          500,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final dataSource = FleetRemoteDataSourceImpl();
      final buses = await dataSource.getFleetBuses();
      expect(buses, isEmpty);
    });

    test('11. FleetRepositoryImpl wraps remote data in Right on success and Left on throw', () async {
      final dataSource = FleetRemoteDataSourceImpl();
      fakeHttp.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 99,
                'status': 'stopped',
              }
            ]
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final repo = FleetRepositoryImpl(remoteDataSource: dataSource);
      final result = await repo.getFleetBuses();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected right but got $failure'),
        (list) {
          expect(list.length, 1);
          expect(list.first.id, '99');
          expect(list.first.status, FleetBusStatus.stopped);
        },
      );
    });
  });
}

