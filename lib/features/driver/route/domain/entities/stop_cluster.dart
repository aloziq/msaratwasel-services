import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'student_stop.dart';

class StopCluster {
  final LatLng location;
  final List<StudentStop> students;

  StopCluster({
    required this.location,
    required this.students,
  });

  bool get isAllAbsent => students.every((s) => s.isAbsent);
}
