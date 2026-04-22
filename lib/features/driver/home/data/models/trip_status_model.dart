import '../../domain/entities/trip_status.dart';

class TripStatusModel extends TripStatus {
  const TripStatusModel({
    required super.id,
    super.type = 'forth',
    super.typeLabel = 'ذهاب',
    super.status = 'pending',
    required super.departureTime,
    super.arrivalTime,
    required super.totalStudents,
    super.excusedCount = 0,
    super.boardedCount = 0,
    super.droppedOffCount = 0,
    super.routeName,
    super.isStarted = false,
    super.isCompleted = false,
  });

  factory TripStatusModel.fromJson(Map<String, dynamic> json) {
    final statusVal = json['status'] as String? ?? 'pending';
    return TripStatusModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'forth',
      typeLabel: json['type_label'] ?? json['typeLabel'] as String? ?? 'ذهاب',
      status: statusVal,
      departureTime: json['departure_time'] ?? json['departureTime'] as String? ?? '',
      arrivalTime: json['arrival_time'] ?? json['arrivalTime'] as String?,
      totalStudents: json['total_students'] ?? json['totalStudents'] as int? ?? 0,
      excusedCount: json['excused_count'] ?? json['excusedCount'] as int? ?? 0,
      boardedCount: json['boarded_count'] ?? json['boardedCount'] as int? ?? 0,
      droppedOffCount: json['dropped_off_count'] ?? json['droppedOffCount'] as int? ?? 0,
      routeName: json['route']?['name'] as String?,
      isStarted: statusVal == 'in_progress' || statusVal == 'awaiting_confirmation',
      isCompleted: statusVal == 'finished',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'type_label': typeLabel,
      'status': status,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'total_students': totalStudents,
      'excused_count': excusedCount,
      'boarded_count': boardedCount,
      'dropped_off_count': droppedOffCount,
      'route': routeName != null ? {'name': routeName} : null,
      'isStarted': isStarted,
      'isCompleted': isCompleted,
    };
  }
}
