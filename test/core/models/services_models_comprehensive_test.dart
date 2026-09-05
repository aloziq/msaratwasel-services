import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_services/features/assistant/core/data/models/bus_student_model.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/data/models/bus_trip_model.dart';
import 'package:msaratwasel_services/features/assistant/tracking/data/models/bus_position_model.dart';
import 'package:msaratwasel_services/features/assistant/tracking/domain/entities/bus_position.dart';
import 'package:msaratwasel_services/features/driver/home/data/models/trip_status_model.dart';
import 'package:msaratwasel_services/features/driver/maintenance/data/models/bus_expense_model.dart';
import 'package:msaratwasel_services/features/driver/route/data/models/student_stop_model.dart';
import 'package:msaratwasel_services/features/driver/trip/data/models/trip_history_model.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/data/models/fleet_bus_model.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/domain/entities/fleet_bus.dart';
import 'package:msaratwasel_services/features/shared/auth/data/models/user_model.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/messages/data/models/conversation_model.dart';
import 'package:msaratwasel_services/features/shared/messages/data/models/message_model.dart';
import 'package:msaratwasel_services/features/teacher/students/data/models/student_model.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/features/teacher/teacher/data/models/classroom_model.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/data/models/attendance_history_model.dart';
import 'package:msaratwasel_services/features/teacher/reports/data/models/report_model.dart';

void main() {
  group('Services App Models Comprehensive Suite', () {
    test('1. BusStudentModel parses JSON and serializes back properly', () {
      final json = {
        'id': 101,
        'student_code': 'ST-101',
        'name_ar': 'أحمد علي',
        'name_en': 'Ahmed Ali',
        'grade': 'الصف الثالث',
        'classroom': {'school_id': 'SCH-01'},
        'parentName': 'علي محمد',
        'parentPhone': '0555000000',
        'status': 'onBus',
        'waitingElapsedSeconds': '120',
        'forth_latitude': '24.7136',
        'forth_longitude': '46.6753',
      };

      final model = BusStudentModel.fromJson(json);
      expect(model.id, '101');
      expect(model.studentCode, 'ST-101');
      expect(model.name, 'أحمد علي');
      expect(model.status, BusStudentStatus.onBus);
      expect(model.forthLatitude, 24.7136);
      expect(model.forthLongitude, 46.6753);

      final outJson = model.toJson();
      expect(outJson['id'], '101');
      expect(outJson['status'], 'onBus');
    });

    test('2. BusTripModel parses nested students list and trip attributes', () {
      final json = {
        'id': 'trip-99',
        'busNumber': 'BUS-12',
        'driverName': 'سائق ماهر',
        'assistantName': 'مشرفة فاطمة',
        'students': [
          {
            'id': 'st-1',
            'name_ar': 'سارة',
            'grade': '1',
            'schoolId': 'sch-1',
            'parentName': 'الأب',
            'parentPhone': '050000',
            'status': 'waiting',
          }
        ],
        'startTime': '2026-09-04T07:00:00.000',
        'isCompleted': false,
        'suggested_direction': 'to_school',
        'trip_type': 'morning',
        'schoolLatitude': '24.7500',
        'schoolLongitude': '46.7000',
      };

      final trip = BusTripModel.fromJson(json);
      expect(trip.id, 'trip-99');
      expect(trip.students.length, 1);
      expect(trip.suggestedDirection, 'to_school');
      expect(trip.schoolLatitude, 24.75);

      final outJson = trip.toJson();
      expect(outJson['id'], 'trip-99');
      expect(outJson['busNumber'], 'BUS-12');
      expect((outJson['students'] as List).length, 1);
    });

    test('3. BusPositionModel handles GPS coordinates and bus states', () {
      final json = {
        'busId': 'bus-55',
        'lat': 24.7136,
        'lng': 46.6753,
        'speedKmh': 45.5,
        'distanceKm': 3.2,
        'etaMinutes': 8,
        'studentsOnBoard': 15,
        'state': 'enRoute',
        'updatedAt': '2026-09-04T07:15:00.000',
      };

      final pos = BusPositionModel.fromJson(json);
      expect(pos.busId, 'bus-55');
      expect(pos.state, BusState.enRoute);
      expect(pos.etaMinutes, 8);

      final out = pos.toJson();
      expect(out['state'], 'enRoute');
      expect(out['speedKmh'], 45.5);
    });

    test('4. TripStatusModel correctly computes isStarted and isCompleted', () {
      final jsonInProgress = {
        'id': 'trip-1',
        'status': 'in_progress',
        'type': 'forth',
        'type_label': 'ذهاب',
        'departure_time': '06:30 AM',
        'total_students': 20,
        'boarded_count': 18,
      };
      final tripInProgress = TripStatusModel.fromJson(jsonInProgress);
      expect(tripInProgress.isStarted, isTrue);
      expect(tripInProgress.isCompleted, isFalse);

      final jsonFinished = {
        'id': 'trip-1',
        'status': 'finished',
        'departure_time': '06:30 AM',
        'total_students': 20,
      };
      final tripFinished = TripStatusModel.fromJson(jsonFinished);
      expect(tripFinished.isStarted, isFalse);
      expect(tripFinished.isCompleted, isTrue);
    });

    test('5. BusExpenseModel handles numbers, dates, and extra_info', () {
      final json = {
        'id': 1,
        'bus_id': 4,
        'type': 'fuel',
        'amount': 250.75,
        'date': '2026-09-01T10:00:00.000',
        'extra_info': '124500 km',
        'receipt_photo': 'https://example.com/receipt.jpg',
      };

      final expense = BusExpenseModel.fromJson(json);
      expect(expense.id, 1);
      expect(expense.amount, 250.75);
      expect(expense.extraInfo, '124500 km');

      final out = expense.toJson();
      expect(out['amount'], 250.75);
      expect(out['type'], 'fuel');
    });

    test('6. StudentStopModel handles LatLng mapping and attendance flags', () {
      final json = {
        'id': 'stop-10',
        'nameAr': 'ياسر',
        'nameEn': 'Yasser',
        'parentAr': 'خالد',
        'parentEn': 'Khaled',
        'location': {'lat': 24.71, 'lng': 46.67},
        'isAbsent': false,
        'isBoarded': true,
        'isWaiting': false,
      };

      final stop = StudentStopModel.fromJson(json);
      expect(stop.id, 'stop-10');
      expect(stop.location.latitude, 24.71);
      expect(stop.location.longitude, 46.67);
      expect(stop.isBoarded, isTrue);

      final out = stop.toJson();
      expect(out['location']['lat'], 24.71);
    });

    test('7. TripHistoryModel and RouteModel parse correctly', () {
      final json = {
        'id': 77,
        'type': 'back',
        'type_label': 'عودة',
        'status': 'finished',
        'trip_date': '2026-09-03',
        'total_students': 22,
        'departure_time': '01:30 PM',
        'arrival_time': '02:15 PM',
        'route': {'id': 5, 'name': 'مسار حي الياسمين'},
      };

      final history = TripHistoryModel.fromJson(json);
      expect(history.id, 77);
      expect(history.route?.name, 'مسار حي الياسمين');

      final out = history.toJson();
      expect(out['route']['id'], 5);
    });

    test('8. FleetBusModel parses supervisor and telemetry fields', () {
      final json = {
        'id': 'bus-1',
        'bus_code': 'BUS-01',
        'driver': 'علي',
        'supervisor': 'منى',
        'school': 'مدارس النخبة',
        'driverPhone': '0555123456',
        'route': 'المسار الشرقي',
        'location_lat': 24.72,
        'location_lng': 46.68,
        'speed_kmh': 50.0,
        'studentsOnBoard': 18,
        'status': 'active',
        'last_update': '2026-09-04T07:30:00.000',
      };

      final fleet = FleetBusModel.fromJson(json);
      expect(fleet.id, 'bus-1');
      expect(fleet.name, 'BUS-01');
      expect(fleet.status, FleetBusStatus.active);
      expect(fleet.studentsOnBoard, 18);

      final out = fleet.toJson();
      expect(out['name'], 'BUS-01');
    });

    test('9. UserModel handles role enum, copyWith, and entity conversion', () {
      final json = {
        'id': 12,
        'name': 'سائق محمد',
        'role': 'driver',
        'token': 'jwt-sample-token',
        'bus_id': 3,
        'phone': '0501112233',
        'school_name': 'مدرسة الأمل',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, '12');
      expect(user.role, UserRole.driver);
      expect(user.busId, 3);

      final copy = user.copyWith(name: 'سائق أحمد', busId: 5);
      expect(copy.name, 'سائق أحمد');
      expect(copy.busId, 5);

      final fromEntity = UserModel.fromEntity(user);
      expect(fromEntity.id, user.id);
      expect(fromEntity.token, user.token);
    });

    test('10. ConversationModel and MessageModel parse chat payloads', () {
      final convJson = {
        'id': 'c-1',
        'parentName': 'أبو فهد',
        'studentName': 'فهد',
        'lastMessage': 'شكراً لكم',
        'lastMessageTime': '2026-09-04T08:00:00.000',
        'unreadCount': 2,
      };
      final conv = ConversationModel.fromJson(convJson);
      expect(conv.id, 'c-1');
      expect(conv.unreadCount, 2);

      final msgJson = {
        'id': 'm-1',
        'text': 'هل وصل الباص؟',
        'sender': 'parent',
        'time': '2026-09-04T08:05:00.000',
        'incoming': true,
      };
      final msg = MessageModel.fromJson(msgJson);
      expect(msg.incoming, isTrue);
      expect(msg.text, 'هل وصل الباص؟');
    });

    test('11. StudentModel & ClassroomModel parse teacher records', () {
      final studentJson = {
        'id': 50,
        'name_ar': 'عمر',
        'parent_name': 'سعيد',
        'parent_phone': '0599999999',
        'status': 'present',
        'isLocked': true,
      };
      final student = StudentModel.fromJson(studentJson);
      expect(student.id, '50');
      expect(student.status, AttendanceStatus.present);
      expect(student.isLocked, isTrue);

      final classJson = {
        'id': 10,
        'name_ar': 'الصف الرابع أ',
        'grade': '4',
        'student_count': 25,
      };
      final classroom = ClassroomModel.fromJson(classJson);
      expect(classroom.id, '10');
      expect(classroom.studentCount, 25);
    });

    test('12. AttendanceHistoryModel & ReportModel parse reports and stats', () {
      final recordJson = {
        'date': '2026-09-01T00:00:00.000',
        'attendedStudents': [],
        'totalStudents': 30,
        'presentCount': 28,
        'absentCount': 2,
      };
      final record = AttendanceHistoryRecordModel.fromJson(recordJson);
      expect(record.presentCount, 28);

      final reportJson = {
        'date': '2026-09-01T00:00:00.000',
        'attendancePercentage': 93.3,
      };
      final report = ReportModel.fromJson(reportJson);
      expect(report.attendancePercentage, 93.3);

      final studentReportJson = {
        'name_ar': 'خالد',
        'civil_id': '1099887766',
        'presentCount': 19,
        'absentCount': 1,
      };
      final studentReport = StudentReportModel.fromJson(studentReportJson);
      expect(studentReport.presentCount, 19);
      expect(studentReport.civilId, '1099887766');
    });
  });
}
