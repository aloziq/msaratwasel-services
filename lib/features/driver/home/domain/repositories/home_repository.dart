import '../entities/trip_status.dart';

abstract class HomeRepository {
  Future<TripStatus> getCurrentTripStatus();
  Future<void> startTrip(String tripId);
}
