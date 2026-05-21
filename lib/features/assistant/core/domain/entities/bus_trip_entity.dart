import 'package:equatable/equatable.dart';
import 'bus_student_entity.dart';

class BusTripEntity extends Equatable {
  final String id;
  final String busNumber;
  final String driverName;
  final String driverPhone;
  final String? driverPhoto;
  final String assistantName;
  final List<BusStudentEntity> students;
  final DateTime startTime;
  final DateTime? endTime;
  final String? suggestedDirection;
  final String? suggestedTripType;
  final String? tripStatus;
  final bool isCompleted;

  const BusTripEntity({
    required this.id,
    required this.busNumber,
    required this.driverName,
    this.driverPhone = '-',
    this.driverPhoto,
    required this.assistantName,
    required this.students,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.suggestedDirection,
    this.suggestedTripType,
    this.tripStatus,
  });

  BusTripEntity copyWith({
    String? id,
    String? busNumber,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    String? assistantName,
    List<BusStudentEntity>? students,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    String? suggestedDirection,
    String? suggestedTripType,
    String? tripStatus,
  }) {
    return BusTripEntity(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      assistantName: assistantName ?? this.assistantName,
      students: students ?? this.students,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      suggestedDirection: suggestedDirection ?? this.suggestedDirection,
      suggestedTripType: suggestedTripType ?? this.suggestedTripType,
      tripStatus: tripStatus ?? this.tripStatus,
    );
  }

  @override
  List<Object?> get props => [
    id,
    busNumber,
    driverName,
    driverPhone,
    driverPhoto,
    assistantName,
    students,
    startTime,
    endTime,
    isCompleted,
    suggestedDirection,
    suggestedTripType,
    tripStatus,
  ];
}
