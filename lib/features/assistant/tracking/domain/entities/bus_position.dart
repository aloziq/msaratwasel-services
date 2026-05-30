import 'package:equatable/equatable.dart';

enum BusState { atStation, enRoute, arrived }

class BusPosition extends Equatable {
  final String busId;
  final double lat;
  final double lng;
  final double? targetLat;
  final double? targetLng;
  final double speedKmh;
  final double distanceKm;
  final int etaMinutes;
  final int studentsOnBoard;
  final BusState state;
  final DateTime updatedAt;

  const BusPosition({
    required this.busId,
    required this.lat,
    required this.lng,
    this.targetLat,
    this.targetLng,
    required this.speedKmh,
    required this.distanceKm,
    required this.etaMinutes,
    required this.studentsOnBoard,
    required this.state,
    required this.updatedAt,
  });

  BusPosition copyWith({
    String? busId,
    double? lat,
    double? lng,
    double? targetLat,
    double? targetLng,
    double? speedKmh,
    double? distanceKm,
    int? etaMinutes,
    int? studentsOnBoard,
    BusState? state,
    DateTime? updatedAt,
  }) {
    return BusPosition(
      busId: busId ?? this.busId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      targetLat: targetLat ?? this.targetLat,
      targetLng: targetLng ?? this.targetLng,
      speedKmh: speedKmh ?? this.speedKmh,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      studentsOnBoard: studentsOnBoard ?? this.studentsOnBoard,
      state: state ?? this.state,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    busId,
    lat,
    lng,
    targetLat,
    targetLng,
    speedKmh,
    distanceKm,
    etaMinutes,
    studentsOnBoard,
    state,
    updatedAt,
  ];
}
