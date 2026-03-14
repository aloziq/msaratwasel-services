import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../entities/student_stop.dart';

abstract class RouteRepository {
  Future<List<StudentStop>> getTripStops();
  Future<List<LatLng>> getRoutePoints();
  Future<void> boardStudent({required String studentId, required String direction});
  Future<void> alightStudent({required String studentId, required String direction});
  Future<void> updateLocation({required double latitude, required double longitude});
}
