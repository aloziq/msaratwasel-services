import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:msaratwasel_services/features/teacher/teacher/presentation/cubit/teacher_cubit.dart';
import 'package:msaratwasel_services/features/teacher/teacher/presentation/cubit/teacher_state.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/repositories/teacher_repository.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/usecases/get_teacher_classroom_usecase.dart';
import 'package:msaratwasel_services/features/teacher/teacher/data/repositories/teacher_repository_impl.dart';
import 'package:msaratwasel_services/features/teacher/teacher/data/datasources/teacher_remote_datasource.dart';
import 'package:msaratwasel_services/features/teacher/teacher/data/models/classroom_model.dart';
import 'package:msaratwasel_services/features/teacher/students/data/repositories/students_repository_impl.dart';
import 'package:msaratwasel_services/features/teacher/students/data/datasources/students_remote_datasource.dart';
import 'package:msaratwasel_services/features/teacher/students/data/models/student_model.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/data/repositories/attendance_history_repository_impl.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/data/datasources/attendance_history_remote_datasource.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/data/models/attendance_history_model.dart';
import 'package:msaratwasel_services/features/teacher/reports/data/repositories/reports_repository_impl.dart';
import 'package:msaratwasel_services/features/teacher/reports/data/datasources/reports_remote_datasource.dart';
import 'package:msaratwasel_services/features/teacher/reports/data/models/report_model.dart';

// Fakes for Remote Data Sources
class FakeTeacherRemoteDataSource implements TeacherRemoteDataSource {
  List<ClassroomModel> classrooms = [];
  bool shouldThrow = false;

  @override
  Future<List<ClassroomModel>> getTeacherClassrooms() async {
    if (shouldThrow) throw Exception('Network timeout');
    return classrooms;
  }
}

class FakeStudentsRemoteDataSource implements StudentsRemoteDataSource {
  List<StudentModel> students = [];
  bool shouldThrow = false;
  String? lastMarkedStudentId;
  AttendanceStatus? lastMarkedStatus;
  bool? lastViaQr;
  String? lastConfirmedClassId;

  @override
  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    if (shouldThrow) throw Exception('Students fetch failed');
    return students;
  }

  @override
  Future<void> markAttendance(String studentId, AttendanceStatus status, {bool viaQr = false}) async {
    if (shouldThrow) throw Exception('Mark attendance failed');
    lastMarkedStudentId = studentId;
    lastMarkedStatus = status;
    lastViaQr = viaQr;
  }

  @override
  Future<void> confirmAttendance(String classId) async {
    if (shouldThrow) throw Exception('Confirm attendance failed');
    lastConfirmedClassId = classId;
  }
}

class FakeAttendanceHistoryRemoteDataSource implements AttendanceHistoryRemoteDataSource {
  List<AttendanceHistoryModel> history = [];
  bool shouldThrow = false;

  @override
  Future<List<AttendanceHistoryModel>> getTeacherAttendanceHistory() async {
    if (shouldThrow) throw Exception('History failed');
    return history;
  }
}

class FakeReportsRemoteDataSource implements ReportsRemoteDataSource {
  AttendanceStatsModel? stats;
  Exception? errorToThrow;

  @override
  Future<AttendanceStatsModel> getAttendanceStats() async {
    if (errorToThrow != null) throw errorToThrow!;
    return stats ??
        const AttendanceStatsModel(
          totalStudents: 25,
          presentToday: 23,
          absentToday: 2,
          unmarkedToday: 0,
          averageAttendance: 92.0,
          weeklyTrend: [],
          studentReports: [],
        );
  }
}

class FakeTeacherRepositoryForCubit implements TeacherRepository {
  Either<String, ClassroomEntity> classroomResult = const Right(
    ClassroomEntity(id: 'c-101', name: 'الصف الرابع أ', grade: '4', studentCount: 20),
  );

  @override
  Future<Either<String, ClassroomEntity>> getTeacherClassroom() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return classroomResult;
  }

  @override
  Future<Either<String, List<ClassroomEntity>>> getTeacherClassrooms() async => const Right([]);

  @override
  Future<Either<String, void>> submitDailyReport(String classId) async => const Right(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TeacherCubit & States Suite', () {
    late FakeTeacherRepositoryForCubit fakeRepo;
    late GetTeacherClassroomUseCase useCase;
    late TeacherCubit cubit;

    setUp(() {
      fakeRepo = FakeTeacherRepositoryForCubit();
      useCase = GetTeacherClassroomUseCase(fakeRepo);
      cubit = TeacherCubit(getTeacherClassroomUseCase: useCase);
    });

    tearDown(() {
      cubit.close();
    });

    test('1. Initial state is TeacherInitial and props check', () {
      expect(cubit.state, isA<TeacherInitial>());
      expect(cubit.state.props, isEmpty);

      const opSuccess = TeacherOperationSuccess('تم بنجاح');
      expect(opSuccess.message, 'تم بنجاح');
      expect(opSuccess.props, ['تم بنجاح']);

      const errorState = TeacherError('خطأ غير متوقع');
      expect(errorState.message, 'خطأ غير متوقع');
      expect(errorState.props, ['خطأ غير متوقع']);
    });

    test('2. loadClassroom emits TeacherLoading and TeacherClassLoaded on success', () async {
      const expectedClass = ClassroomEntity(
        id: 'c-101',
        name: 'الصف الرابع أ',
        nameEn: 'Grade 4A',
        grade: '4',
        studentCount: 22,
      );
      fakeRepo.classroomResult = const Right(expectedClass);

      final states = <TeacherState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadClassroom();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<TeacherLoading>());
      expect(states[1], isA<TeacherClassLoaded>());

      final loadedState = states[1] as TeacherClassLoaded;
      expect(loadedState.classroom.id, 'c-101');
      expect(loadedState.classroom.name, 'الصف الرابع أ');
      expect(loadedState.props, [expectedClass]);
      await sub.cancel();
    });

    test('3. loadClassroom emits TeacherLoading and TeacherError on failure', () async {
      fakeRepo.classroomResult = const Left('فشل جلب الفصل');

      final states = <TeacherState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadClassroom();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<TeacherLoading>());
      expect(states[1], isA<TeacherError>());

      final errorState = states[1] as TeacherError;
      expect(errorState.message, 'فشل جلب الفصل');
      await sub.cancel();
    });
  });

  group('TeacherRepositoryImpl Suite', () {
    late FakeTeacherRemoteDataSource remoteDataSource;
    late TeacherRepositoryImpl repository;

    setUp(() {
      remoteDataSource = FakeTeacherRemoteDataSource();
      repository = TeacherRepositoryImpl(remoteDataSource);
    });

    test('4. getTeacherClassroom returns first class when list is not empty', () async {
      remoteDataSource.classrooms = [
        const ClassroomModel(id: 'c-1', name: 'فصل 1', grade: '1', studentCount: 15),
        const ClassroomModel(id: 'c-2', name: 'فصل 2', grade: '2', studentCount: 18),
      ];

      final result = await repository.getTeacherClassroom();

      expect(result.isRight(), isTrue);
      result.fold(
        (e) => fail('Expected Right: $e'),
        (classroom) => expect(classroom.id, 'c-1'),
      );
    });

    test('5. getTeacherClassroom returns Left when classrooms list is empty', () async {
      remoteDataSource.classrooms = [];

      final result = await repository.getTeacherClassroom();

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, 'لا توجد فصول مسجلة لهذا المعلم'),
        (_) => fail('Expected Left'),
      );
    });

    test('6. getTeacherClassroom returns Left on exception', () async {
      remoteDataSource.shouldThrow = true;

      final result = await repository.getTeacherClassroom();

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, 'فشل تحميل بيانات الفصل'),
        (_) => fail('Expected Left'),
      );
    });

    test('7. getTeacherClassrooms returns Right on success and Left on exception', () async {
      remoteDataSource.classrooms = [
        const ClassroomModel(id: 'c-1', name: 'فصل 1', grade: '1', studentCount: 15),
      ];

      final success = await repository.getTeacherClassrooms();
      expect(success.isRight(), isTrue);
      success.fold((_) => fail('Expected Right'), (list) => expect(list.length, 1));

      remoteDataSource.shouldThrow = true;
      final failure = await repository.getTeacherClassrooms();
      expect(failure.isLeft(), isTrue);
      failure.fold((e) => expect(e, 'فشل تحميل قائمة الفصول'), (_) => fail('Expected Left'));
    });

    test('8. submitDailyReport returns Right(null)', () async {
      final result = await repository.submitDailyReport('class-1');
      expect(result.isRight(), isTrue);
    });
  });

  group('StudentsRepositoryImpl Suite', () {
    late FakeStudentsRemoteDataSource remoteDataSource;
    late StudentsRepositoryImpl repository;

    setUp(() {
      remoteDataSource = FakeStudentsRemoteDataSource();
      repository = StudentsRepositoryImpl(remoteDataSource);
    });

    test('9. getStudentsByClass returns Right on success and Left on error', () async {
      remoteDataSource.students = [
        const StudentModel(
          id: 's-1',
          name: 'طالب أ',
          parentName: 'ولي أمر أ',
          parentPhone: '90000001',
        ),
      ];

      final resSuccess = await repository.getStudentsByClass('class-1');
      expect(resSuccess.isRight(), isTrue);
      resSuccess.fold((_) => fail('Expected Right'), (list) => expect(list.length, 1));

      remoteDataSource.shouldThrow = true;
      final resFail = await repository.getStudentsByClass('class-1');
      expect(resFail.isLeft(), isTrue);
      resFail.fold((e) => expect(e, 'فشل تحميل قائمة الطلاب'), (_) => fail('Expected Left'));
    });

    test('10. markAttendance passes arguments and handles errors', () async {
      final resSuccess = await repository.markAttendance(
        's-1',
        AttendanceStatus.present,
        viaQr: true,
      );
      expect(resSuccess.isRight(), isTrue);
      expect(remoteDataSource.lastMarkedStudentId, 's-1');
      expect(remoteDataSource.lastMarkedStatus, AttendanceStatus.present);
      expect(remoteDataSource.lastViaQr, isTrue);

      remoteDataSource.shouldThrow = true;
      final resFail = await repository.markAttendance('s-1', AttendanceStatus.absent);
      expect(resFail.isLeft(), isTrue);
      resFail.fold((e) => expect(e, 'فشل تسجيل الحضور'), (_) => fail('Expected Left'));
    });

    test('11. confirmAttendance invokes data source and handles errors', () async {
      final resSuccess = await repository.confirmAttendance('class-1');
      expect(resSuccess.isRight(), isTrue);
      expect(remoteDataSource.lastConfirmedClassId, 'class-1');

      remoteDataSource.shouldThrow = true;
      final resFail = await repository.confirmAttendance('class-1');
      expect(resFail.isLeft(), isTrue);
      resFail.fold((e) => expect(e, 'فشل تأكيد وإرسال التقرير'), (_) => fail('Expected Left'));
    });
  });

  group('AttendanceHistory & Reports Repositories Suite', () {
    test('12. AttendanceHistoryRepositoryImpl returns Right and handles errors', () async {
      final remoteDS = FakeAttendanceHistoryRemoteDataSource();
      final repo = AttendanceHistoryRepositoryImpl(remoteDS);

      remoteDS.history = [
        const AttendanceHistoryModel(
          classId: 'c1',
          className: 'فصل 1',
          dailyRecords: [],
        ),
      ];

      final resSuccess = await repo.getTeacherAttendanceHistory();
      expect(resSuccess.isRight(), isTrue);
      resSuccess.fold((_) => fail('Expected Right'), (list) => expect(list.length, 1));

      remoteDS.shouldThrow = true;
      final resFail = await repo.getTeacherAttendanceHistory();
      expect(resFail.isLeft(), isTrue);
      resFail.fold((e) => expect(e, 'فشل تحميل سجل الحضور'), (_) => fail('Expected Left'));
    });

    test('13. ReportsRepositoryImpl formats DioException and generic errors', () async {
      final remoteDS = FakeReportsRemoteDataSource();
      final repo = ReportsRepositoryImpl(remoteDS);

      // Success
      final resSuccess = await repo.getAttendanceStats();
      expect(resSuccess.isRight(), isTrue);

      // DioException
      remoteDS.errorToThrow = DioException(
        requestOptions: RequestOptions(path: '/reports'),
        error: 'Bad gateway',
      );
      final resDio = await repo.getAttendanceStats();
      expect(resDio.isLeft(), isTrue);
      resDio.fold((e) => expect(e, contains('تفاصيل الاتصال بالسيرفر')), (_) => fail('Expected Left'));

      // Generic exception
      remoteDS.errorToThrow = const FormatException('Corrupt JSON');
      final resGeneric = await repo.getAttendanceStats();
      expect(resGeneric.isLeft(), isTrue);
      resGeneric.fold((e) => expect(e, contains('خطأ في معالجة البيانات')), (_) => fail('Expected Left'));
    });
  });

  group('Teacher Feature Models Suite', () {
    test('14. ClassroomModel and AttendanceHistoryRecordModel serialization', () {
      final jsonClass = {
        'id': 'cls-50',
        'name_ar': 'الصف الثاني ب',
        'name_en': 'Grade 2B',
        'grade': '2',
        'student_count': 18,
      };

      final classModel = ClassroomModel.fromJson(jsonClass);
      expect(classModel.id, 'cls-50');
      expect(classModel.name, 'الصف الثاني ب');
      expect(classModel.nameEn, 'Grade 2B');
      expect(classModel.studentCount, 18);

      final classJson = classModel.toJson();
      expect(classJson['id'], 'cls-50');
      expect(classJson['studentCount'], 18);

      final now = DateTime(2026, 9, 4);
      final jsonRecord = {
        'date': now.toIso8601String(),
        'totalStudents': 20,
        'presentCount': 18,
        'absentCount': 2,
        'attendedStudents': [],
      };

      final recordModel = AttendanceHistoryRecordModel.fromJson(jsonRecord);
      expect(recordModel.totalStudents, 20);
      expect(recordModel.presentCount, 18);
      expect(recordModel.absentCount, 2);

      final recordJson = recordModel.toJson();
      expect(recordJson['totalStudents'], 20);
      expect(recordJson['presentCount'], 18);
    });

    test('15. AttendanceStatsModel calculates unmarkedToday and serializes', () {
      final jsonStats = {
        'totalStudents': 30,
        'presentToday': 25,
        'absentToday': 3,
        // unmarkedToday is omitted -> should be calculated as 30 - 25 - 3 = 2!
        'averageAttendance': 83.3,
        'weeklyTrend': [
          {'date': '2026-09-01T00:00:00.000', 'attendancePercentage': 85.0}
        ],
        'studentReports': [
          {
            'name': 'طالب تجريبي',
            'civil_id': '12345678',
            'presentCount': 20,
            'absentCount': 2,
          }
        ],
      };

      final stats = AttendanceStatsModel.fromJson(jsonStats);
      expect(stats.totalStudents, 30);
      expect(stats.presentToday, 25);
      expect(stats.absentToday, 3);
      expect(stats.unmarkedToday, 2); // Calculated!
      expect(stats.averageAttendance, 83.3);
      expect(stats.weeklyTrend.length, 1);
      expect(stats.studentReports.length, 1);
      expect(stats.studentReports.first.name, 'طالب تجريبي');

      final serialized = stats.toJson();
      expect(serialized['unmarkedToday'], 2);
      expect(serialized['totalStudents'], 30);
    });
  });
}
