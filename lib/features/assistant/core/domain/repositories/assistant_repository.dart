import 'package:dartz/dartz.dart';
import '../entities/bus_student_entity.dart';
import '../entities/bus_trip_entity.dart';

abstract class AssistantRepository {
  Future<Either<String, BusTripEntity>> getActiveTrip();

  Future<Either<String, List<BusStudentEntity>>> getStudents();

  Future<Either<String, void>> updateStudentStatus(
    String studentId,
    BusStudentStatus status,
  );

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
