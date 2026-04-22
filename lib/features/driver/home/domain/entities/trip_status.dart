class TripStatus {
  final String id;
  final String type;
  final String typeLabel;
  final String status;
  final String departureTime;
  final String? arrivalTime;
  final int totalStudents;
  final int excusedCount;
  final int boardedCount;
  final int droppedOffCount;
  final String? routeName;
  final bool isStarted;
  final bool isCompleted;

  const TripStatus({
    required this.id,
    this.type = 'forth',
    this.typeLabel = 'ذهاب',
    this.status = 'pending',
    required this.departureTime,
    this.arrivalTime,
    required this.totalStudents,
    this.excusedCount = 0,
    this.boardedCount = 0,
    this.droppedOffCount = 0,
    this.routeName,
    this.isStarted = false,
    this.isCompleted = false,
  });
}
