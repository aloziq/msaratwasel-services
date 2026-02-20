abstract class TripRepository {
  Future<void> endTrip(String tripId);
  Future<void> updateStudentStatus(
    String studentId, {
    bool? isAbsent,
    bool? isBoarded,
    bool? isDroppedOff,
  });
}
