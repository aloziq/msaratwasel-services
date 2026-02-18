import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../entities/driver_entities.dart';

abstract class DriverRepository {
  Future<TripStatus> getCurrentTripStatus();
  Future<List<StudentStop>> getTripStops();
  Future<List<LatLng>> getRoutePoints();
  Future<void> startTrip(String tripId);
  Future<void> updateStudentStatus(
    String studentId, {
    bool? isAbsent,
    bool? isBoarded,
    bool? isDroppedOff,
  });
  Future<void> endTrip(String tripId);
  Future<void> submitFuelRefill({
    required double amount,
    required int odometer,
    required DateTime date,
    String? photoPath,
  });
  Future<void> submitMaintenanceRequest({
    required String description,
    required DateTime date,
    double? cost,
    String? photoPath,
  });
}
