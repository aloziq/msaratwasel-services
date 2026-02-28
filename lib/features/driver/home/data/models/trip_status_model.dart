import '../../domain/entities/trip_status.dart';

class TripStatusModel extends TripStatus {
  const TripStatusModel({
    required super.id,
    required super.departureTime,
    required super.totalStudents,
    super.boardedCount = 0,
    super.droppedOffCount = 0,
    super.isStarted = false,
    super.isCompleted = false,
  });

  factory TripStatusModel.fromJson(Map<String, dynamic> json) {
    return TripStatusModel(
      id: json['id'] as String,
      departureTime: json['departureTime'] as String,
      totalStudents: json['totalStudents'] as int,
      boardedCount: json['boardedCount'] as int? ?? 0,
      droppedOffCount: json['droppedOffCount'] as int? ?? 0,
      isStarted: json['isStarted'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departureTime': departureTime,
      'totalStudents': totalStudents,
      'boardedCount': boardedCount,
      'droppedOffCount': droppedOffCount,
      'isStarted': isStarted,
      'isCompleted': isCompleted,
    };
  }
}
