import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/features/teacher/reports/data/models/report_model.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/entities/report_entity.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/usecases/get_attendance_stats_usecase.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/cubit/reports_cubit.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/cubit/reports_state.dart';

class FakeGetAttendanceStatsUseCase implements GetAttendanceStatsUseCase {
  Either<String, AttendanceStatsEntity>? result;

  @override
  Future<Either<String, AttendanceStatsEntity>> call() async {
    return result ??
        const Right(
          AttendanceStatsEntity(
            totalStudents: 0,
            presentToday: 0,
            absentToday: 0,
            unmarkedToday: 0,
            averageAttendance: 0,
            weeklyTrend: [],
            studentReports: [],
          ),
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ReportModel & StudentReportModel Serialization', () {
    test('1. ReportModel fromJson and toJson handle valid date and fallback date', () {
      final json = {
        'date': '2026-09-04T12:00:00.000Z',
        'attendancePercentage': 92.5,
      };
      final model = ReportModel.fromJson(json);
      expect(model.attendancePercentage, 92.5);
      expect(model.toJson()['attendancePercentage'], 92.5);

      final fallbackModel = ReportModel.fromJson({
        'attendancePercentage': 80,
      });
      expect(fallbackModel.attendancePercentage, 80.0);
      expect(fallbackModel.date, isNotNull);
    });

    test('2. StudentReportModel fromJson and toJson handle fallbacks for name and civil_id', () {
      final json = {
        'name_ar': 'خالد أحمد',
        'name_en': 'Khaled Ahmed',
        'civil_id': '1029384756',
        'presentCount': 18,
        'absentCount': 2,
        'photo_url': 'https://photos.test/khaled.jpg',
      };
      final model = StudentReportModel.fromJson(json);
      expect(model.name, 'خالد أحمد');
      expect(model.nameEn, 'Khaled Ahmed');
      expect(model.civilId, '1029384756');
      expect(model.presentCount, 18);
      expect(model.absentCount, 2);
      expect(model.photoUrl, 'https://photos.test/khaled.jpg');

      final outJson = model.toJson();
      expect(outJson['civil_id'], '1029384756');
      expect(outJson['presentCount'], 18);

      // Fallback fields test
      final fallbackModel = StudentReportModel.fromJson({
        'name': 'ياسر',
        'civilId': 98765,
      });
      expect(fallbackModel.name, 'ياسر');
      expect(fallbackModel.civilId, '98765');
      expect(fallbackModel.presentCount, 0);

      // Ultimate fallback name
      final unknownModel = StudentReportModel.fromJson({});
      expect(unknownModel.name, 'غير معروف');
    });

    test('3. AttendanceStatsModel calculates unmarkedToday and serializes nested entities', () {
      final json = {
        'totalStudents': 30,
        'presentToday': 25,
        'absentToday': 3,
        // unmarkedToday omitted -> calculated as 30 - 25 - 3 = 2
        'averageAttendance': 88.0,
        'weeklyTrend': [
          {'date': '2026-09-01T08:00:00.000Z', 'attendancePercentage': 90.0}
        ],
        'studentReports': [
          {'name': 'طالب 1', 'presentCount': 5, 'absentCount': 0}
        ]
      };

      final statsModel = AttendanceStatsModel.fromJson(json);
      expect(statsModel.totalStudents, 30);
      expect(statsModel.presentToday, 25);
      expect(statsModel.absentToday, 3);
      expect(statsModel.unmarkedToday, 2);
      expect(statsModel.weeklyTrend.length, 1);
      expect(statsModel.studentReports.length, 1);

      // Test toJson with generic ReportEntity & StudentReportEntity
      final genericStats = AttendanceStatsModel(
        totalStudents: 10,
        presentToday: 8,
        absentToday: 1,
        unmarkedToday: 1,
        averageAttendance: 80.0,
        weeklyTrend: [
          ReportEntity(date: DateTime.parse('2026-09-01'), attendancePercentage: 80.0),
        ],
        studentReports: const [
          StudentReportEntity(name: 'سارة', presentCount: 4, absentCount: 1),
        ],
      );

      final outJson = genericStats.toJson();
      expect(outJson['totalStudents'], 10);
      expect((outJson['weeklyTrend'] as List).first['attendancePercentage'], 80.0);
      expect((outJson['studentReports'] as List).first['name'], 'سارة');
    });
  });

  group('ReportsCubit & ReportsState Machine', () {
    late FakeGetAttendanceStatsUseCase fakeUseCase;
    late ReportsCubit cubit;

    setUp(() {
      fakeUseCase = FakeGetAttendanceStatsUseCase();
      cubit = ReportsCubit(getAttendanceStatsUseCase: fakeUseCase);
    });

    tearDown(() {
      cubit.close();
    });

    test('4. Initial state is ReportsInitial', () {
      expect(cubit.state, equals(ReportsInitial()));
      expect(ReportsInitial().props, isEmpty);
      expect(ReportsLoading().props, isEmpty);
    });

    test('5. loadReports emits Loading then Loaded on success', () async {
      const mockStats = AttendanceStatsEntity(
        totalStudents: 20,
        presentToday: 18,
        absentToday: 2,
        unmarkedToday: 0,
        averageAttendance: 90.0,
        weeklyTrend: [],
        studentReports: [],
      );
      fakeUseCase.result = const Right(mockStats);

      final states = <ReportsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadReports();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<ReportsLoading>());
      expect(states[1], isA<ReportsLoaded>());
      final loaded = states[1] as ReportsLoaded;
      expect(loaded.stats.totalStudents, 20);
      expect(loaded.props, [mockStats]);

      await sub.cancel();
    });

    test('6. loadReports emits Loading then Error on failure', () async {
      fakeUseCase.result = const Left('Network error loading reports');

      final states = <ReportsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadReports();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<ReportsLoading>());
      expect(states[1], isA<ReportsError>());
      final error = states[1] as ReportsError;
      expect(error.message, 'Network error loading reports');
      expect(error.props, ['Network error loading reports']);

      await sub.cancel();
    });
  });
}
