import '../entities/trip_status.dart';

abstract class HomeRepository {
  Future<TripStatus> getCurrentTripStatus();
  Future<List<TripStatus>> getMyTrips();
  Future<void> startTrip(String tripId);
}
