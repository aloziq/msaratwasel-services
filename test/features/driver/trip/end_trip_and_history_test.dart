import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/features/driver/trip/data/models/trip_history_model.dart';
import 'package:msaratwasel_services/features/driver/trip/domain/repositories/trip_history_repository.dart';
import 'package:msaratwasel_services/features/driver/trip/domain/repositories/trip_repository.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/manager/end_trip_cubit.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/manager/trip_history_cubit.dart';

class FakeTripRepository implements TripRepository {
  bool endTripCalled = false;
  String? lastVideoPath;
  String? lastStartQr;
  String? lastEndQr;
  Exception? errorToThrow;

  @override
  Future<void> endTrip({
    required String videoPath,
    required String startQrData,
    required String endQrData,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    endTripCalled = true;
    lastVideoPath = videoPath;
    lastStartQr = startQrData;
    lastEndQr = endQrData;
    if (onProgress != null) {
      onProgress(50, 100);
      onProgress(100, 100);
    }
  }

  @override
  Future<void> checkTripReadiness() async {}

  @override
  Future<void> updateStudentStatus(
    String studentId, {
    bool? isAbsent,
    bool? isBoarded,
    bool? isDroppedOff,
  }) async {}
}

class FakeTripHistoryRepository implements TripHistoryRepository {
  Either<Failure, TripHistoryResponse>? resultToReturn;

  @override
  Future<Either<Failure, TripHistoryResponse>> getTripsHistory({
    String? startDate,
    String? endDate,
    String? status,
    int? page = 1,
  }) async {
    return resultToReturn ?? const Left(ServerFailure('Default error'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EndTrip Verification State Machine Suite', () {
    late FakeTripRepository fakeTripRepo;
    late EndTripCubit endTripCubit;

    setUp(() {
      fakeTripRepo = FakeTripRepository();
      endTripCubit = EndTripCubit(fakeTripRepo);
    });

    tearDown(() {
      endTripCubit.close();
    });

    test('1. EndTrip initial state is EndTripInitial', () {
      expect(endTripCubit.state, isA<EndTripInitial>());
    });

    test('2. Step-by-step verification pipeline transitions correctly', () async {
      // Step 1: Scan front QR
      endTripCubit.scanFrontQr('QR_FRONT_123');
      expect(endTripCubit.state, isA<EndTripRecording>());

      // Step 2: Record verification walk video
      endTripCubit.prepareScanBack('/path/to/bus_video.mp4');
      expect(endTripCubit.state, isA<EndTripScanningBack>());

      // Step 3: Scan back QR
      endTripCubit.scanBackQr('QR_BACK_456');
      expect(endTripCubit.state, isA<EndTripCompressing>());

      // Step 4: Progress upload
      endTripCubit.updateUploadProgress(0.75);
      expect(endTripCubit.state, isA<EndTripUploading>());
      expect((endTripCubit.state as EndTripUploading).progress, 0.75);

      // Step 5: Finalize upload
      await endTripCubit.finalizeUpload('/path/to/compressed_video.mp4');
      expect(fakeTripRepo.endTripCalled, isTrue);
      expect(fakeTripRepo.lastStartQr, 'QR_FRONT_123');
      expect(fakeTripRepo.lastEndQr, 'QR_BACK_456');
      expect(fakeTripRepo.lastVideoPath, '/path/to/compressed_video.mp4');
      expect(endTripCubit.state, isA<EndTripSuccess>());

      // Restart resets to initial
      endTripCubit.restart();
      expect(endTripCubit.state, isA<EndTripInitial>());
    });

    test('3. submitTripEnd fails with Error if any verification item is missing', () async {
      endTripCubit.scanFrontQr('QR_FRONT_123');
      // Did not prepare video, did not scan back
      await endTripCubit.submitTripEnd();

      expect(endTripCubit.state, isA<EndTripError>());
      final err = endTripCubit.state as EndTripError;
      expect(err.message, 'بيانات التحقق غير مكتملة');
    });

    test('4. finalizeUpload emits Error if repository fails', () async {
      endTripCubit.scanFrontQr('QR_FRONT_123');
      endTripCubit.prepareScanBack('/path/video.mp4');
      endTripCubit.scanBackQr('QR_BACK_456');

      fakeTripRepo.errorToThrow = Exception('Upload timeout');

      await endTripCubit.finalizeUpload('/path/video.mp4');

      expect(endTripCubit.state, isA<EndTripError>());
      final err = endTripCubit.state as EndTripError;
      expect(err.message, contains('Upload timeout'));
    });

    test('4b. EndTripCubit handles restart, checkTripReadiness, startCompressing, and incomplete data error', () async {
      // Test restart
      endTripCubit.scanFrontQr('QR1');
      expect(endTripCubit.state, isA<EndTripRecording>());
      endTripCubit.restart();
      expect(endTripCubit.state, isA<EndTripInitial>());

      // Test checkTripReadiness
      await endTripCubit.checkTripReadiness();

      // Test startCompressing
      endTripCubit.startCompressing();
      expect(endTripCubit.state, isA<EndTripCompressing>());

      // Test submitTripEnd with incomplete data
      final freshCubit = EndTripCubit(fakeTripRepo);
      await freshCubit.submitTripEnd();
      expect(freshCubit.state, isA<EndTripError>());
      expect((freshCubit.state as EndTripError).message, 'بيانات التحقق غير مكتملة');
      await freshCubit.close();

      // Test finalizeUpload error
      fakeTripRepo.errorToThrow = Exception('Upload network dropped');
      endTripCubit.scanFrontQr('QR_A');
      endTripCubit.prepareScanBack('video.mp4');
      endTripCubit.scanBackQr('QR_B');
      await endTripCubit.finalizeUpload('video.mp4');
      expect(endTripCubit.state, isA<EndTripError>());
      expect((endTripCubit.state as EndTripError).message, contains('Upload network dropped'));

      // Check state props
      expect(EndTripInitial().props, isEmpty);
      expect(EndTripScanningFront().props, isEmpty);
      expect(EndTripRecording().props, isEmpty);
      expect(EndTripScanningBack().props, isEmpty);
      expect(EndTripCompressing().props, isEmpty);
      expect(const EndTripUploading(0.5).props, [0.5]);
      expect(EndTripSuccess().props, isEmpty);
      expect(const EndTripError('err').props, ['err']);
    });
  });

  group('TripHistory Models & Cubit Suite', () {
    late FakeTripHistoryRepository fakeHistoryRepo;
    late TripHistoryCubit historyCubit;

    setUp(() {
      fakeHistoryRepo = FakeTripHistoryRepository();
      historyCubit = TripHistoryCubit(fakeHistoryRepo);
    });

    tearDown(() {
      historyCubit.close();
    });

    test('5. TripHistoryModel and RouteModel JSON serialization/deserialization', () {
      final json = {
        'id': 10,
        'type': 'forth',
        'type_label': 'ذهاب',
        'status': 'finished',
        'trip_date': '2026-09-04',
        'total_students': 18,
        'departure_time': '06:45',
        'arrival_time': '07:25',
        'route': {'id': 5, 'name': 'مسار رقم 5'},
      };

      final model = TripHistoryModel.fromJson(json);

      expect(model.id, 10);
      expect(model.typeLabel, 'ذهاب');
      expect(model.status, 'finished');
      expect(model.totalStudents, 18);
      expect(model.route?.name, 'مسار رقم 5');

      final serialized = model.toJson();
      expect(serialized['id'], 10);
      expect(serialized['route']['id'], 5);
    });

    test('6. TripHistoryCubit loadTrips emits Loading and Loaded on success and filterTrips works', () async {
      final sampleResponse = TripHistoryResponse(
        trips: [
          TripHistoryModel(
            id: 1,
            type: 'forth',
            typeLabel: 'ذهاب',
            status: 'finished',
            tripDate: '2026-09-04',
            totalStudents: 15,
          ),
        ],
        pagination: PaginationModel(
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
        filters: FiltersModel(
          startDate: '2026-09-01',
          endDate: '2026-09-04',
        ),
      );

      fakeHistoryRepo.resultToReturn = Right(sampleResponse);

      final expectedStates = [
        isA<TripHistoryLoading>(),
        isA<TripHistoryLoaded>(),
      ];

      expectLater(historyCubit.stream, emitsInOrder(expectedStates));
      await historyCubit.loadTrips();

      final state = historyCubit.state as TripHistoryLoaded;
      expect(state.response.trips.length, 1);
      expect(state.response.trips.first.id, 1);
      expect(state.props, [sampleResponse]);

      // Test filterTrips
      await historyCubit.filterTrips(startDate: '2026-09-01', endDate: '2026-09-04', status: 'finished');
      expect(historyCubit.state, isA<TripHistoryLoaded>());

      // Test State props
      expect(TripHistoryInitial().props, isEmpty);
      expect(TripHistoryLoading().props, isEmpty);
      expect(const TripHistoryError('err').props, ['err']);
    });

    test('7. TripHistoryCubit loadTrips emits Error on failure', () async {
      fakeHistoryRepo.resultToReturn = const Left(ServerFailure('Server error 500'));

      final expectedStates = [
        isA<TripHistoryLoading>(),
        isA<TripHistoryError>(),
      ];

      expectLater(historyCubit.stream, emitsInOrder(expectedStates));
      await historyCubit.loadTrips();

      final state = historyCubit.state as TripHistoryError;
      expect(state.message, 'Server error 500');
    });
  });
}
