import '../../domain/entities/fleet_bus.dart';

class FleetBusModel extends FleetBus {
  const FleetBusModel({
    required super.id,
    required super.name,
    required super.driverName,
    required super.supervisorName,
    required super.schoolName,
    required super.driverPhone,
    required super.route,
    required super.lat,
    required super.lng,
    required super.speedKmh,
    required super.studentsOnBoard,
    required super.status,
    required super.updatedAt,
  });

  factory FleetBusModel.fromJson(Map<String, dynamic> json) {
    return FleetBusModel(
      id: json['id'] as String,
      name: json['name'] as String,
      driverName: json['driverName'] as String,
      supervisorName: json['supervisorName'] as String,
      schoolName: json['schoolName'] as String,
      driverPhone: json['driverPhone'] as String,
      route: json['route'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speedKmh: (json['speedKmh'] as num).toDouble(),
      studentsOnBoard: json['studentsOnBoard'] as int,
      status: FleetBusStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FleetBusStatus.active,
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'driverName': driverName,
      'supervisorName': supervisorName,
      'schoolName': schoolName,
      'driverPhone': driverPhone,
      'route': route,
      'lat': lat,
      'lng': lng,
      'speedKmh': speedKmh,
      'studentsOnBoard': studentsOnBoard,
      'status': status.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
