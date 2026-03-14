import '../../domain/entities/bus_trip_entity.dart';

import 'bus_student_model.dart';

class BusTripModel extends BusTripEntity {
  const BusTripModel({
    required super.id,
    required super.busNumber,
    required super.driverName,
    required super.assistantName,
    required super.students,
    required super.startTime,
    super.endTime,
    super.isCompleted = false,
    super.suggestedDirection,
    super.suggestedTripType,
    super.tripStatus,
  });

  factory BusTripModel.fromJson(Map<String, dynamic> json) {
    return BusTripModel(
      id: json['id'] as String,
      busNumber: json['busNumber'] as String,
      driverName: json['driverName'] as String,
      assistantName: json['assistantName'] as String,
      students:
          (json['students'] as List<dynamic>?)
              ?.map((e) => BusStudentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      suggestedDirection: json['suggested_direction'] as String?,
      suggestedTripType: json['suggested_trip_type'] as String?,
      tripStatus: json['trip_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busNumber': busNumber,
      'driverName': driverName,
      'assistantName': assistantName,
      'students': students.map((e) {
        if (e is BusStudentModel) return e.toJson();
        return BusStudentModel(
          id: e.id,
          studentCode: e.studentCode,
          name: e.name,
          grade: e.grade,
          schoolId: e.schoolId,
          parentName: e.parentName,
          parentPhone: e.parentPhone,
          photoUrl: e.photoUrl,
          status: e.status,
          behavioralNote: e.behavioralNote,
        ).toJson();
      }).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
