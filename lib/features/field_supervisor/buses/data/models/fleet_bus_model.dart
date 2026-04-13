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
      id: json['id']?.toString() ?? '',
      name: json['bus_code'] ?? json['name'] ?? '',
      driverName: json['driver'] ?? json['driverName'] ?? 'N/A',
      supervisorName: json['supervisor'] ?? json['supervisorName'] ?? 'N/A',
      schoolName: json['school'] ?? json['schoolName'] ?? 'N/A',
      driverPhone: json['driverPhone'] ?? '',
      route: json['route'] ?? '',
      lat: (json['location_lat'] ?? json['lat'] ?? 0 as num).toDouble(),
      lng: (json['location_lng'] ?? json['lng'] ?? 0 as num).toDouble(),
      speedKmh: (json['speed_kmh'] ?? json['speedKmh'] ?? 0 as num).toDouble(),
      studentsOnBoard: json['studentsOnBoard'] ?? 0,
      status: FleetBusStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'stopped'),
        orElse: () => FleetBusStatus.active,
      ),
      updatedAt: json['last_update'] != null
          ? DateTime.tryParse(json['last_update']) ?? DateTime.now()
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
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
