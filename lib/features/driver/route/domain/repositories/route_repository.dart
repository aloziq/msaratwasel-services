import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../entities/student_stop.dart';

abstract class RouteRepository {
  String get currentTripType;
  LatLng? get schoolLocation;
  Future<List<StudentStop>> getTripStops();
  Future<List<LatLng>> getRoutePoints();
  Future<void> markStudentBoarded({required String studentId});
  Future<void> groupBoard({required List<String> studentIds});
  Future<void> markStudentDropped({required String studentId});
  Future<void> notifyParentNearHouse({required String studentId});
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    double? accuracy,
  });
  Future<void> arriveAtSchool();
  int getOnBoardCount(List<StudentStop> stops);
  int getUnprocessedCount(List<StudentStop> stops);
}
