import 'package:dartz/dartz.dart';
import '../entities/bus_student_entity.dart';
import '../entities/bus_trip_entity.dart';

abstract class AssistantRepository {
  Future<Either<String, BusTripEntity>> getActiveTrip();

  Future<Either<String, void>> confirmTrip(String tripId);

  Future<Either<String, List<BusStudentEntity>>> getStudents();

  Future<Either<String, void>> updateStudentStatus(
    String studentId,
    BusStudentStatus status,
    String? direction,
  );

  Future<Either<String, void>> groupAlight({
    required List<String> studentIds,
    required String direction,
  });

  Future<Either<String, void>> groupBoard({
    required List<String> studentIds,
    required String direction,
  });

  Future<Either<String, void>> submitIncidentReport({
    required String studentId,
    required String type,
    required String description,
  });

  Future<Either<String, void>> submitDailyChecklist(Map<String, bool> items);

  Future<Either<String, void>> confirmEmptyBus();

  Future<Either<String, void>> sendAlertToDriver(String message);

  Future<Either<String, void>> updateBehavioralNote(
    String studentId,
    String note,
  );
}
