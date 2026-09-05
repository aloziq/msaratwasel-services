import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/features/driver/maintenance/domain/entities/bus_expense.dart';
import 'package:msaratwasel_services/features/driver/trip/data/datasources/trip_history_remote_datasource.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/data/datasources/fleet_remote_datasource.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/data/repositories/fleet_repository_impl.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/domain/entities/fleet_bus.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/change_password_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/login_usecase.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/reset_password_usecase.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/class_details_state.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';

import 'package:msaratwasel_services/features/field_supervisor/buses/data/models/fleet_bus_model.dart';

class _FailingFleetRemoteDataSource implements FleetRemoteDataSource {
  @override
  Future<List<FleetBusModel>> getFleetBuses() async {
    throw Exception('Database offline');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Entities, Params, Failures, and Edge Branches Suite', () {
    test('1. Failure hierarchy and props equality', () {
      const serverFail = ServerFailure('سيرفر غير متاح');
      const netFail = NetworkFailure('لا يوجد إنترنت');
      const validFail = ValidationFailure('بيانات غير صحيحة');
      const authFail = AuthFailure('فشل التحقق');
      const cacheFail = CacheFailure('فشل الذاكرة المؤقتة');

      expect(serverFail.props, ['سيرفر غير متاح']);
      expect(netFail.props, ['لا يوجد إنترنت']);
      expect(validFail.props, ['بيانات غير صحيحة']);
      expect(authFail.props, ['فشل التحقق']);
      expect(cacheFail.props, ['فشل الذاكرة المؤقتة']);

      expect(const ServerFailure('x'), equals(const ServerFailure('x')));
      expect(const ServerFailure('x'), isNot(equals(const ServerFailure('y'))));
    });

    test('2. ClassDetailsState props equality', () {
      expect(ClassDetailsInitial().props, isEmpty);
      expect(ClassDetailsLoading().props, isEmpty);

      final loaded1 = const ClassDetailsLoaded([], 'c1');
      final loaded2 = const ClassDetailsLoaded([], 'c1');
      final loaded3 = const ClassDetailsLoaded([], 'c2');
      expect(loaded1, equals(loaded2));
      expect(loaded1, isNot(equals(loaded3)));
      expect(loaded1.props, [<StudentEntity>[], 'c1']);

      const err1 = ClassDetailsError('خطأ');
      const err2 = ClassDetailsError('خطأ');
      expect(err1, equals(err2));
      expect(err1.props, ['خطأ']);
    });

    test('3. ClassroomEntity props equality', () {
      const c1 = ClassroomEntity(
        id: '1',
        name: 'الأول أ',
        nameEn: 'Grade 1A',
        grade: '1',
        studentCount: 20,
      );
      const c2 = ClassroomEntity(
        id: '1',
        name: 'الأول أ',
        nameEn: 'Grade 1A',
        grade: '1',
        studentCount: 20,
      );
      const c3 = ClassroomEntity(
        id: '2',
        name: 'الثاني ب',
        nameEn: 'Grade 2B',
        grade: '2',
        studentCount: 25,
      );

      expect(c1, equals(c2));
      expect(c1, isNot(equals(c3)));
      expect(c1.props, ['1', 'الأول أ', 'Grade 1A', '1', 20]);
    });

    test('4. Auth UseCase Params props equality', () {
      const p1 = ChangePasswordParams(
        currentPassword: 'old',
        newPassword: 'new',
        confirmPassword: 'new',
      );
      const p2 = ChangePasswordParams(
        currentPassword: 'old',
        newPassword: 'new',
        confirmPassword: 'new',
      );
      expect(p1, equals(p2));
      expect(p1.props, ['old', 'new', 'new']);

      const lp1 = LoginParams(id: 'user1', password: 'pass1');
      const lp2 = LoginParams(id: 'user1', password: 'pass1');
      expect(lp1, equals(lp2));
      expect(lp1.props, ['user1', 'pass1']);

      const rp1 = ResetPasswordParams(id: 'usr1');
      const rp2 = ResetPasswordParams(id: 'usr1');
      expect(rp1, equals(rp2));
      expect(rp1.props, ['usr1']);
    });

    test('5. BusExpense props equality', () {
      final now = DateTime(2026, 9, 5);
      final e1 = BusExpense(
        id: 1,
        busId: 10,
        type: 'fuel',
        amount: 25.5,
        date: now,
        extraInfo: '95 لتر',
        receiptPhoto: 'photo.jpg',
      );
      final e2 = BusExpense(
        id: 1,
        busId: 10,
        type: 'fuel',
        amount: 25.5,
        date: now,
        extraInfo: '95 لتر',
        receiptPhoto: 'photo.jpg',
      );
      expect(e1, equals(e2));
      expect(e1.props, [1, 10, 'fuel', 25.5, now, '95 لتر', 'photo.jpg']);
    });

    test('6. FleetRepositoryImpl catch branch returns ServerFailure on datasource error', () async {
      final repo = FleetRepositoryImpl(remoteDataSource: _FailingFleetRemoteDataSource());
      final result = await repo.getFleetBuses();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('Database offline')),
        (r) => fail('Should have failed'),
      );
    });

    test('7. TripHistoryRemoteDataSourceImpl rethrows on Dio error', () async {
      final dio = Dio();
      dio.httpClientAdapter = _AlwaysFailingAdapter();
      final ds = TripHistoryRemoteDataSourceImpl(dio);

      expect(
        () async => await ds.getTripsHistory(page: 1),
        throwsA(isA<DioException>()),
      );
    });

    test('8. AppRoutes constants integrity', () {
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.resetPassword, '/reset-password');
      expect(AppRoutes.teacherHome, '/');
      expect(AppRoutes.classDetails, '/class/:classId');
      expect(AppRoutes.myClasses, '/my-classes');
      expect(AppRoutes.attendanceHistory, '/attendance-history');
      expect(AppRoutes.settings, '/settings');
      expect(AppRoutes.qrScan, '/qr-scan');
      expect(AppRoutes.helpCenter, '/help-center');
      expect(AppRoutes.reports, '/reports');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.assistantHome, '/assistant');
      expect(AppRoutes.busStudents, '/bus-students');
      expect(AppRoutes.dailyChecklist, '/daily-checklist');
      expect(AppRoutes.incidentReport, '/incident-report');
      expect(AppRoutes.busMap, '/bus-map');
      expect(AppRoutes.messages, '/messages');
      expect(AppRoutes.chats, '/chats');
      expect(AppRoutes.supervisorHome, '/supervisor');
      expect(AppRoutes.supervisorBuses, '/supervisor/buses');
      expect(AppRoutes.driverHome, '/driver/home');
      expect(AppRoutes.driverRoute, '/driver/route');
      expect(AppRoutes.driverEndTrip, '/driver/end-trip');

      // Helper path builders
      expect(AppRoutes.classDetailsPath('123'), '/class/123');
      expect(AppRoutes.supervisorTrackingPath('456'), '/supervisor/tracking/456');
    });

    test('9. AppColors palette accents', () {
      expect(AppColors.slateGray.value, isNotNull);
      expect(AppColors.teal.value, isNotNull);
      expect(AppColors.skyBlue.value, isNotNull);
      expect(AppColors.indigo.value, isNotNull);
      expect(AppColors.purple.value, isNotNull);
      expect(AppColors.pink.value, isNotNull);
      expect(AppColors.cardDark.value, isNotNull);
      expect(AppColors.cardBorderDark.value, isNotNull);
      expect(AppColors.cardLightGray.value, isNotNull);
      expect(AppColors.cardBorderLight.value, isNotNull);
      expect(AppColors.twitter.value, isNotNull);
      expect(AppColors.instagram.value, isNotNull);
      expect(AppColors.facebook.value, isNotNull);
      expect(AppColors.whatsapp.value, isNotNull);
    });
  });
}

class _AlwaysFailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream? requestStream,
    Future? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      error: 'Network unreachable',
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}
