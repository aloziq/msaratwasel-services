import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/features/driver/trip/data/models/trip_history_model.dart';
import 'package:msaratwasel_services/features/teacher/reports/data/models/report_model.dart';

Map<String, dynamic> tripJson({bool withRoute = true, bool withTimes = true}) => {
  'id': 101,
  'type': 'morning',
  'type_label': 'رحلة الصباح',
  'status': 'completed',
  'trip_date': '2025-09-01',
  'total_students': 35,
  if (withTimes) 'departure_time': '07:00',
  if (withTimes) 'arrival_time': '07:45',
  if (withRoute) 'route': {'id': 5, 'name': 'المسار الشمالي'},
};

void main() {
  // ── TripHistoryModel ───────────────────────────────────────────────────────

  group('TripHistoryModel', () {
    test('1. fromJson parses all fields', () {
      final m = TripHistoryModel.fromJson(tripJson());
      expect(m.id, 101);
      expect(m.type, 'morning');
      expect(m.typeLabel, 'رحلة الصباح');
      expect(m.status, 'completed');
      expect(m.tripDate, '2025-09-01');
      expect(m.totalStudents, 35);
      expect(m.departureTime, '07:00');
      expect(m.arrivalTime, '07:45');
    });

    test('2. fromJson parses nested route', () {
      final m = TripHistoryModel.fromJson(tripJson());
      expect(m.route, isNotNull);
      expect(m.route!.id, 5);
      expect(m.route!.name, 'المسار الشمالي');
    });

    test('3. fromJson handles null route', () {
      final json = tripJson()..['route'] = null;
      final m = TripHistoryModel.fromJson(json);
      expect(m.route, isNull);
    });

    test('4. fromJson handles null departure/arrival times', () {
      final m = TripHistoryModel.fromJson(tripJson(withTimes: false));
      expect(m.departureTime, isNull);
      expect(m.arrivalTime, isNull);
    });

    test('5. toJson round-trips all fields', () {
      final m = TripHistoryModel.fromJson(tripJson());
      final json = m.toJson();
      expect(json['id'], 101);
      expect(json['type'], 'morning');
      expect(json['status'], 'completed');
      expect(json['total_students'], 35);
      expect(json['departure_time'], '07:00');
    });

    test('6. toJson includes route when present', () {
      final m = TripHistoryModel.fromJson(tripJson());
      final json = m.toJson();
      expect(json['route'], isNotNull);
      expect((json['route'] as Map)['name'], 'المسار الشمالي');
    });

    test('7. toJson has null route when missing', () {
      final m = TripHistoryModel.fromJson(tripJson()..['route'] = null);
      expect(m.toJson()['route'], isNull);
    });
  });

  // ── RouteModel ─────────────────────────────────────────────────────────────

  group('RouteModel', () {
    test('8. fromJson and toJson round-trip', () {
      final r = RouteModel.fromJson({'id': 3, 'name': 'المسار الجنوبي'});
      expect(r.id, 3);
      expect(r.name, 'المسار الجنوبي');
      final json = r.toJson();
      expect(json['id'], 3);
      expect(json['name'], 'المسار الجنوبي');
    });
  });

  // ── PaginationModel ────────────────────────────────────────────────────────

  group('PaginationModel', () {
    test('9. fromJson and toJson round-trip', () {
      final p = PaginationModel.fromJson({'current_page': 2, 'last_page': 5, 'total': 50});
      expect(p.currentPage, 2);
      expect(p.lastPage, 5);
      expect(p.total, 50);
      final json = p.toJson();
      expect(json['current_page'], 2);
      expect(json['total'], 50);
    });
  });

  // ── FiltersModel ───────────────────────────────────────────────────────────

  group('FiltersModel', () {
    test('10. fromJson with status', () {
      final f = FiltersModel.fromJson({'start_date': '2025-01-01', 'end_date': '2025-01-31', 'status': 'completed'});
      expect(f.startDate, '2025-01-01');
      expect(f.endDate, '2025-01-31');
      expect(f.status, 'completed');
    });

    test('11. fromJson with null status', () {
      final f = FiltersModel.fromJson({'start_date': '2025-01-01', 'end_date': '2025-01-31'});
      expect(f.status, isNull);
    });

    test('12. toJson round-trips', () {
      final f = FiltersModel.fromJson({'start_date': '2025-01-01', 'end_date': '2025-01-31', 'status': 'pending'});
      final json = f.toJson();
      expect(json['start_date'], '2025-01-01');
      expect(json['status'], 'pending');
    });
  });

  // ── TripHistoryResponse ────────────────────────────────────────────────────

  group('TripHistoryResponse', () {
    test('13. fromJson parses trips, pagination, filters together', () {
      final json = {
        'trips': [tripJson()],
        'pagination': {'current_page': 1, 'last_page': 3, 'total': 25},
        'filters': {'start_date': '2025-09-01', 'end_date': '2025-09-30'},
      };
      final resp = TripHistoryResponse.fromJson(json);
      expect(resp.trips.length, 1);
      expect(resp.pagination.total, 25);
      expect(resp.filters.startDate, '2025-09-01');
    });

    test('14. toJson round-trips full response', () {
      final json = {
        'trips': [tripJson()],
        'pagination': {'current_page': 1, 'last_page': 1, 'total': 1},
        'filters': {'start_date': '2025-09-01', 'end_date': '2025-09-30'},
      };
      final resp = TripHistoryResponse.fromJson(json);
      final out = resp.toJson();
      expect((out['trips'] as List).length, 1);
      expect((out['pagination'] as Map)['total'], 1);
    });
  });

  // ── ReportModel ────────────────────────────────────────────────────────────

  group('ReportModel', () {
    test('15. fromJson parses date and percentage', () {
      final m = ReportModel.fromJson({'date': '2025-09-01', 'attendancePercentage': 92.5});
      expect(m.date, DateTime(2025, 9, 1));
      expect(m.attendancePercentage, 92.5);
    });

    test('16. fromJson uses DateTime.now() when date is null', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final m = ReportModel.fromJson({'attendancePercentage': 80.0});
      expect(m.date.isAfter(before), isTrue);
    });

    test('17. fromJson defaults percentage to 0.0', () {
      final m = ReportModel.fromJson({'date': '2025-09-01'});
      expect(m.attendancePercentage, 0.0);
    });

    test('18. toJson round-trips', () {
      final m = ReportModel.fromJson({'date': '2025-09-01', 'attendancePercentage': 75.0});
      final json = m.toJson();
      expect(json['attendancePercentage'], 75.0);
      expect((json['date'] as String), startsWith('2025-09-01'));
    });
  });

  // ── StudentReportModel ─────────────────────────────────────────────────────

  group('StudentReportModel', () {
    test('19. fromJson uses name_ar field', () {
      final m = StudentReportModel.fromJson({'name_ar': 'علي', 'presentCount': 20, 'absentCount': 2});
      expect(m.name, 'علي');
    });

    test('20. fromJson falls back to name field', () {
      final m = StudentReportModel.fromJson({'name': 'Ali', 'presentCount': 10, 'absentCount': 0});
      expect(m.name, 'Ali');
    });

    test('21. fromJson defaults name to "غير معروف"', () {
      final m = StudentReportModel.fromJson({'presentCount': 5, 'absentCount': 1});
      expect(m.name, 'غير معروف');
    });

    test('22. fromJson parses civil_id and photo_url', () {
      final m = StudentReportModel.fromJson({
        'name': 'X', 'presentCount': 0, 'absentCount': 0,
        'civil_id': '12345', 'photo_url': 'https://img.com/p.jpg',
      });
      expect(m.civilId, '12345');
      expect(m.photoUrl, 'https://img.com/p.jpg');
    });

    test('23. toJson round-trips', () {
      final m = StudentReportModel.fromJson({'name': 'Nora', 'presentCount': 18, 'absentCount': 2});
      final json = m.toJson();
      expect(json['name'], 'Nora');
      expect(json['presentCount'], 18);
    });
  });

  // ── AttendanceStatsModel ───────────────────────────────────────────────────

  group('AttendanceStatsModel', () {
    Map<String, dynamic> statsJson() => {
      'totalStudents': 30,
      'presentToday': 25,
      'absentToday': 3,
      'unmarkedToday': 2,
      'averageAttendance': 88.5,
      'weeklyTrend': [
        {'date': '2025-09-01', 'attendancePercentage': 90.0},
        {'date': '2025-09-02', 'attendancePercentage': 85.0},
      ],
      'studentReports': [
        {'name': 'طالب 1', 'presentCount': 18, 'absentCount': 2},
      ],
    };

    test('24. fromJson parses counts correctly', () {
      final m = AttendanceStatsModel.fromJson(statsJson());
      expect(m.totalStudents, 30);
      expect(m.presentToday, 25);
      expect(m.absentToday, 3);
      expect(m.unmarkedToday, 2);
      expect(m.averageAttendance, 88.5);
    });

    test('25. fromJson computes unmarked when missing', () {
      final json = statsJson()..remove('unmarkedToday');
      final m = AttendanceStatsModel.fromJson(json);
      // 30 - 25 - 3 = 2
      expect(m.unmarkedToday, 2);
    });

    test('26. fromJson parses weeklyTrend list', () {
      final m = AttendanceStatsModel.fromJson(statsJson());
      expect(m.weeklyTrend.length, 2);
      expect(m.weeklyTrend.first.attendancePercentage, 90.0);
    });

    test('27. fromJson handles empty weeklyTrend', () {
      final json = statsJson()..['weeklyTrend'] = [];
      expect(AttendanceStatsModel.fromJson(json).weeklyTrend, isEmpty);
    });

    test('28. fromJson parses studentReports list', () {
      final m = AttendanceStatsModel.fromJson(statsJson());
      expect(m.studentReports.length, 1);
    });

    test('29. toJson round-trips all scalar fields', () {
      final m = AttendanceStatsModel.fromJson(statsJson());
      final json = m.toJson();
      expect(json['totalStudents'], 30);
      expect(json['averageAttendance'], 88.5);
      expect((json['weeklyTrend'] as List).length, 2);
      expect((json['studentReports'] as List).length, 1);
    });
  });
}
