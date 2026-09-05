import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_trip_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/repositories/assistant_repository.dart';
import 'package:msaratwasel_services/features/assistant/core/presentation/cubit/bus_trip_cubit.dart';

class FakeAssistantRepository implements AssistantRepository {
  Either<String, BusTripEntity>? getActiveTripResult;
  Either<String, void> confirmTripResult = const Right(null);
  Either<String, void> updateStudentStatusResult = const Right(null);

  String? lastConfirmedTripId;
  String? lastUpdatedStudentId;
  BusStudentStatus? lastUpdatedStatus;
  String? lastUpdatedDirection;

  @override
  Future<Either<String, BusTripEntity>> getActiveTrip() async {
    return getActiveTripResult ?? Left('No trip configured');
  }

  @override
  Future<Either<String, void>> confirmTrip(String tripId) async {
    lastConfirmedTripId = tripId;
    return confirmTripResult;
  }

  @override
  Future<Either<String, void>> updateStudentStatus(
    String studentId,
    BusStudentStatus status,
    String? direction,
  ) async {
    lastUpdatedStudentId = studentId;
    lastUpdatedStatus = status;
    lastUpdatedDirection = direction;
    return updateStudentStatusResult;
  }

  @override
  Future<Either<String, void>> groupAlight({
    required List<String> studentIds,
    required String direction,
  }) async => const Right(null);

  @override
  Future<Either<String, void>> groupBoard({
    required List<String> studentIds,
    required String direction,
  }) async => const Right(null);

  @override
  Future<Either<String, List<BusStudentEntity>>> getStudents() async => const Right([]);

  @override
  Future<Either<String, void>> submitIncidentReport({
    required String studentId,
    required String type,
    required String description,
  }) async => const Right(null);

  @override
  Future<Either<String, void>> submitDailyChecklist(Map<String, bool> items) async => const Right(null);

  @override
  Future<Either<String, void>> confirmEmptyBus() async => const Right(null);

  @override
  Future<Either<String, void>> sendAlertToDriver(String message) async => const Right(null);

  @override
  Future<Either<String, void>> updateBehavioralNote(String studentId, String note) async => const Right(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAssistantRepository fakeRepo;
  late BusTripCubit cubit;

  final sampleStudent = const BusStudentEntity(
    id: 'st_101',
    studentCode: 'CODE101',
    name: 'سالم أحمد',
    grade: 'الصف الثالث',
    schoolId: 'sch_1',
    parentName: 'أحمد',
    parentPhone: '91234567',
    status: BusStudentStatus.waiting,
  );

  final sampleActiveTrip = BusTripEntity(
    id: 'trip_55',
    busNumber: 'B-09',
    driverName: 'ناصر',
    assistantName: 'سارة',
    students: [sampleStudent],
    startTime: DateTime(2026, 9, 4, 7, 0),
    tripStatus: 'in_progress',
    suggestedDirection: 'to_school',
  );

  setUp(() {
    fakeRepo = FakeAssistantRepository();
    cubit = BusTripCubit(repository: fakeRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('BusTripCubit Baseline Suite', () {
    test('1. Initial state is BusTripInitial', () {
      expect(cubit.state, isA<BusTripInitial>());
    });

    test('2. loadTrip emits Loading then Loaded on success', () async {
      fakeRepo.getActiveTripResult = Right(sampleActiveTrip);

      final expectedStates = [
        isA<BusTripLoading>(),
        isA<BusTripLoaded>(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.loadTrip();

      final state = cubit.state as BusTripLoaded;
      expect(state.trip.id, 'trip_55');
      expect(state.trip.students.first.name, 'سالم أحمد');
    });

    test('3. loadTrip emits Loading then Error on failure', () async {
      fakeRepo.getActiveTripResult = const Left('Network error');

      final expectedStates = [
        isA<BusTripLoading>(),
        isA<BusTripError>(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.loadTrip();

      final state = cubit.state as BusTripError;
      expect(state.message, 'Network error');
    });

    test('4. updateStudentStatus blocks changes when trip is not active', () async {
      final inactiveTrip = sampleActiveTrip.copyWith(tripStatus: 'completed');
      cubit.emit(BusTripLoaded(inactiveTrip));

      await cubit.updateStudentStatus('st_101', BusStudentStatus.onBus);

      expect(cubit.state, isA<BusTripUpdateError>());
      final errorState = cubit.state as BusTripUpdateError;
      expect(errorState.message, contains('لا يمكن تعديل حالة الطلاب لعدم وجود رحلة نشطة حالياً'));
      // Verify repository was not called
      expect(fakeRepo.lastUpdatedStudentId, isNull);
    });

    test('5. updateStudentStatus performs optimistic update and confirms on success', () async {
      cubit.emit(BusTripLoaded(sampleActiveTrip));
      fakeRepo.updateStudentStatusResult = const Right(null);

      await cubit.updateStudentStatus('st_101', BusStudentStatus.onBus);

      expect(fakeRepo.lastUpdatedStudentId, 'st_101');
      expect(fakeRepo.lastUpdatedStatus, BusStudentStatus.onBus);
      expect(fakeRepo.lastUpdatedDirection, 'to_school');

      expect(cubit.state, isA<BusTripLoaded>());
      final loadedState = cubit.state as BusTripLoaded;
      expect(loadedState.trip.students.first.status, BusStudentStatus.onBus);
    });

    test('6. updateStudentStatus rolls back optimistic update when repository fails', () async {
      cubit.emit(BusTripLoaded(sampleActiveTrip));
      fakeRepo.updateStudentStatusResult = const Left('Server update failed');

      await cubit.updateStudentStatus('st_101', BusStudentStatus.onBus);

      // Should rollback to original status (waiting)
      expect(cubit.state, isA<BusTripLoaded>());
      final loadedState = cubit.state as BusTripLoaded;
      expect(loadedState.trip.students.first.status, BusStudentStatus.waiting);
    });

    test('7. confirmTrip invokes repository and reloads trip', () async {
      cubit.emit(BusTripLoaded(sampleActiveTrip));
      fakeRepo.getActiveTripResult = Right(sampleActiveTrip);
      fakeRepo.confirmTripResult = const Right(null);

      await cubit.confirmTrip('trip_55');

      expect(fakeRepo.lastConfirmedTripId, 'trip_55');
    });

    test('8. BusTripState props and equality checks', () {
      expect(BusTripInitial().props, isEmpty);
      expect(BusTripLoading().props, isEmpty);
      expect(BusTripLoaded(sampleActiveTrip).props, [sampleActiveTrip]);
      expect(const BusTripError('err').props, ['err']);
      expect(const BusTripUpdateError('u_err').props, ['u_err']);
      expect(const BusTripUpdateSuccess('u_succ').props, ['u_succ']);
    });
  });
}
