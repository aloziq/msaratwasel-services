import 'package:injectable/injectable.dart';
import '../../domain/repositories/trip_repository.dart';

@LazySingleton(as: TripRepository)
class TripMockRepository implements TripRepository {
  @override
  Future<void> updateStudentStatus(
    String studentId, {
    bool? isAbsent,
    bool? isBoarded,
    bool? isDroppedOff,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Find stop and update locally if needed for simulation
  }

  @override
  Future<void> endTrip(String tripId) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
