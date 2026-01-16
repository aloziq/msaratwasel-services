import 'package:equatable/equatable.dart';

enum BusState { atStation, enRoute, arrived }

class BusPosition extends Equatable {
  final String busId;
  final double lat;
  final double lng;
  final double speedKmh;
  final double distanceKm;
  final int etaMinutes;
  final BusState state;
  final DateTime updatedAt;

  const BusPosition({
    required this.busId,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.distanceKm,
    required this.etaMinutes,
    required this.state,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    busId,
    lat,
    lng,
    speedKmh,
    distanceKm,
    etaMinutes,
    state,
    updatedAt,
  ];
}
