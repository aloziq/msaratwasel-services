import '../../domain/entities/bus_position.dart';

class BusPositionModel extends BusPosition {
  const BusPositionModel({
    required super.busId,
    required super.lat,
    required super.lng,
    required super.speedKmh,
    required super.distanceKm,
    required super.etaMinutes,
    required super.studentsOnBoard,
    required super.state,
    required super.updatedAt,
  });

  factory BusPositionModel.fromJson(Map<String, dynamic> json) {
    return BusPositionModel(
      busId: json['busId'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speedKmh: (json['speedKmh'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      etaMinutes: json['etaMinutes'] as int,
      studentsOnBoard: json['studentsOnBoard'] as int,
      state: BusState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => BusState.atStation,
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'lat': lat,
      'lng': lng,
      'speedKmh': speedKmh,
      'distanceKm': distanceKm,
      'etaMinutes': etaMinutes,
      'studentsOnBoard': studentsOnBoard,
      'state': state.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
