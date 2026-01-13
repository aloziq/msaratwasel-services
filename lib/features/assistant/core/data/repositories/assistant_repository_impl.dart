import 'package:dartz/dartz.dart';
import '../../domain/entities/bus_student_entity.dart';
import '../../domain/entities/bus_trip_entity.dart';
import '../../domain/repositories/assistant_repository.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  final List<BusStudentEntity> _mockStudents = [
    const BusStudentEntity(
      id: 's1',
      name: 'أحمد محمد',
      grade: 'الصف الثاني',
      schoolId: 'SCH-001',
      parentName: 'محمد علي',
      parentPhone: '99999999',
      status: BusStudentStatus.atHome,
      photoUrl:
          'https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=400',
    ),
    const BusStudentEntity(
      id: 's2',
      name: 'فاطمة علي',
      grade: 'الصف الثالث',
      schoolId: 'SCH-001',
      parentName: 'علي حسن',
      parentPhone: '98888888',
      status: BusStudentStatus.onBus,
      photoUrl:
          'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=400',
    ),
    const BusStudentEntity(
      id: 's3',
      name: 'يوسف سليم',
      grade: 'الصف الأول',
      schoolId: 'SCH-001',
      parentName: 'سليم خالد',
      parentPhone: '97777777',
      status: BusStudentStatus.atSchool,
      photoUrl:
          'https://images.unsplash.com/photo-1544717297-fa95b3ee51f3?w=400',
    ),
    const BusStudentEntity(
      id: 's4',
      name: 'ليان عمر',
      grade: 'الصف الرابع',
      schoolId: 'SCH-001',
      parentName: 'عمر هاني',
      parentPhone: '96666666',
      status: BusStudentStatus.atHome,
      photoUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
    ),
  ];

  @override
  Future<Either<String, BusTripEntity>> getActiveTrip() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right(
      BusTripEntity(
        id: 'trip-101',
        busNumber: 'B-45',
        driverName: 'عصام كمال',
        assistantName: 'مريم سعيد',
        students: _mockStudents,
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    );
  }

  @override
  Future<Either<String, List<BusStudentEntity>>> getStudents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right(_mockStudents);
  }

  @override
  Future<Either<String, void>> updateStudentStatus(
    String studentId,
    BusStudentStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Right(null);
  }

  @override
  Future<Either<String, void>> submitIncidentReport({
    required String studentId,
    required String type,
    required String description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const Right(null);
  }

  @override
  Future<Either<String, void>> submitDailyChecklist(
    Map<String, bool> items,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(null);
  }

  @override
  Future<Either<String, void>> confirmEmptyBus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(null);
  }

  @override
  Future<Either<String, void>> sendAlertToDriver(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Right(null);
  }

  @override
  Future<Either<String, void>> updateBehavioralNote(
    String studentId,
    String note,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Right(null);
  }
}
