import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/data/models/attendance_history_model.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/domain/entities/attendance_history_entity.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/domain/usecases/get_attendance_history_usecase.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/presentation/cubit/attendance_history_cubit.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/presentation/cubit/attendance_history_state.dart';
import 'package:msaratwasel_services/features/teacher/students/data/models/student_model.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';

class FakeGetAttendanceHistoryUseCase implements GetAttendanceHistoryUseCase {
  Either<String, List<AttendanceHistoryEntity>>? result;

  @override
  Future<Either<String, List<AttendanceHistoryEntity>>> call() async {
    return result ?? const Right([]);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AttendanceHistoryEntity & AttendanceHistoryRecord', () {
    test('1. AttendanceHistoryRecord computes attendanceRate and props correctly', () {
      final recordWithStudents = AttendanceHistoryRecord(
        date: DateTime.parse('2026-09-04'),
        attendedStudents: const [],
        totalStudents: 20,
        presentCount: 15,
        absentCount: 5,
      );
      expect(recordWithStudents.attendanceRate, 75.0);
      expect(recordWithStudents.props.length, 5);

      final zeroStudentsRecord = AttendanceHistoryRecord(
        date: DateTime.parse('2026-09-04'),
        attendedStudents: const [],
        totalStudents: 0,
        presentCount: 0,
        absentCount: 0,
      );
      expect(zeroStudentsRecord.attendanceRate, 0.0);
    });

    test('2. AttendanceHistoryEntity getLocalizedClassName handles arabic and english with fallbacks', () {
      const entityWithEn = AttendanceHistoryEntity(
        classId: 'c1',
        className: 'فصل الأمل',
        classNameEn: 'Hope Class',
        dailyRecords: [],
      );
      expect(entityWithEn.getLocalizedClassName('ar'), 'فصل الأمل');
      expect(entityWithEn.getLocalizedClassName('EN'), 'Hope Class');

      const entityWithoutEn = AttendanceHistoryEntity(
        classId: 'c2',
        className: 'فصل النور',
        classNameEn: '   ',
        dailyRecords: [],
      );
      expect(entityWithoutEn.getLocalizedClassName('en'), 'فصل النور');

      const entityWithNullEn = AttendanceHistoryEntity(
        classId: 'c3',
        className: 'فصل الهدى',
        classNameEn: null,
        dailyRecords: [],
      );
      expect(entityWithNullEn.getLocalizedClassName('en'), 'فصل الهدى');
      expect(entityWithNullEn.props, ['c3', 'فصل الهدى', null, []]);
    });
  });

  group('AttendanceHistoryModel & AttendanceHistoryRecordModel Serialization', () {
    test('3. AttendanceHistoryRecordModel serialization with StudentModel and StudentEntity', () {
      final student = const StudentEntity(
        id: 's1',
        name: 'أحمد',
        nameEn: 'Ahmed',
        parentName: 'محمد',
        parentNameEn: 'Mohammed',
        parentPhone: '0501234567',
        photoUrl: 'https://example.com/p.jpg',
        status: AttendanceStatus.present,
      );

      final record = AttendanceHistoryRecordModel(
        date: DateTime.parse('2026-09-04T08:00:00.000Z'),
        attendedStudents: [student],
        totalStudents: 10,
        presentCount: 8,
        absentCount: 2,
      );

      final json = record.toJson();
      expect(json['totalStudents'], 10);
      expect(json['presentCount'], 8);
      expect(json['absentCount'], 2);
      expect(json['attendedStudents'], isA<List>());
      expect((json['attendedStudents'] as List).first['name'], 'أحمد');

      final fromJson = AttendanceHistoryRecordModel.fromJson({
        'date': '2026-09-04T08:00:00.000Z',
        'attendedStudents': [
          {
            'id': 's1',
            'name': 'أحمد',
            'name_en': 'Ahmed',
            'parent_name': 'محمد',
            'parent_phone': '0501234567',
            'status': 'present',
          }
        ],
        'totalStudents': 10,
        'presentCount': 8,
        'absentCount': 2,
      });

      expect(fromJson.totalStudents, 10);
      expect(fromJson.attendedStudents.length, 1);
      expect(fromJson.attendedStudents.first.name, 'أحمد');

      // Test with StudentModel in toJson branch
      final studentModel = StudentModel.fromJson({
        'id': 's2',
        'name': 'علي',
        'status': 'absent',
      });
      final recordWithModel = AttendanceHistoryRecordModel(
        date: DateTime.parse('2026-09-04T08:00:00.000Z'),
        attendedStudents: [studentModel],
        totalStudents: 1,
        presentCount: 0,
        absentCount: 1,
      );
      final jsonWithModel = recordWithModel.toJson();
      expect((jsonWithModel['attendedStudents'] as List).first['id'], 's2');
    });

    test('4. AttendanceHistoryModel fromJson and toJson with fallbacks and generic records', () {
      final jsonMap = {
        'id': 'cls_99',
        'class_name': 'الصف الأول',
        'class_name_en': 'Grade 1',
        'dailyRecords': [
          {
            'date': '2026-09-04T08:00:00.000Z',
            'attendedStudents': [],
            'totalStudents': 15,
            'presentCount': 14,
            'absentCount': 1,
          }
        ]
      };

      final model = AttendanceHistoryModel.fromJson(jsonMap);
      expect(model.classId, 'cls_99');
      expect(model.className, 'الصف الأول');
      expect(model.classNameEn, 'Grade 1');
      expect(model.dailyRecords.length, 1);

      // Alternative fallback names
      final altJson = AttendanceHistoryModel.fromJson({
        'name': 'فصل ب',
        'name_en': 'Class B',
      });
      expect(altJson.className, 'فصل ب');
      expect(altJson.classNameEn, 'Class B');

      // Generic record conversion in toJson
      final genericRecord = AttendanceHistoryRecord(
        date: DateTime.parse('2026-09-04T08:00:00.000Z'),
        attendedStudents: const [],
        totalStudents: 10,
        presentCount: 9,
        absentCount: 1,
      );
      final modelWithGeneric = AttendanceHistoryModel(
        classId: 'c1',
        className: 'فصل',
        dailyRecords: [genericRecord],
      );
      final outJson = modelWithGeneric.toJson();
      expect((outJson['dailyRecords'] as List).first['totalStudents'], 10);
    });
  });

  group('AttendanceHistoryCubit & State', () {
    late FakeGetAttendanceHistoryUseCase fakeUseCase;
    late AttendanceHistoryCubit cubit;

    setUp(() {
      fakeUseCase = FakeGetAttendanceHistoryUseCase();
      cubit = AttendanceHistoryCubit(getAttendanceHistoryUseCase: fakeUseCase);
    });

    tearDown(() {
      cubit.close();
    });

    test('5. Initial state is AttendanceHistoryInitial', () {
      expect(cubit.state, equals(AttendanceHistoryInitial()));
      expect(AttendanceHistoryInitial().props, isEmpty);
      expect(AttendanceHistoryLoading().props, isEmpty);
    });

    test('6. loadHistory emits Loading and Loaded on Right', () async {
      const mockHistory = [
        AttendanceHistoryEntity(
          classId: 'cls_1',
          className: 'فصل 1',
          dailyRecords: [],
        )
      ];
      fakeUseCase.result = const Right(mockHistory);

      final states = <AttendanceHistoryState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadHistory();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<AttendanceHistoryLoading>());
      expect(states[1], isA<AttendanceHistoryLoaded>());
      final loaded = states[1] as AttendanceHistoryLoaded;
      expect(loaded.history.length, 1);
      expect(loaded.props, [mockHistory]);

      await sub.cancel();
    });

    test('7. loadHistory emits Loading and Error on Left', () async {
      fakeUseCase.result = const Left('Failed to fetch attendance history');

      final states = <AttendanceHistoryState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadHistory();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<AttendanceHistoryLoading>());
      expect(states[1], isA<AttendanceHistoryError>());
      final error = states[1] as AttendanceHistoryError;
      expect(error.message, 'Failed to fetch attendance history');
      expect(error.props, ['Failed to fetch attendance history']);

      await sub.cancel();
    });
  });
}
