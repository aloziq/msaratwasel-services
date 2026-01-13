import 'package:equatable/equatable.dart';
import 'bus_student_entity.dart';

class BusTripEntity extends Equatable {
  final String id;
  final String busNumber;
  final String driverName;
  final String assistantName;
  final List<BusStudentEntity> students;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;

  const BusTripEntity({
    required this.id,
    required this.busNumber,
    required this.driverName,
    required this.assistantName,
    required this.students,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
  });

  BusTripEntity copyWith({
    String? id,
    String? busNumber,
    String? driverName,
    String? assistantName,
    List<BusStudentEntity>? students,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
  }) {
    return BusTripEntity(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      driverName: driverName ?? this.driverName,
      assistantName: assistantName ?? this.assistantName,
      students: students ?? this.students,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    busNumber,
    driverName,
    assistantName,
    students,
    startTime,
    endTime,
    isCompleted,
  ];
}
