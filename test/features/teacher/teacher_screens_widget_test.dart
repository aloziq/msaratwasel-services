import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/presentation/screens/attendance_history_screen.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/presentation/cubit/attendance_history_cubit.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/domain/entities/attendance_history_entity.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/domain/repositories/attendance_history_repository.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/domain/usecases/get_attendance_history_usecase.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/screens/class_details_screen.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/class_details_cubit.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/repositories/students_repository.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/usecases/get_students_usecase.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/usecases/mark_attendance_usecase.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/usecases/confirm_attendance_usecase.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/screens/reports_screen.dart';
import 'package:msaratwasel_services/features/teacher/reports/presentation/cubit/reports_cubit.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/entities/report_entity.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/repositories/reports_repository.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/usecases/get_attendance_stats_usecase.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/screens/my_classes_screen.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/my_classes_cubit.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/repositories/teacher_repository.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class FakeTeacherRepo implements TeacherRepository {
  @override
  Future<Either<String, ClassroomEntity>> getTeacherClassroom() async {
    return const Right(ClassroomEntity(id: 'cls_1', name: 'الصف الأول', grade: '1', studentCount: 20));
  }

  @override
  Future<Either<String, List<ClassroomEntity>>> getTeacherClassrooms() async {
    return const Right([
      ClassroomEntity(id: 'cls_1', name: 'الصف الأول', grade: '1', studentCount: 20),
      ClassroomEntity(id: 'cls_2', name: 'الصف الثاني', grade: '2', studentCount: 22),
    ]);
  }

  @override
  Future<Either<String, void>> submitDailyReport(String classId) async {
    return const Right(null);
  }
}

class FakeAttendanceHistoryRepo implements AttendanceHistoryRepository {
  @override
  Future<Either<String, List<AttendanceHistoryEntity>>> getTeacherAttendanceHistory() async {
    final now = DateTime.now();
    return Right([
      AttendanceHistoryEntity(
        classId: 'cls_1',
        className: 'Class 3A',
        dailyRecords: [
          AttendanceHistoryRecord(
            date: DateTime(now.year, now.month, now.day),
            attendedStudents: const [
              StudentEntity(
                id: 'std_1',
                name: 'سالم الهنائي',
                parentName: 'سعيد',
                parentPhone: '0501112233',
                status: AttendanceStatus.present,
              )
            ],
            totalStudents: 20,
            presentCount: 18,
            absentCount: 2,
          ),
        ],
      ),
    ]);
  }
}

class FakeStudentsRepo implements StudentsRepository {
  @override
  Future<Either<String, List<StudentEntity>>> getStudentsByClass(String classId) async {
    return const Right([
      StudentEntity(
        id: 'std_101',
        name: 'Sami Ahmad',
        parentName: 'Ahmad',
        parentPhone: '0555555555',
        status: AttendanceStatus.present,
        isLocked: false,
      ),
    ]);
  }

  @override
  Future<Either<String, void>> markAttendance(
    String studentId,
    AttendanceStatus status, {
    bool viaQr = false,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<String, void>> confirmAttendance(String classId) async {
    return const Right(null);
  }
}

class FakeReportsRepo implements ReportsRepository {
  @override
  Future<Either<String, AttendanceStatsEntity>> getAttendanceStats() async {
    return const Right(
      AttendanceStatsEntity(
        totalStudents: 30,
        presentToday: 28,
        absentToday: 2,
        unmarkedToday: 0,
        averageAttendance: 93.3,
        weeklyTrend: [],
        studentReports: [],
      ),
    );
  }
}

Widget buildTestableTeacherWidget({
  required Widget child,
  required AttendanceHistoryCubit historyCubit,
  required ClassDetailsCubit detailsCubit,
  required ReportsCubit reportsCubit,
  required MyClassesCubit myClassesCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AttendanceHistoryCubit>.value(value: historyCubit),
      BlocProvider<ClassDetailsCubit>.value(value: detailsCubit),
      BlocProvider<ReportsCubit>.value(value: reportsCubit),
      BlocProvider<MyClassesCubit>.value(value: myClassesCubit),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AttendanceHistoryCubit historyCubit;
  late ClassDetailsCubit detailsCubit;
  late ReportsCubit reportsCubit;
  late MyClassesCubit myClassesCubit;

  setUp(() {
    historyCubit = AttendanceHistoryCubit(
      getAttendanceHistoryUseCase: GetAttendanceHistoryUseCase(FakeAttendanceHistoryRepo()),
    );
    final studentsRepo = FakeStudentsRepo();
    detailsCubit = ClassDetailsCubit(
      getStudentsUseCase: GetStudentsUseCase(studentsRepo),
      markAttendanceUseCase: MarkAttendanceUseCase(studentsRepo),
      confirmAttendanceUseCase: ConfirmAttendanceUseCase(studentsRepo),
    );
    reportsCubit = ReportsCubit(
      getAttendanceStatsUseCase: GetAttendanceStatsUseCase(FakeReportsRepo()),
    );
    myClassesCubit = MyClassesCubit(
      getTeacherClassroomsUseCase: GetTeacherClassroomsUseCase(FakeTeacherRepo()),
    );
  });

  tearDown(() async {
    await historyCubit.close();
    await detailsCubit.close();
    await reportsCubit.close();
    await myClassesCubit.close();
  });

  group('Agent 4: Teacher Screens Widget Suite', () {
    testWidgets('1. AttendanceHistoryScreen mounts, calls loadHistory, and displays view and details', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableTeacherWidget(
          child: const AttendanceHistoryScreen(),
          historyCubit: historyCubit,
          detailsCubit: detailsCubit,
          reportsCubit: reportsCubit,
          myClassesCubit: myClassesCubit,
        ),
      );
      // Wait for cubit async completion and animations to settle
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(AttendanceHistoryScreen), findsOneWidget);
      expect(find.text('Class 3A'), findsOneWidget);

      // Tap the class card to transition to class detail view
      await tester.tap(find.text('Class 3A'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Verify header and summary counts are shown
      expect(find.text('18'), findsWidgets); // present count
      expect(find.text('2'), findsWidgets);  // absent count
      expect(find.text('سالم الهنائي'), findsOneWidget);
    });

    testWidgets('2. ClassDetailsScreen mounts with ClassroomEntity and renders list', (tester) async {
      const classroom = ClassroomEntity(
        id: 'cls_1',
        name: 'الصف الأول الابتدائي',
        grade: '1',
        studentCount: 20,
      );

      await tester.pumpWidget(
        buildTestableTeacherWidget(
          child: const ClassDetailsScreen(classroom: classroom),
          historyCubit: historyCubit,
          detailsCubit: detailsCubit,
          reportsCubit: reportsCubit,
          myClassesCubit: myClassesCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ClassDetailsScreen), findsOneWidget);
      expect(find.text('الصف الأول الابتدائي'), findsOneWidget);
    });

    testWidgets('3. ReportsScreen mounts, renders search and statistics cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableTeacherWidget(
          child: const ReportsScreen(),
          historyCubit: historyCubit,
          detailsCubit: detailsCubit,
          reportsCubit: reportsCubit,
          myClassesCubit: myClassesCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('4. MyClassesScreen mounts, loads classrooms and displays list', (tester) async {
      await tester.pumpWidget(
        buildTestableTeacherWidget(
          child: const MyClassesScreen(),
          historyCubit: historyCubit,
          detailsCubit: detailsCubit,
          reportsCubit: reportsCubit,
          myClassesCubit: myClassesCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(MyClassesScreen), findsOneWidget);
      expect(find.text('الصف الأول'), findsOneWidget);
    });
  });
}
