import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';

import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/network/api_config.dart';
import 'package:msaratwasel_services/core/utils/active_conversation_tracker.dart';
import 'package:msaratwasel_services/core/utils/location_utils.dart';
import 'package:msaratwasel_services/core/usecases/usecase.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/data/field_supervisor_remote_datasource.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/time_formatter.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/data/datasources/fleet_remote_datasource.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/domain/entities/fleet_bus.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/repositories/auth_repository.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/usecases/logout_usecase.dart';
import 'package:msaratwasel_services/features/shared/messages/domain/entities/conversation_entity.dart';
import 'package:msaratwasel_services/features/shared/messages/domain/entities/message_entity.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/data/datasources/attendance_history_remote_datasource.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/domain/entities/attendance_history_entity.dart';
import 'package:msaratwasel_services/features/teacher/reports/data/datasources/reports_remote_datasource.dart';
import 'package:msaratwasel_services/features/teacher/reports/domain/entities/report_entity.dart';
import 'package:msaratwasel_services/features/teacher/students/data/datasources/students_remote_datasource.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/features/teacher/teacher/data/datasources/teacher_local_datasource.dart';
import 'package:msaratwasel_services/features/teacher/teacher/data/datasources/teacher_remote_datasource.dart';
import 'package:msaratwasel_services/features/driver/trip/data/datasources/trip_history_remote_datasource.dart';

class FakeApiAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeAuthRepository implements AuthRepository {
  bool logoutCalled = false;

  @override
  Future<Either<Failure, void>> logout() async {
    logoutCalled = true;
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiAdapter mockAdapter;

  setUp(() {
    mockAdapter = FakeApiAdapter();
    final testDio = Dio(
      BaseOptions(
        baseUrl: 'https://test.wasel.com/api/',
        connectTimeout: const Duration(seconds: 5),
      ),
    );
    testDio.httpClientAdapter = mockAdapter;
    ApiClient.testDio = testDio;
  });

  tearDown(() {
    ApiClient.testDio = null;
  });

  group('1. FieldSupervisorRemoteDataSource Tests', () {
    test('getDashboardStats returns mapped stats on success', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('field/dashboard-stats')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'active_buses': 12,
                'active_drivers': 10,
                'active_trips': 8,
              },
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final stats = await FieldSupervisorRemoteDataSource.getDashboardStats();
      expect(stats['active_buses'], 12);
      expect(stats['active_drivers'], 10);
      expect(stats['active_trips'], 8);
    });

    test('getDashboardStats returns zeros on error or non-200', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString('{"success": false}', 500);
      };

      final stats = await FieldSupervisorRemoteDataSource.getDashboardStats();
      expect(stats['active_buses'], 0);
      expect(stats['active_drivers'], 0);
      expect(stats['active_trips'], 0);
    });

    test('getBuses returns list of buses on success and empty list on catch', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('field/buses')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1, 'bus_code': 'BUS-01'},
                {'id': 2, 'bus_code': 'BUS-02'},
              ],
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final buses = await FieldSupervisorRemoteDataSource.getBuses();
      expect(buses.length, 2);
      expect(buses.first['bus_code'], 'BUS-01');

      mockAdapter.handler = (options) => throw DioException(requestOptions: options);
      final emptyBuses = await FieldSupervisorRemoteDataSource.getBuses();
      expect(emptyBuses, isEmpty);
    });

    test('getStaff returns drivers and supervisors', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'drivers': [{'id': 1, 'name': 'Driver Ali'}],
              'supervisors': [{'id': 2, 'name': 'Supervisor Omar'}],
            },
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final staff = await FieldSupervisorRemoteDataSource.getStaff();
      expect(staff['drivers']?.length, 1);
      expect(staff['supervisors']?.length, 1);

      mockAdapter.handler = (options) => throw DioException(requestOptions: options);
      final failedStaff = await FieldSupervisorRemoteDataSource.getStaff();
      expect(failedStaff['drivers'], isEmpty);
      expect(failedStaff['supervisors'], isEmpty);
    });

    test('getInspectionItems returns checklist items', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 10, 'name': 'Tires check'},
            ],
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final items = await FieldSupervisorRemoteDataSource.getInspectionItems();
      expect(items.length, 1);
      expect(items.first['id'], 10);

      mockAdapter.handler = (options) => throw DioException(requestOptions: options);
      expect(await FieldSupervisorRemoteDataSource.getInspectionItems(), isEmpty);
    });

    test('submitInspection without photos sends JSON map', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'inspection_id': 99},
          }),
          201,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final result = await FieldSupervisorRemoteDataSource.submitInspection(
        busId: 5,
        overallStatus: 'passed',
        results: [
          {'item_id': 1, 'is_passed': true, 'notes': 'all good'},
        ],
        notes: 'General check complete',
      );

      expect(result, isNotNull);
      expect(result!['inspection_id'], 99);
    });

    test('submitInspection handles errors and non-201 gracefully', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'success': false}),
          400,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final result = await FieldSupervisorRemoteDataSource.submitInspection(
        busId: 5,
        overallStatus: 'failed',
        results: [],
      );
      expect(result, isNull);

      mockAdapter.handler = (options) => throw DioException(requestOptions: options);

      final errorResult = await FieldSupervisorRemoteDataSource.submitInspection(
        busId: 5,
        overallStatus: 'failed',
        results: [],
      );
      expect(errorResult, isNull);
    });

    test('reportIncident handles coordinates, studentIds and errors', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'incident_id': 45},
          }),
          201,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final incident = await FieldSupervisorRemoteDataSource.reportIncident(
        busId: 2,
        type: 'accident',
        severity: 'high',
        description: 'Minor tire puncture',
        locationLat: 23.5,
        locationLng: 58.4,
        studentIds: [101, 102],
      );

      expect(incident, isNotNull);
      expect(incident!['incident_id'], 45);

      mockAdapter.handler = (options) => throw DioException(requestOptions: options);

      final failed = await FieldSupervisorRemoteDataSource.reportIncident(
        type: 'sos',
        severity: 'critical',
        description: 'SOS alert',
      );
      expect(failed, isNull);
    });

    test('submitViolation, getIncidents, getInspections, getFieldTrips', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('field/violations')) {
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': {'id': 7}}),
            201,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/incidents')) {
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': [{'id': 1}]}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/inspections')) {
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': [{'id': 2}]}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/field-trips')) {
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': [{'id': 3}]}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final violation = await FieldSupervisorRemoteDataSource.submitViolation(
        busId: 3,
        type: 'speeding',
        description: 'Exceeded 100km/h',
      );
      expect(violation?['id'], 7);

      expect((await FieldSupervisorRemoteDataSource.getIncidents()).length, 1);
      expect((await FieldSupervisorRemoteDataSource.getInspections()).length, 1);
      expect((await FieldSupervisorRemoteDataSource.getFieldTrips()).length, 1);
    });

    test('getDashboardReport, getDelays, storeDelay, and getStudents', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('field/report')) {
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': {'total_inspections': 25}}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/delays') && options.method == 'GET') {
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': [{'id': 4, 'duration_minutes': 15}]}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/delays') && options.method == 'POST') {
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': {'delay_id': 88}}),
            201,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('field/students')) {
          return ResponseBody.fromString(
            jsonEncode({'success': true, 'data': [{'id': 12, 'name': 'Ahmed'}]}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final report = await FieldSupervisorRemoteDataSource.getDashboardReport();
      expect(report['total_inspections'], 25);

      final delays = await FieldSupervisorRemoteDataSource.getDelays(type: 'traffic');
      expect(delays.length, 1);

      final storedDelay = await FieldSupervisorRemoteDataSource.storeDelay(
        type: 'weather',
        durationMinutes: 20,
        busId: 4,
        reason: 'Heavy rain',
        notes: 'Route delayed',
      );
      expect(storedDelay?['delay_id'], 88);

      final students = await FieldSupervisorRemoteDataSource.getStudents(search: 'Ahmed');
      expect(students.first['name'], 'Ahmed');
    });
  });

  group('2. FleetRemoteDataSourceImpl Tests', () {
    test('getFleetBuses maps status correctly (active, maintenance, stopped)', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 101,
                'bus_code': 'BUS-101',
                'driver': 'Salem',
                'supervisor': 'Nasser',
                'school': 'Al-Amal School',
                'status': 'active',
                'location_lat': 23.58,
                'location_lng': 58.40,
                'speed_kmh': 45.0,
                'last_update': '2026-09-04T12:00:00Z',
              },
              {
                'id': 102,
                'bus_number': '55',
                'status': 'maintenance',
              },
              {
                'id': 103,
                'status': 'unknown_status',
              },
            ],
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final ds = FleetRemoteDataSourceImpl();
      final buses = await ds.getFleetBuses();

      expect(buses.length, 3);
      expect(buses[0].status, FleetBusStatus.active);
      expect(buses[0].name, 'BUS-101');
      expect(buses[0].driverName, 'Salem');
      expect(buses[1].status, FleetBusStatus.maintenance);
      expect(buses[1].name, 'حافلة 55');
      expect(buses[2].status, FleetBusStatus.stopped);
    });

    test('getFleetBuses returns empty list on network error', () async {
      mockAdapter.handler = (options) => throw DioException(requestOptions: options);

      final ds = FleetRemoteDataSourceImpl();
      final buses = await ds.getFleetBuses();
      expect(buses, isEmpty);
    });
  });

  group('3. Teacher DataSources Tests', () {
    test('TeacherRemoteDataSourceImpl fetches classrooms or rethrows on error', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode([
            {'id': 'c1', 'name': 'الصف الأول', 'grade': '1', 'student_count': 20},
          ]),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final remoteDS = TeacherRemoteDataSourceImpl();
      final classes = await remoteDS.getTeacherClassrooms();
      expect(classes.length, 1);
      expect(classes.first.name, 'الصف الأول');

      mockAdapter.handler = (options) => throw Exception('Server error');
      expect(() => remoteDS.getTeacherClassrooms(), throwsException);
    });

    test('TeacherLocalDataSourceImpl returns mock classes', () async {
      final localDS = TeacherLocalDataSourceImpl();
      final singleClass = await localDS.getTeacherClassroom();
      expect(singleClass.id, '1');

      final classes = await localDS.getTeacherClassrooms();
      expect(classes.length, 3);
    });

    test('AttendanceHistoryRemoteDataSourceImpl fetches and parses history', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode([
            {
              'classId': 'c1',
              'className': 'Class A',
              'dailyRecords': [
                {
                  'date': '2026-09-01T08:00:00Z',
                  'totalStudents': 30,
                  'presentCount': 28,
                  'absentCount': 2,
                  'attendedStudents': [],
                }
              ],
            }
          ]),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final ds = AttendanceHistoryRemoteDataSourceImpl();
      final history = await ds.getTeacherAttendanceHistory();
      expect(history.length, 1);
      expect(history.first.dailyRecords.first.attendanceRate, closeTo(93.33, 0.1));

      mockAdapter.handler = (options) => throw Exception('Fail');
      expect(() => ds.getTeacherAttendanceHistory(), throwsException);
    });

    test('StudentsRemoteDataSourceImpl methods (get, mark, confirm)', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('students') && options.method == 'GET') {
          return ResponseBody.fromString(
            jsonEncode([
              {
                'id': 's1',
                'name': 'Khalid',
                'status': 'present',
                'parentName': 'P',
                'parentPhone': '123',
              }
            ]),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 200);
      };

      final ds = StudentsRemoteDataSourceImpl();
      final students = await ds.getStudentsByClass('c1');
      expect(students.length, 1);

      await expectLater(ds.markAttendance('s1', AttendanceStatus.present, viaQr: true), completes);
      await expectLater(ds.confirmAttendance('c1'), completes);
    });

    test('ReportsRemoteDataSourceImpl direct stats and local fallback', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'totalStudents': 50,
            'presentToday': 45,
            'absentToday': 5,
            'unmarkedToday': 0,
            'averageAttendance': 90.0,
            'weeklyTrend': [],
            'studentReports': [],
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final ds = ReportsRemoteDataSourceImpl();
      final stats = await ds.getAttendanceStats();
      expect(stats.totalStudents, 50);
      expect(stats.averageAttendance, 90.0);

      // Test fallback calculation
      mockAdapter.handler = (options) {
        if (options.path.contains('reports/stats')) {
          throw DioException(requestOptions: options);
        }
        if (options.path.contains('teacher/classes') && !options.path.contains('students')) {
          return ResponseBody.fromString(
            jsonEncode([{'id': 'c1'}]),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('teacher/classes/c1/students')) {
          return ResponseBody.fromString(
            jsonEncode([
              {'name': 'Ali', 'civil_id': '111', 'status': 'present'},
              {'name': 'Sara', 'civil_id': '222', 'status': 'absent'},
            ]),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final fallbackStats = await ds.getAttendanceStats();
      expect(fallbackStats.totalStudents, 2);
      expect(fallbackStats.presentToday, 1);
      expect(fallbackStats.absentToday, 1);
      expect(fallbackStats.averageAttendance, 50.0);
    });
  });

  group('4. Driver TripHistoryRemoteDataSourceImpl Tests', () {
    test('getTripsHistory calls endpoint and returns parsed response', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'trips': [
              {
                'id': 1,
                'type': 'morning',
                'type_label': 'صباحية',
                'status': 'completed',
                'trip_date': '2026-09-04',
                'total_students': 15,
                'departure_time': '07:00',
                'arrival_time': '08:00',
              }
            ],
            'pagination': {
              'current_page': 1,
              'last_page': 1,
              'total': 1,
            },
            'filters': {
              'start_date': '2026-09-01',
              'end_date': '2026-09-04',
              'status': 'completed',
            },
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final ds = TripHistoryRemoteDataSourceImpl(ApiClient.instance);
      final res = await ds.getTripsHistory(page: 1, status: 'completed');
      expect(res.trips.length, 1);
      expect(res.trips.first.type, 'morning');
    });
  });

  group('5. BusStudentEntity Localization & Parsing Tests', () {
    test('BusStudentStatus labels in Arabic', () {
      expect(BusStudentStatus.atHome.labelAr, 'في المنزل');
      expect(BusStudentStatus.onBus.labelAr, 'في الحافلة');
      expect(BusStudentStatus.atSchool.labelAr, 'في المدرسة');
      expect(BusStudentStatus.absent.labelAr, 'غائب');
      expect(BusStudentStatus.waiting.labelAr, 'انتظار');
      expect(BusStudentStatus.unknown.labelAr, 'غير محدد');
    });

    test('getLocalizedName returns English name if available and requested', () {
      const student = BusStudentEntity(
        id: '1',
        studentCode: 'ST-1',
        name: 'يوسف أحمد',
        nameEn: 'Youssef Ahmed',
        grade: 'أول ابتدائي',
        schoolId: 'SCH-1',
        parentName: 'أحمد',
        parentPhone: '99001122',
      );

      expect(student.getLocalizedName('ar'), 'يوسف أحمد');
      expect(student.getLocalizedName('en'), 'Youssef Ahmed');

      const studentNoEn = BusStudentEntity(
        id: '2',
        studentCode: 'ST-2',
        name: 'سالم',
        grade: 'ثاني',
        schoolId: 'SCH-1',
        parentName: 'ناصر',
        parentPhone: '99001123',
      );
      expect(studentNoEn.getLocalizedName('en'), 'سالم');
    });

    test('getLocalizedGrade maps stages and ordinals accurately', () {
      const s1 = BusStudentEntity(
        id: '1',
        studentCode: '1',
        name: 'N',
        grade: 'حضانة',
        schoolId: '1',
        parentName: 'P',
        parentPhone: '0',
      );
      expect(s1.getLocalizedGrade('en'), 'Nursery');
      expect(s1.getLocalizedGrade('ar'), 'حضانة');

      const s2 = BusStudentEntity(
        id: '2',
        studentCode: '2',
        name: 'N',
        grade: 'أول ابتدائي',
        schoolId: '1',
        parentName: 'P',
        parentPhone: '0',
      );
      expect(s2.getLocalizedGrade('en'), '1st Primary');

      const s3 = BusStudentEntity(
        id: '3',
        studentCode: '3',
        name: 'N',
        grade: 'الصف الثاني متوسط',
        schoolId: '1',
        parentName: 'P',
        parentPhone: '0',
      );
      expect(s3.getLocalizedGrade('en'), '2nd Intermediate');

      const s4 = BusStudentEntity(
        id: '4',
        studentCode: '4',
        name: 'N',
        grade: 'ثالث ثانوي',
        schoolId: '1',
        parentName: 'P',
        parentPhone: '0',
      );
      expect(s4.getLocalizedGrade('en'), '3rd Secondary');

      const s5 = BusStudentEntity(
        id: '5',
        studentCode: '5',
        name: 'N',
        grade: 'غير محدد',
        schoolId: '1',
        parentName: 'P',
        parentPhone: '0',
      );
      expect(s5.getLocalizedGrade('en'), 'Not Specified');
    });

    test('BusStudentEntity copyWith and props', () {
      const original = BusStudentEntity(
        id: '1',
        studentCode: '1',
        name: 'Ali',
        grade: '1',
        schoolId: 'S',
        parentName: 'P',
        parentPhone: '00',
        status: BusStudentStatus.atHome,
      );

      final copied = original.copyWith(status: BusStudentStatus.onBus);
      expect(copied.status, BusStudentStatus.onBus);
      expect(copied.name, 'Ali');
      expect(original.props.contains('Ali'), isTrue);
    });
  });

  group('6. Utilities, Config & LogoutUseCase Tests', () {
    test('TimeFormatter relative formatters', () {
      final now = DateTime.now();
      final tenMinAgo = now.subtract(const Duration(minutes: 10));
      final threeHoursAgo = now.subtract(const Duration(hours: 3));
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      expect(formatRelativeTime(tenMinAgo), contains('منذ 10 دقيقة'));
      expect(formatRelativeTime(threeHoursAgo), contains('منذ 3 ساعة'));
      expect(formatRelativeTime(twoDaysAgo), contains('منذ 2 يوم'));

      expect(formatRelativeTimeCompact(tenMinAgo), '10د');
      expect(formatRelativeTimeCompact(threeHoursAgo), '3س');
      expect(formatRelativeTimeCompact(twoDaysAgo), '2ي');
    });

    test('ApiConfig URLs and getImageUrl resolution', () {
      expect(ApiConfig.baseUrl.isNotEmpty, isTrue);
      expect(ApiConfig.domainUrl.isNotEmpty, isTrue);

      expect(ApiConfig.getImageUrl(null), contains('ui-avatars.com'));
      expect(ApiConfig.getImageUrl(''), contains('ui-avatars.com'));
      expect(ApiConfig.getImageUrl('https://custom.com/pic.jpg'), 'https://custom.com/pic.jpg');
      expect(ApiConfig.getImageUrl('/storage/photos/pic.jpg'), contains('/storage/photos/pic.jpg'));
      expect(ApiConfig.getImageUrl('storage/photos/pic.jpg'), contains('/storage/photos/pic.jpg'));
      expect(ApiConfig.getImageUrl('photos/pic.jpg'), contains('/storage/photos/pic.jpg'));
    });

    test('LocationUtils ETA and distance calculation', () {
      expect(LocationUtils.calculateEtaMinutes(80.0), 60.0);
      expect(LocationUtils.calculateEtaMinutesRounded(80.0), 60);

      expect(LocationUtils.formatEtaArabic(80.0), '1 ساعة');
      expect(LocationUtils.formatEtaArabic(100.0), '1 ساعة و 15 دقيقة');
      expect(LocationUtils.formatEtaArabic(20.0), '15 دقيقة');

      expect(LocationUtils.formatEtaEnglish(80.0), '1 hr');
      expect(LocationUtils.formatEtaEnglish(100.0), '1 hr 15 min');
      expect(LocationUtils.formatEtaEnglish(20.0), '15 min');

      final distance = LocationUtils.calculateDistance(23.5859, 58.4059, 23.5959, 58.4159);
      expect(distance, greaterThan(0));
    });

    test('ActiveConversationTracker getter and setter', () {
      expect(ActiveConversationTracker.activeConversationId, isNull);
      ActiveConversationTracker.setActiveConversation('conv_99');
      expect(ActiveConversationTracker.activeConversationId, 'conv_99');
      ActiveConversationTracker.clearActiveConversation();
      expect(ActiveConversationTracker.activeConversationId, isNull);
    });

    test('LogoutUseCase executes repository.logout', () async {
      final fakeAuthRepo = FakeAuthRepository();
      final logoutUseCase = LogoutUseCase(fakeAuthRepo);
      final res = await logoutUseCase(const NoParams());
      expect(res.isRight(), isTrue);
      expect(fakeAuthRepo.logoutCalled, isTrue);
    });

    test('FleetBus, ConversationEntity, and MessageEntity copyWith and props', () {
      final bus = FleetBus(
        id: '1',
        name: 'Bus 1',
        driverName: 'D',
        supervisorName: 'S',
        schoolName: 'School',
        driverPhone: '123',
        route: 'Route A',
        lat: 23.0,
        lng: 58.0,
        speedKmh: 40.0,
        studentsOnBoard: 5,
        status: FleetBusStatus.active,
        updatedAt: DateTime.now(),
      );
      expect(bus.props.length, 16);

      final conv = ConversationEntity(
        id: '1',
        parentName: 'Parent',
        studentName: 'Student',
        lastMessage: 'Hello',
        lastMessageTime: DateTime.now(),
      );
      final copiedConv = conv.copyWith(lastMessage: 'Updated');
      expect(copiedConv.lastMessage, 'Updated');
      expect(conv.props.contains('Parent'), isTrue);

      final msg = MessageEntity(
        id: 'm1',
        text: 'Test',
        sender: 'Me',
        time: DateTime.now(),
        incoming: false,
      );
      final copiedMsg = msg.copyWith(text: 'Edited');
      expect(copiedMsg.text, 'Edited');
      expect(msg.props.contains('Test'), isTrue);
    });

    test('ReportEntity, StudentReportEntity, and AttendanceStatsEntity', () {
      final now = DateTime.now();
      final report = ReportEntity(date: now, attendancePercentage: 95.0);
      expect(report.props, [now, 95.0]);

      const studentReport = StudentReportEntity(
        name: 'ماجد',
        nameEn: 'Majid',
        presentCount: 5,
        absentCount: 0,
      );
      expect(studentReport.getLocalizedName('en'), 'Majid');
      expect(studentReport.getLocalizedName('ar'), 'ماجد');

      final stats = AttendanceStatsEntity(
        totalStudents: 10,
        presentToday: 9,
        absentToday: 1,
        unmarkedToday: 0,
        averageAttendance: 90.0,
        weeklyTrend: [report],
        studentReports: [studentReport],
      );
      expect(stats.props.length, 7);
    });
  });
}
