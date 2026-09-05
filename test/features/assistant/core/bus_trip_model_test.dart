import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/features/assistant/core/data/models/bus_student_model.dart';
import 'package:msaratwasel_services/features/assistant/core/data/models/bus_trip_model.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_trip_entity.dart';

void main() {
  group('BusTripModel & BusTripEntity Suite', () {
    final now = DateTime(2026, 9, 5, 8, 30);
    final end = DateTime(2026, 9, 5, 9, 15);

    final sampleStudent = BusStudentModel(
      id: 's1',
      studentCode: 'CODE101',
      name: 'سالم أحمد',
      grade: 'الرابع',
      schoolId: 'SCH1',
      parentName: 'أحمد',
      parentPhone: '96899999999',
      photoUrl: 'https://example.com/photo.jpg',
      status: BusStudentStatus.onBus,
      behavioralNote: 'طالب ممتاز',
    );

    test('fromJson parses full JSON with all attributes', () {
      final json = {
        'id': 'trip_100',
        'busNumber': 'BUS-05',
        'driverName': 'ناصر',
        'driverPhone': '96891234567',
        'driverPhoto': 'https://example.com/driver.png',
        'assistantName': 'فاطمة',
        'students': [sampleStudent.toJson()],
        'startTime': now.toIso8601String(),
        'endTime': end.toIso8601String(),
        'isCompleted': true,
        'suggested_direction': 'to_school',
        'trip_type': 'morning',
        'trip_status': 'completed',
        'schoolLatitude': '23.6100',
        'schoolLongitude': '58.4500',
      };

      final model = BusTripModel.fromJson(json);

      expect(model.id, 'trip_100');
      expect(model.busNumber, 'BUS-05');
      expect(model.driverName, 'ناصر');
      expect(model.driverPhone, '96891234567');
      expect(model.driverPhoto, 'https://example.com/driver.png');
      expect(model.assistantName, 'فاطمة');
      expect(model.students.length, 1);
      expect(model.students.first.name, 'سالم أحمد');
      expect(model.startTime, now);
      expect(model.endTime, end);
      expect(model.isCompleted, isTrue);
      expect(model.suggestedDirection, 'to_school');
      expect(model.suggestedTripType, 'morning');
      expect(model.tripStatus, 'completed');
      expect(model.schoolLatitude, 23.6100);
      expect(model.schoolLongitude, 58.4500);
    });

    test('fromJson handles fallbacks (school_lat, school_lng, null endTime, null students)', () {
      final json = {
        'id': 'trip_101',
        'busNumber': 'BUS-06',
        'driverName': 'سعيد',
        'assistantName': 'مريم',
        'students': null,
        'startTime': now.toIso8601String(),
        'endTime': null,
        'school_lat': 23.5900,
        'school_lng': 58.4200,
      };

      final model = BusTripModel.fromJson(json);

      expect(model.id, 'trip_101');
      expect(model.driverPhone, '-');
      expect(model.driverPhoto, isNull);
      expect(model.students, isEmpty);
      expect(model.endTime, isNull);
      expect(model.isCompleted, isFalse);
      expect(model.schoolLatitude, 23.5900);
      expect(model.schoolLongitude, 58.4200);
    });

    test('toJson serializes BusStudentModel correctly', () {
      final model = BusTripModel(
        id: 'trip_102',
        busNumber: 'BUS-07',
        driverName: 'خالد',
        driverPhone: '96890001111',
        driverPhoto: 'https://example.com/khaled.jpg',
        assistantName: 'عائشة',
        students: [sampleStudent],
        startTime: now,
        endTime: end,
        isCompleted: true,
        schoolLatitude: 23.58,
        schoolLongitude: 58.40,
      );

      final json = model.toJson();

      expect(json['id'], 'trip_102');
      expect(json['busNumber'], 'BUS-07');
      expect(json['driverName'], 'خالد');
      expect(json['driverPhone'], '96890001111');
      expect(json['driverPhoto'], 'https://example.com/khaled.jpg');
      expect(json['assistantName'], 'عائشة');
      expect(json['students'], isA<List>());
      expect((json['students'] as List).length, 1);
      expect(json['isCompleted'], isTrue);
      expect(json['schoolLatitude'], 23.58);
      expect(json['schoolLongitude'], 58.40);
    });

    test('toJson serializes generic BusStudentEntity correctly', () {
      const genericStudent = BusStudentEntity(
        id: 's_gen',
        studentCode: 'GEN99',
        name: 'يوسف',
        grade: 'الخامس',
        schoolId: 'SCH2',
        parentName: 'محمود',
        parentPhone: '96892223333',
        photoUrl: 'https://example.com/yousef.png',
        status: BusStudentStatus.atHome,
      );

      final model = BusTripModel(
        id: 'trip_103',
        busNumber: 'BUS-08',
        driverName: 'جمال',
        assistantName: 'منى',
        students: const [genericStudent],
        startTime: now,
      );

      final json = model.toJson();
      expect(json['id'], 'trip_103');
      expect(json['students'], isA<List>());
      final studentMap = (json['students'] as List).first as Map<String, dynamic>;
      expect(studentMap['id'], 's_gen');
      expect(studentMap['name'], 'يوسف');
    });

    test('BusTripEntity copyWith and equality props', () {
      final trip1 = BusTripEntity(
        id: 'trip_1',
        busNumber: 'BUS-01',
        driverName: 'Driver A',
        assistantName: 'Assistant A',
        students: [sampleStudent],
        startTime: now,
      );

      final trip2 = BusTripEntity(
        id: 'trip_1',
        busNumber: 'BUS-01',
        driverName: 'Driver A',
        assistantName: 'Assistant A',
        students: [sampleStudent],
        startTime: now,
      );

      expect(trip1, equals(trip2));

      final modified = trip1.copyWith(
        busNumber: 'BUS-02',
        driverPhone: '96898887777',
        driverPhoto: 'new_photo.png',
        isCompleted: true,
        endTime: end,
        suggestedDirection: 'to_home',
        suggestedTripType: 'afternoon',
        tripStatus: 'done',
        schoolLatitude: 23.50,
        schoolLongitude: 58.30,
      );

      expect(modified.busNumber, 'BUS-02');
      expect(modified.driverPhone, '96898887777');
      expect(modified.driverPhoto, 'new_photo.png');
      expect(modified.isCompleted, isTrue);
      expect(modified.endTime, end);
      expect(modified.suggestedDirection, 'to_home');
      expect(modified.suggestedTripType, 'afternoon');
      expect(modified.tripStatus, 'done');
      expect(modified.schoolLatitude, 23.50);
      expect(modified.schoolLongitude, 58.30);
    });
  });
}
