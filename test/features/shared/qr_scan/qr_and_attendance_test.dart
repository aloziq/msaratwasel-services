import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/features/shared/qr_scan/presentation/cubit/qr_scan_state.dart';
import 'package:msaratwasel_services/features/teacher/attendance_history/data/models/attendance_history_model.dart';

void main() {
  // ── QRScanState ────────────────────────────────────────────────────────────

  group('QRScanState classes', () {
    test('1. QRScanInitial is a QRScanState', () {
      expect(QRScanInitial(), isA<QRScanState>());
      expect(QRScanInitial().props, isEmpty);
    });

    test('2. QRScanLoading is a QRScanState', () {
      expect(QRScanLoading(), isA<QRScanState>());
      expect(QRScanLoading().props, isEmpty);
    });

    test('3. QRScanSuccess stores and exposes code', () {
      const state = QRScanSuccess('ABC-123');
      expect(state.code, 'ABC-123');
      expect(state.props, contains('ABC-123'));
    });

    test('4. QRScanError stores message', () {
      const state = QRScanError('حدث خطأ');
      expect(state.message, 'حدث خطأ');
      expect(state.props, contains('حدث خطأ'));
    });

    test('5. QRScanAttendanceSuccess stores studentId and evaluates props', () {
      const state = QRScanAttendanceSuccess('student_42');
      expect(state.studentId, 'student_42');
      expect(state.props.first, 'student_42');
      expect(state.props.length, 2);
    });

    test('6. QRScanTripSuccess stores name, status, message and evaluates props', () {
      const state = QRScanTripSuccess(
        studentName: 'أحمد',
        newStatus: 'onBus',
        message: 'تم تسجيل الصعود',
      );
      expect(state.studentName, 'أحمد');
      expect(state.newStatus, 'onBus');
      expect(state.message, 'تم تسجيل الصعود');
      expect(state.props.length, 4);
      expect(state.props[0], 'أحمد');
      expect(state.props[1], 'onBus');
      expect(state.props[2], 'تم تسجيل الصعود');
    });

    test('7. QRScanTripError stores message and evaluates props', () {
      const state = QRScanTripError('فشل الاتصال');
      expect(state.message, 'فشل الاتصال');
      expect(state.props.first, 'فشل الاتصال');
      expect(state.props.length, 2);
    });

    test('8. QRScanSuccess equality — same code same state', () {
      // Note: props includes the code so same code = same equality
      const a = QRScanSuccess('XYZ');
      const b = QRScanSuccess('XYZ');
      expect(a, equals(b));
    });

    test('9. QRScanSuccess inequality — different codes', () {
      const a = QRScanSuccess('ABC');
      const b = QRScanSuccess('DEF');
      expect(a, isNot(equals(b)));
    });

    test('10. QRScanError inequality — different messages', () {
      const a = QRScanError('error 1');
      const b = QRScanError('error 2');
      expect(a, isNot(equals(b)));
    });
  });

  // ── AttendanceHistoryRecordModel ───────────────────────────────────────────

  group('AttendanceHistoryRecordModel', () {
    Map<String, dynamic> recordJson() => {
      'date': '2025-09-01',
      'attendedStudents': [
        {
          'id': 's1',
          'name': 'طالب 1',
          'name_en': 'Student 1',
          'parent_name': 'ولي الأمر',
          'parent_name_en': 'Parent',
          'parent_phone': '05',
          'photo_url': null,
          'status': 'present',
        }
      ],
      'totalStudents': 30,
      'presentCount': 28,
      'absentCount': 2,
    };

    test('11. fromJson parses date correctly', () {
      final model = AttendanceHistoryRecordModel.fromJson(recordJson());
      expect(model.date, DateTime(2025, 9, 1));
    });

    test('12. fromJson parses counts correctly', () {
      final model = AttendanceHistoryRecordModel.fromJson(recordJson());
      expect(model.totalStudents, 30);
      expect(model.presentCount, 28);
      expect(model.absentCount, 2);
    });

    test('13. fromJson parses attendedStudents list', () {
      final model = AttendanceHistoryRecordModel.fromJson(recordJson());
      expect(model.attendedStudents.length, 1);
      expect(model.attendedStudents.first.name, 'طالب 1');
    });

    test('14. fromJson handles empty attendedStudents', () {
      final json = recordJson()..['attendedStudents'] = [];
      final model = AttendanceHistoryRecordModel.fromJson(json);
      expect(model.attendedStudents, isEmpty);
    });

    test('15. fromJson handles null attendedStudents', () {
      final json = recordJson()..['attendedStudents'] = null;
      final model = AttendanceHistoryRecordModel.fromJson(json);
      expect(model.attendedStudents, isEmpty);
    });

    test('16. fromJson defaults counts to 0 when missing', () {
      final json = {'date': '2025-01-01'};
      final model = AttendanceHistoryRecordModel.fromJson(json);
      expect(model.totalStudents, 0);
      expect(model.presentCount, 0);
      expect(model.absentCount, 0);
    });

    test('17. toJson round-trips date as ISO8601', () {
      final model = AttendanceHistoryRecordModel.fromJson(recordJson());
      final json = model.toJson();
      expect(json['date'], startsWith('2025-09-01'));
      expect(json['totalStudents'], 30);
      expect(json['presentCount'], 28);
    });

    test('18. toJson round-trips student list', () {
      final model = AttendanceHistoryRecordModel.fromJson(recordJson());
      final json = model.toJson();
      final students = json['attendedStudents'] as List;
      expect(students.length, 1);
      expect(students.first['name'], 'طالب 1');
    });
  });

  // ── AttendanceHistoryModel ─────────────────────────────────────────────────

  group('AttendanceHistoryModel', () {
    Map<String, dynamic> historyJson() => {
      'classId': 'cls_5',
      'className': 'الصف الثالث أ',
      'classNameEn': 'Grade 3 A',
      'dailyRecords': [
        {
          'date': '2025-09-01',
          'attendedStudents': [],
          'totalStudents': 25,
          'presentCount': 22,
          'absentCount': 3,
        },
        {
          'date': '2025-09-02',
          'attendedStudents': [],
          'totalStudents': 25,
          'presentCount': 24,
          'absentCount': 1,
        },
      ],
    };

    test('19. fromJson parses classId and className', () {
      final model = AttendanceHistoryModel.fromJson(historyJson());
      expect(model.classId, 'cls_5');
      expect(model.className, 'الصف الثالث أ');
      expect(model.classNameEn, 'Grade 3 A');
    });

    test('20. fromJson parses dailyRecords list', () {
      final model = AttendanceHistoryModel.fromJson(historyJson());
      expect(model.dailyRecords.length, 2);
    });

    test('21. fromJson uses id as fallback for classId', () {
      final json = historyJson()..remove('classId')..['id'] = 'cls_fallback';
      final model = AttendanceHistoryModel.fromJson(json);
      expect(model.classId, 'cls_fallback');
    });

    test('22. fromJson uses class_name as fallback for className', () {
      final json = historyJson()..remove('className')..['class_name'] = 'Fallback Class';
      final model = AttendanceHistoryModel.fromJson(json);
      expect(model.className, 'Fallback Class');
    });

    test('23. fromJson handles null classNameEn', () {
      final json = historyJson()..remove('classNameEn');
      final model = AttendanceHistoryModel.fromJson(json);
      expect(model.classNameEn, isNull);
    });

    test('24. fromJson handles empty dailyRecords', () {
      final json = historyJson()..['dailyRecords'] = [];
      final model = AttendanceHistoryModel.fromJson(json);
      expect(model.dailyRecords, isEmpty);
    });

    test('25. fromJson handles null dailyRecords', () {
      final json = historyJson()..['dailyRecords'] = null;
      final model = AttendanceHistoryModel.fromJson(json);
      expect(model.dailyRecords, isEmpty);
    });

    test('26. toJson round-trips classId and className', () {
      final model = AttendanceHistoryModel.fromJson(historyJson());
      final json = model.toJson();
      expect(json['classId'], 'cls_5');
      expect(json['className'], 'الصف الثالث أ');
      expect(json['classNameEn'], 'Grade 3 A');
    });

    test('27. toJson round-trips dailyRecords list', () {
      final model = AttendanceHistoryModel.fromJson(historyJson());
      final json = model.toJson();
      final records = json['dailyRecords'] as List;
      expect(records.length, 2);
    });

    test('28. dailyRecords have correct counts after parse', () {
      final model = AttendanceHistoryModel.fromJson(historyJson());
      expect(model.dailyRecords.first.presentCount, 22);
      expect(model.dailyRecords.last.absentCount, 1);
    });
  });
}
