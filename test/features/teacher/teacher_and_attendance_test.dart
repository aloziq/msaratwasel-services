import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/features/teacher/students/data/models/student_model.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/repositories/students_repository.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/usecases/confirm_attendance_usecase.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/usecases/get_students_usecase.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/usecases/mark_attendance_usecase.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/class_details_cubit.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/class_details_state.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/my_classes_cubit.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/my_classes_state.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/repositories/teacher_repository.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/presentation/cubit/attendance_history_cubit.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/presentation/cubit/attendance_history_state.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/domain/entities/attendance_history_entity.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/domain/repositories/attendance_history_repository.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/domain/usecases/get_attendance_history_usecase.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/cubit/reports_cubit.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/cubit/reports_state.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/entities/report_entity.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/repositories/reports_repository.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/usecases/get_attendance_stats_usecase.dart';

// Fake implementations
class FakeStudentsRepository implements StudentsRepository {
  Either<String, List<StudentEntity>>? getStudentsResult;
  Either<String, void>? markAttendanceResult;
  Either<String, void>? confirmAttendanceResult;

  @override
  Future<Either<String, List<StudentEntity>>> getStudentsByClass(String classId) async {
    return getStudentsResult ?? const Right([]);
  }

  @override
  Future<Either<String, void>> markAttendance(
    String studentId,
    AttendanceStatus status, {
    bool viaQr = false,
  }) async {
    return markAttendanceResult ?? const Right(null);
  }

  @override
  Future<Either<String, void>> confirmAttendance(String classId) async {
    return confirmAttendanceResult ?? const Right(null);
  }
}

class FakeTeacherRepository implements TeacherRepository {
  Either<String, List<ClassroomEntity>>? classroomsResult;

  @override
  Future<Either<String, List<ClassroomEntity>>> getTeacherClassrooms() async {
    return classroomsResult ?? const Right([]);
  }

  @override
  Future<Either<String, ClassroomEntity>> getTeacherClassroom() async {
    return const Left('Not implemented in mock');
  }

  @override
  Future<Either<String, void>> submitDailyReport(String classId) async {
    return const Right(null);
  }
}

class FakeAttendanceHistoryRepository implements AttendanceHistoryRepository {
  Either<String, List<AttendanceHistoryEntity>>? historyResult;

  @override
  Future<Either<String, List<AttendanceHistoryEntity>>> getTeacherAttendanceHistory() async {
    return historyResult ?? const Right([]);
  }
}

class FakeReportsRepository implements ReportsRepository {
  Either<String, AttendanceStatsEntity>? statsResult;

  @override
  Future<Either<String, AttendanceStatsEntity>> getAttendanceStats() async {
    return statsResult ??
        const Right(AttendanceStatsEntity(
          totalStudents: 30,
          presentToday: 28,
          absentToday: 2,
          unmarkedToday: 0,
          averageAttendance: 93.3,
          weeklyTrend: [],
          studentReports: [],
        ));
  }
}

void main() {
  group('StudentModel & ClassroomEntity Suite', () {
    test('1. StudentModel fromJson & toJson round-trip', () {
      final json = {
        'id': 'std_101',
        'name_ar': 'سعد العتيبي',
        'name_en': 'Saad Al-Otaibi',
        'parent_name': 'ناصر العتيبي',
        'parent_name_en': 'Nasser Al-Otaibi',
        'parent_phone': '0551122334',
        'image_url': 'https://api.msaratwasel.com/photos/std101.jpg',
        'status': 'present',
        'is_locked': false,
      };

      final model = StudentModel.fromJson(json);

      expect(model.id, 'std_101');
      expect(model.name, 'سعد العتيبي');
      expect(model.nameEn, 'Saad Al-Otaibi');
      expect(model.parentName, 'ناصر العتيبي');
      expect(model.parentPhone, '0551122334');
      expect(model.photoUrl, 'https://api.msaratwasel.com/photos/std101.jpg');
      expect(model.status, AttendanceStatus.present);
      expect(model.isLocked, isFalse);

      final serialized = model.toJson();
      expect(serialized['id'], 'std_101');
      expect(serialized['name'], 'سعد العتيبي');
      expect(serialized['status'], 'present');
    });

    test('2. ClassroomEntity localized names work correctly for Ar and En', () {
      const classroom = ClassroomEntity(
        id: 'c1',
        name: 'الصف الثالث أ',
        nameEn: 'Grade 3A',
        grade: '3',
        studentCount: 25,
      );

      expect(classroom.getLocalizedName('ar'), 'الصف الثالث أ');
      expect(classroom.getLocalizedName('en'), 'Grade 3A');
      expect(classroom.getLocalizedName('fr'), 'الصف الثالث أ');
    });
  });

  group('ClassDetailsCubit & Optimistic Attendance Suite', () {
    late FakeStudentsRepository fakeRepo;
    late GetStudentsUseCase getStudentsUseCase;
    late MarkAttendanceUseCase markAttendanceUseCase;
    late ConfirmAttendanceUseCase confirmAttendanceUseCase;
    late ClassDetailsCubit cubit;

    final studentA = const StudentEntity(
      id: 'std_a',
      name: 'Student A',
      parentName: 'Parent A',
      parentPhone: '0550000001',
      status: AttendanceStatus.unknown,
      isLocked: false,
    );

    final studentB = const StudentEntity(
      id: 'std_b',
      name: 'Student B',
      parentName: 'Parent B',
      parentPhone: '0550000002',
      status: AttendanceStatus.present,
      isLocked: true, // locked!
    );

    setUp(() {
      fakeRepo = FakeStudentsRepository();
      getStudentsUseCase = GetStudentsUseCase(fakeRepo);
      markAttendanceUseCase = MarkAttendanceUseCase(fakeRepo);
      confirmAttendanceUseCase = ConfirmAttendanceUseCase(fakeRepo);
      cubit = ClassDetailsCubit(
        getStudentsUseCase: getStudentsUseCase,
        markAttendanceUseCase: markAttendanceUseCase,
        confirmAttendanceUseCase: confirmAttendanceUseCase,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('3. loadStudents emits Loading then Loaded on success', () async {
      fakeRepo.getStudentsResult = Right([studentA, studentB]);

      final states = <ClassDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadStudents('class_1');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<ClassDetailsLoading>());
      expect(states[1], isA<ClassDetailsLoaded>());

      final loaded = states[1] as ClassDetailsLoaded;
      expect(loaded.students.length, 2);
      expect(loaded.classId, 'class_1');

      await subscription.cancel();
    });

    test('4. loadStudents emits Error when repository returns Left', () async {
      fakeRepo.getStudentsResult = const Left('Failed to load class students');

      final states = <ClassDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadStudents('class_1');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<ClassDetailsLoading>());
      expect(states[1], isA<ClassDetailsError>());

      final error = states[1] as ClassDetailsError;
      expect(error.message, 'Failed to load class students');

      await subscription.cancel();
    });

    test('5. markAttendance performs optimistic update and keeps state when successful', () async {
      fakeRepo.getStudentsResult = Right([studentA]);
      await cubit.loadStudents('class_1');

      fakeRepo.markAttendanceResult = const Right(null);

      await cubit.markAttendance('std_a', AttendanceStatus.present, 'class_1');

      expect(cubit.state, isA<ClassDetailsLoaded>());
      final loaded = cubit.state as ClassDetailsLoaded;
      expect(loaded.students.first.status, AttendanceStatus.present);
    });

    test('6. markAttendance rolls back to previous state if repository fails', () async {
      fakeRepo.getStudentsResult = Right([studentA]);
      await cubit.loadStudents('class_1');

      fakeRepo.markAttendanceResult = const Left('Server network error');

      await cubit.markAttendance('std_a', AttendanceStatus.present, 'class_1');

      // Should have rolled back to unknown
      expect(cubit.state, isA<ClassDetailsLoaded>());
      final loaded = cubit.state as ClassDetailsLoaded;
      expect(loaded.students.first.status, AttendanceStatus.unknown);
    });

    test('7. markAttendance rejects change when student is locked and status is not unknown', () async {
      fakeRepo.getStudentsResult = Right([studentB]); // studentB is locked with status present
      await cubit.loadStudents('class_1');

      await cubit.markAttendance('std_b', AttendanceStatus.absent, 'class_1');

      // Must remain present because isLocked is true!
      final loaded = cubit.state as ClassDetailsLoaded;
      expect(loaded.students.first.status, AttendanceStatus.present);
    });

    test('8. submitDailyReport confirms and locks all marked students on success', () async {
      final studentMarked = studentA.copyWith(status: AttendanceStatus.present);
      fakeRepo.getStudentsResult = Right([studentMarked]);
      await cubit.loadStudents('class_1');

      fakeRepo.confirmAttendanceResult = const Right(null);

      final success = await cubit.submitDailyReport();

      expect(success, isTrue);
      final loaded = cubit.state as ClassDetailsLoaded;
      expect(loaded.students.first.isLocked, isTrue);
    });

    test('9. submitDailyReport returns false on failure without modifying locks', () async {
      final studentMarked = studentA.copyWith(status: AttendanceStatus.present);
      fakeRepo.getStudentsResult = Right([studentMarked]);
      await cubit.loadStudents('class_1');

      fakeRepo.confirmAttendanceResult = const Left('Network error');

      final success = await cubit.submitDailyReport();

      expect(success, isFalse);
      final loaded = cubit.state as ClassDetailsLoaded;
      expect(loaded.students.first.isLocked, isFalse);
    });
  });

  group('MyClassesCubit, AttendanceHistoryCubit & ReportsCubit Suite', () {
    test('10. MyClassesCubit emits Loading and Loaded on success', () async {
      final repo = FakeTeacherRepository();
      repo.classroomsResult = const Right([
        ClassroomEntity(id: 'c1', name: 'الصف الثالث أ', nameEn: 'Grade 3A', grade: '3', studentCount: 25),
      ]);
      final cubit = MyClassesCubit(getTeacherClassroomsUseCase: GetTeacherClassroomsUseCase(repo));

      final states = <MyClassesState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadClasses();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<MyClassesLoading>());
      expect(states[1], isA<MyClassesLoaded>());

      await sub.cancel();
      await cubit.close();
    });

    test('11. AttendanceHistoryCubit emits Loading and Loaded on success', () async {
      final repo = FakeAttendanceHistoryRepository();
      repo.historyResult = const Right([]);
      final cubit = AttendanceHistoryCubit(getAttendanceHistoryUseCase: GetAttendanceHistoryUseCase(repo));

      final states = <AttendanceHistoryState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadHistory();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<AttendanceHistoryLoading>());
      expect(states[1], isA<AttendanceHistoryLoaded>());

      await sub.cancel();
      await cubit.close();
    });

    test('12. ReportsCubit emits Loading and Loaded on success', () async {
      final repo = FakeReportsRepository();
      final cubit = ReportsCubit(getAttendanceStatsUseCase: GetAttendanceStatsUseCase(repo));

      final states = <ReportsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadReports();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<ReportsLoading>());
      expect(states[1], isA<ReportsLoaded>());

      await sub.cancel();
      await cubit.close();
    });
  });
}
