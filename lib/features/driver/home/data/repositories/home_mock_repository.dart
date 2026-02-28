import 'package:injectable/injectable.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/entities/trip_status.dart';
import '../models/trip_status_model.dart';

@LazySingleton(as: HomeRepository)
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
