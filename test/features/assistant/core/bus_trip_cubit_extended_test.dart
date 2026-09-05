import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_trip_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/repositories/assistant_repository.dart';
import 'package:msaratwasel_services/features/assistant/core/presentation/cubit/bus_trip_cubit.dart';

class MockAssistantRepoExtended implements AssistantRepository {
  Either<String, BusTripEntity> getActiveTripResult = const Left('No trip');
  Either<String, void> confirmTripResult = const Right(null);
  Either<String, void> groupAlightResult = const Right(null);
  Either<String, void> groupBoardResult = const Right(null);
  Either<String, void> updateNoteResult = const Right(null);

  List<String>? lastGroupAlightIds;
  String? lastGroupAlightDirection;
  List<String>? lastGroupBoardIds;
  String? lastGroupBoardDirection;
  String? lastNoteStudentId;
  String? lastNoteText;

  @override
  Future<Either<String, BusTripEntity>> getActiveTrip() async => getActiveTripResult;

  @override
  Future<Either<String, void>> confirmTrip(String tripId) async => confirmTripResult;

  @override
  Future<Either<String, void>> groupAlight({
    required List<String> studentIds,
    required String direction,
  }) async {
    lastGroupAlightIds = studentIds;
    lastGroupAlightDirection = direction;
    return groupAlightResult;
  }

  @override
  Future<Either<String, void>> groupBoard({
    required List<String> studentIds,
    required String direction,
  }) async {
    lastGroupBoardIds = studentIds;
    lastGroupBoardDirection = direction;
    return groupBoardResult;
  }

  @override
  Future<Either<String, void>> updateBehavioralNote(String studentId, String note) async {
    lastNoteStudentId = studentId;
    lastNoteText = note;
    return updateNoteResult;
  }

  @override
  Future<Either<String, void>> updateStudentStatus(
    String studentId,
    BusStudentStatus status,
    String? direction,
  ) async => const Right(null);

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAssistantRepoExtended mockRepo;
  late BusTripCubit cubit;

  final student1 = const BusStudentEntity(
    id: 'st_1',
    studentCode: 'C1',
    name: 'Student One',
    grade: 'G3',
    schoolId: 'sch_1',
    parentName: 'Parent One',
    parentPhone: '0550000001',
    status: BusStudentStatus.waiting,
  );

  final activeTrip = BusTripEntity(
    id: 'trip_100',
    busNumber: 'B-01',
    driverName: 'Driver Ali',
    assistantName: 'Assistant Noor',
    students: [student1],
    startTime: DateTime(2026, 9, 4, 7, 0),
    tripStatus: 'in_progress',
    suggestedDirection: 'to_school',
  );

  final idleTrip = BusTripEntity(
    id: 'trip_idle',
    busNumber: 'B-01',
    driverName: 'Driver Ali',
    assistantName: 'Assistant Noor',
    students: [student1],
    startTime: DateTime(2026, 9, 4, 7, 0),
    tripStatus: 'completed',
  );

  setUp(() {
    mockRepo = MockAssistantRepoExtended();
    cubit = BusTripCubit(repository: mockRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('BusTripCubit Extended Branches Suite', () {
    test('1. loadTrip(silent: true) does not emit Loading state', () async {
      mockRepo.getActiveTripResult = Right(activeTrip);

      final states = <BusTripState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadTrip(silent: true);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 1);
      expect(states.first, isA<BusTripLoaded>());

      await sub.cancel();
    });

    test('2. confirmTrip failure emits BusTripUpdateError and restores previous loaded trip', () async {
      mockRepo.getActiveTripResult = Right(activeTrip);
      await cubit.loadTrip();

      mockRepo.confirmTripResult = const Left('Supervisor confirmation rejected');

      final states = <BusTripState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.confirmTrip('trip_100');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 3);
      expect(states[0], isA<BusTripLoading>());
      expect(states[1], isA<BusTripUpdateError>());
      expect((states[1] as BusTripUpdateError).message, 'Supervisor confirmation rejected');
      expect(states[2], isA<BusTripLoaded>());

      await sub.cancel();
    });

    test('3. groupAlight fails with error when trip is not active', () async {
      mockRepo.getActiveTripResult = Right(idleTrip);
      await cubit.loadTrip();

      final states = <BusTripState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.groupAlight(['st_1'], 'to_school');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 1);
      expect(states.first, isA<BusTripUpdateError>());
      expect((states.first as BusTripUpdateError).message, contains('لا يمكن تعديل حالة الطلاب'));

      await sub.cancel();
    });

    test('4. groupAlight success emits Loading, UpdateSuccess, and reloads trip', () async {
      mockRepo.getActiveTripResult = Right(activeTrip);
      await cubit.loadTrip();

      mockRepo.groupAlightResult = const Right(null);

      final states = <BusTripState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.groupAlight(['st_1'], 'to_school');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(mockRepo.lastGroupAlightIds, ['st_1']);
      expect(mockRepo.lastGroupAlightDirection, 'to_school');
      expect(states.any((s) => s is BusTripUpdateSuccess), isTrue);

      await sub.cancel();
    });

    test('5. groupAlight failure emits BusTripUpdateError and restores loaded trip', () async {
      mockRepo.getActiveTripResult = Right(activeTrip);
      await cubit.loadTrip();

      mockRepo.groupAlightResult = const Left('Network timeout in batch alight');

      final states = <BusTripState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.groupAlight(['st_1'], 'to_school');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.any((s) => s is BusTripUpdateError), isTrue);
      expect(states.last, isA<BusTripLoaded>());

      await sub.cancel();
    });

    test('6. groupBoard fails with error when trip is inactive', () async {
      mockRepo.getActiveTripResult = Right(idleTrip);
      await cubit.loadTrip();

      final states = <BusTripState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.groupBoard(['st_1'], 'to_home');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 1);
      expect(states.first, isA<BusTripUpdateError>());

      await sub.cancel();
    });

    test('7. groupBoard success emits Loading, UpdateSuccess, and reloads trip', () async {
      mockRepo.getActiveTripResult = Right(activeTrip);
      await cubit.loadTrip();

      mockRepo.groupBoardResult = const Right(null);

      final states = <BusTripState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.groupBoard(['st_1'], 'to_home');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(mockRepo.lastGroupBoardIds, ['st_1']);
      expect(mockRepo.lastGroupBoardDirection, 'to_home');
      expect(states.any((s) => s is BusTripUpdateSuccess), isTrue);

      await sub.cancel();
    });

    test('8. groupBoard failure emits BusTripUpdateError and restores loaded trip', () async {
      mockRepo.getActiveTripResult = Right(activeTrip);
      await cubit.loadTrip();

      mockRepo.groupBoardResult = const Left('Server error batch board');

      final states = <BusTripState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.groupBoard(['st_1'], 'to_home');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.any((s) => s is BusTripUpdateError), isTrue);
      expect(states.last, isA<BusTripLoaded>());

      await sub.cancel();
    });

    test('9. updateBehavioralNote updates student note optimistically and notifies repository', () async {
      mockRepo.getActiveTripResult = Right(activeTrip);
      await cubit.loadTrip();

      await cubit.updateBehavioralNote('st_1', 'Student was very cooperative today');

      expect(mockRepo.lastNoteStudentId, 'st_1');
      expect(mockRepo.lastNoteText, 'Student was very cooperative today');
      expect(cubit.state, isA<BusTripLoaded>());
      final loaded = cubit.state as BusTripLoaded;
      expect(loaded.trip.students.first.behavioralNote, 'Student was very cooperative today');
    });
  });
}
