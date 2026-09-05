import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/features/driver/maintenance/presentation/manager/maintenance_cubit.dart';
import 'package:msaratwasel_services/features/driver/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:msaratwasel_services/features/driver/maintenance/data/models/bus_expense_model.dart';
import 'package:msaratwasel_services/features/driver/maintenance/domain/entities/bus_expense.dart';

class FakeMaintenanceRepository implements MaintenanceRepository {
  List<BusExpense>? expensesToReturn;
  Exception? errorToThrow;
  
  bool submitFuelCalled = false;
  double? lastFuelAmount;
  int? lastOdometer;
  DateTime? lastFuelDate;
  String? lastFuelPhoto;

  bool submitMaintenanceCalled = false;
  String? lastMaintenanceDesc;
  DateTime? lastMaintenanceDate;
  double? lastMaintenanceCost;
  String? lastMaintenancePhoto;

  @override
  Future<List<BusExpense>> getExpenses({int page = 1}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return expensesToReturn ?? [];
  }

  @override
  Future<void> submitFuelRefill({
    required double amount,
    required int odometer,
    required DateTime date,
    String? photoPath,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    submitFuelCalled = true;
    lastFuelAmount = amount;
    lastOdometer = odometer;
    lastFuelDate = date;
    lastFuelPhoto = photoPath;
  }

  @override
  Future<void> submitMaintenanceRequest({
    required String description,
    required DateTime date,
    double? cost,
    String? photoPath,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    submitMaintenanceCalled = true;
    lastMaintenanceDesc = description;
    lastMaintenanceDate = date;
    lastMaintenanceCost = cost;
    lastMaintenancePhoto = photoPath;
  }
}

void main() {
  late FakeMaintenanceRepository fakeRepository;
  late MaintenanceCubit cubit;

  final testDate = DateTime.parse('2026-09-04T10:00:00.000Z');
  final testExpense = BusExpenseModel(
    id: 101,
    busId: 42,
    type: 'fuel',
    amount: 150.50,
    date: testDate,
    extraInfo: '45000',
    receiptPhoto: 'uploads/receipt_101.jpg',
  );

  setUp(() {
    fakeRepository = FakeMaintenanceRepository();
    cubit = MaintenanceCubit(fakeRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('BusExpenseModel Serialization Suite', () {
    test('1. BusExpenseModel fromJson correctly parses all fields including numeric conversions', () {
      final json = {
        'id': 101,
        'bus_id': 42,
        'type': 'fuel',
        'amount': '150.50',
        'date': '2026-09-04T10:00:00.000Z',
        'extra_info': '45000',
        'receipt_photo': 'uploads/receipt_101.jpg',
      };

      final model = BusExpenseModel.fromJson(json);

      expect(model.id, 101);
      expect(model.busId, 42);
      expect(model.type, 'fuel');
      expect(model.amount, 150.50);
      expect(model.date, testDate);
      expect(model.extraInfo, '45000');
      expect(model.receiptPhoto, 'uploads/receipt_101.jpg');
    });

    test('2. BusExpenseModel toJson formats fields according to API contract', () {
      final json = testExpense.toJson();

      expect(json['id'], 101);
      expect(json['bus_id'], 42);
      expect(json['type'], 'fuel');
      expect(json['amount'], 150.50);
      expect(json['date'], testDate.toIso8601String());
      expect(json['extra_info'], '45000');
      expect(json['receipt_photo'], 'uploads/receipt_101.jpg');
    });
  });

  group('MaintenanceCubit State Machine Suite', () {
    test('3. Initial state is MaintenanceInitial', () {
      expect(cubit.state, equals(MaintenanceInitial()));
    });

    test('4. fetchLogs page 1 emits LoadingLogs and LogsLoaded with items', () async {
      fakeRepository.expensesToReturn = [testExpense];

      final states = <MaintenanceState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.fetchLogs();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<MaintenanceLoadingLogs>());
      expect(states[1], isA<MaintenanceLogsLoaded>());

      final loaded = states[1] as MaintenanceLogsLoaded;
      expect(loaded.expenses.length, 1);
      expect(loaded.expenses.first, equals(testExpense));
      expect(loaded.hasReachedMax, isTrue); // length 1 < 15

      await subscription.cancel();
    });

    test('5. fetchLogs emits hasReachedMax: true when repository returns empty list', () async {
      fakeRepository.expensesToReturn = [];

      final states = <MaintenanceState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.fetchLogs();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<MaintenanceLoadingLogs>());
      expect(states[1], isA<MaintenanceLogsLoaded>());

      final loaded = states[1] as MaintenanceLogsLoaded;
      expect(loaded.expenses.isEmpty, isTrue);
      expect(loaded.hasReachedMax, isTrue);

      await subscription.cancel();
    });

    test('5b. fetchLogs handles pagination (page > 1) and refresh correctly', () async {
      // Create 15 items to simulate full page
      final fullPage = List.generate(
        15,
        (i) => BusExpenseModel(
          id: i + 1,
          busId: 42,
          type: 'fuel',
          amount: 100.0 + i,
          date: testDate,
        ),
      );
      fakeRepository.expensesToReturn = fullPage;

      await cubit.fetchLogs();
      expect(cubit.state, isA<MaintenanceLogsLoaded>());
      final firstLoaded = cubit.state as MaintenanceLogsLoaded;
      expect(firstLoaded.expenses.length, 15);
      expect(firstLoaded.hasReachedMax, isFalse);

      // Now fetch page 2 (does not emit LoadingLogs, but appends)
      final secondPage = List.generate(
        15,
        (i) => BusExpenseModel(id: 16 + i, busId: 42, type: 'maintenance', amount: 300.0, date: testDate),
      );
      fakeRepository.expensesToReturn = secondPage;

      final states = <MaintenanceState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.fetchLogs();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 1); // No LoadingLogs emitted for page > 1
      expect(states[0], isA<MaintenanceLogsLoaded>());
      final secondLoaded = states[0] as MaintenanceLogsLoaded;
      expect(secondLoaded.expenses.length, 30);
      expect(secondLoaded.hasReachedMax, isFalse); // 15 items == 15
      await sub.cancel();

      // Now test empty page 3 -> transitions hasReachedMax from false to true
      fakeRepository.expensesToReturn = [];
      final states3 = <MaintenanceState>[];
      final sub3 = cubit.stream.listen(states3.add);

      await cubit.fetchLogs();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states3.length, 1);
      final thirdLoaded = states3[0] as MaintenanceLogsLoaded;
      expect(thirdLoaded.expenses.length, 30);
      expect(thirdLoaded.hasReachedMax, isTrue);
      await sub3.cancel();

      // Now test refresh: resets page and emits LoadingLogs
      fakeRepository.expensesToReturn = [testExpense];
      final statesRefresh = <MaintenanceState>[];
      final subRefresh = cubit.stream.listen(statesRefresh.add);

      await cubit.fetchLogs(refresh: true);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(statesRefresh.length, 2);
      expect(statesRefresh[0], isA<MaintenanceLoadingLogs>());
      expect(statesRefresh[1], isA<MaintenanceLogsLoaded>());
      final refreshedLoaded = statesRefresh[1] as MaintenanceLogsLoaded;
      expect(refreshedLoaded.expenses.length, 1);
      await subRefresh.cancel();
    });

    test('6. fetchLogs emits MaintenanceLogsError when repository throws exception', () async {
      fakeRepository.errorToThrow = Exception('Network timeout while fetching expenses');

      final states = <MaintenanceState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.fetchLogs();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<MaintenanceLoadingLogs>());
      expect(states[1], isA<MaintenanceLogsError>());

      final error = states[1] as MaintenanceLogsError;
      expect(error.message, contains('Network timeout'));

      await subscription.cancel();
    });

    test('7. submitFuelRefill emits Submitting then MaintenanceSuccess on success', () async {
      final states = <MaintenanceState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submitFuelRefill(
        amount: 150.0,
        odometer: 45000,
        date: testDate,
        photoPath: '/mock/path/receipt.jpg',
      );
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<MaintenanceSubmitting>());
      expect(states[1], isA<MaintenanceSuccess>());

      final success = states[1] as MaintenanceSuccess;
      expect(success.message, 'fuel_success');
      expect(fakeRepository.submitFuelCalled, isTrue);
      expect(fakeRepository.lastFuelAmount, 150.0);
      expect(fakeRepository.lastOdometer, 45000);

      await subscription.cancel();
    });

    test('8. submitFuelRefill emits MaintenanceError when repository throws', () async {
      fakeRepository.errorToThrow = Exception('Failed to upload receipt');

      final states = <MaintenanceState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submitFuelRefill(
        amount: 150.0,
        odometer: 45000,
        date: testDate,
      );
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<MaintenanceSubmitting>());
      expect(states[1], isA<MaintenanceError>());

      final error = states[1] as MaintenanceError;
      expect(error.message, contains('Failed to upload receipt'));

      await subscription.cancel();
    });

    test('9. submitMaintenanceRequest emits Submitting then MaintenanceSuccess on success', () async {
      final states = <MaintenanceState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submitMaintenanceRequest(
        description: 'Oil change and brake pad replacement',
        date: testDate,
        cost: 320.0,
      );
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<MaintenanceSubmitting>());
      expect(states[1], isA<MaintenanceSuccess>());

      final success = states[1] as MaintenanceSuccess;
      expect(success.message, 'request_success');
      expect(fakeRepository.submitMaintenanceCalled, isTrue);
      expect(fakeRepository.lastMaintenanceCost, 320.0);

      await subscription.cancel();
    });

    test('10. submitMaintenanceRequest emits MaintenanceError on repository failure', () async {
      fakeRepository.errorToThrow = Exception('Server 500 error');

      final states = <MaintenanceState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submitMaintenanceRequest(
        description: 'Brake check',
        date: testDate,
      );
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<MaintenanceSubmitting>());
      expect(states[1], isA<MaintenanceError>());

      final error = states[1] as MaintenanceError;
      expect(error.message, contains('Server 500 error'));

      await subscription.cancel();
    });
  });
}
