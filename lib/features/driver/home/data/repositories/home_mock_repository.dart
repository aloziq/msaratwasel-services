import 'package:injectable/injectable.dart';
import 'package:msaratwasel_services/features/driver/home/domain/repositories/home_repository.dart';
import 'package:msaratwasel_services/features/driver/home/domain/entities/trip_status.dart';
import 'package:msaratwasel_services/features/driver/home/data/models/trip_status_model.dart';

//@LazySingleton(as: HomeRepository)
class HomeMockRepository implements HomeRepository {
  @override
  Future<TripStatus> getCurrentTripStatus() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    return const TripStatusModel(
      id: 'trip_123',
      departureTime: '06:30 AM',
      totalStudents: 22,
      isStarted: false,
    );
  }

  @override
  Future<void> startTrip(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, we'd update backend state
  }
}
