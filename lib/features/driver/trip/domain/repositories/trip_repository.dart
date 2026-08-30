abstract class TripRepository {
  Future<void> endTrip({
    required String videoPath,
    required String startQrData,
    required String endQrData,
    void Function(int sent, int total)? onProgress,
  });
  Future<void> checkTripReadiness();
  Future<void> updateStudentStatus(
    String studentId, {
    bool? isAbsent,
    bool? isBoarded,
    bool? isDroppedOff,
  });
}
