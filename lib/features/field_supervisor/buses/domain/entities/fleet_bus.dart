import 'package:equatable/equatable.dart';

enum FleetBusStatus { active, stopped, maintenance }

class FleetBus extends Equatable {
  final String id;
  final String name;
  final String driverName;
  final String supervisorName; // Assistant
  final String? fieldSupervisorName;
  final String? frontQrUrl;
  final String? backQrUrl;
  final String schoolName;
  final String driverPhone;
  final String route;
  final double lat;
  final double lng;
  final double speedKmh;
  final int studentsOnBoard;
  final FleetBusStatus status;
  final DateTime updatedAt;

  const FleetBus({
    required this.id,
    required this.name,
    required this.driverName,
    required this.supervisorName,
    this.fieldSupervisorName,
    this.frontQrUrl,
    this.backQrUrl,
    required this.schoolName,
    required this.driverPhone,
    required this.route,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.studentsOnBoard,
    required this.status,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    driverName,
    supervisorName,
    fieldSupervisorName,
    frontQrUrl,
    backQrUrl,
    schoolName,
    driverPhone,
    route,
    lat,
    lng,
    speedKmh,
    studentsOnBoard,
    status,
    updatedAt,
  ];
}
