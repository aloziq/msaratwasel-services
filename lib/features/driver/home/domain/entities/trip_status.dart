class TripStatus {
  final String id;
  final String departureTime;
  final int totalStudents;
  final int boardedCount;
  final int droppedOffCount;
  final bool isStarted;
  final bool isCompleted;

  const TripStatus({
    required this.id,
    required this.departureTime,
    required this.totalStudents,
    this.boardedCount = 0,
    this.droppedOffCount = 0,
    this.isStarted = false,
    this.isCompleted = false,
  });
}
