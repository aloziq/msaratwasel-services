import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/bus_student_entity.dart';
import '../../domain/entities/bus_trip_entity.dart';
import '../models/bus_student_model.dart';
import '../models/bus_trip_model.dart';
import '../../domain/repositories/assistant_repository.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  String? get _busId {
    try {
      return GetIt.instance<SharedPreferences>().getString('USER_BUS_ID');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<String, BusTripEntity>> getActiveTrip() async {
    try {
      final busId = _busId;
      if (busId == null) {
        return const Left('لم يتم العثور على حافلة معينة لحسابك.');
      }

      final response = await ApiClient.instance.get('/bus/$busId/passengers');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final passengers = (data['passengers'] as List)
            .map((e) => BusStudentModel.fromJson(e))
            .toList();
            
        final busData = data['bus'];
        
        return Right(
          BusTripModel(
            id: 'trip-$busId',
            busNumber: busData['bus_number'] ?? '-',
            driverName: '-', // Needs to come from user profile if needed
            assistantName: '-', // Needs to come from user profile
            students: passengers,
            startTime: DateTime.now(), 
            suggestedDirection: busData['suggested_direction'] as String?,
            suggestedTripType: busData['suggested_trip_type'] as String?,
            tripStatus: busData['trip_status'] as String?,
          ),
        );
      }
      return const Left('فشل في جلب بيانات الرحلة');
    } catch (e) {
      return Left('خطأ في الاتصال: $e');
    }
  }

  @override
  Future<Either<String, List<BusStudentEntity>>> getStudents() async {
    final tripResult = await getActiveTrip();
    return tripResult.fold(
      (failure) => Left(failure),
      (trip) => Right(trip.students),
    );
  }

  @override
  Future<Either<String, void>> updateStudentStatus(
    String studentId,
    BusStudentStatus status,
    String? direction,
  ) async {
    try {
      final busId = _busId;
      if (busId == null) {
        return const Left('خطأ: لا توجد حافلة مسجلة');
      }

      String endpoint;
      String finalDirection;

      if (status == BusStudentStatus.onBus) {
        endpoint = '/bus/$busId/board';
        // Use provided direction or ask backend? Defaulting to morning if null.
        finalDirection = direction ?? 'to_school'; 
      } else if (status == BusStudentStatus.atSchool || status == BusStudentStatus.atHome) {
        endpoint = '/bus/$busId/alight';
        finalDirection = direction ?? (status == BusStudentStatus.atSchool ? 'to_school' : 'to_home');
      } else {
        return const Right(null); 
      }

      final response = await ApiClient.instance.post(
        endpoint,
        data: {
          'student_id': studentId,
          'direction': finalDirection,
          'latitude': null,
          'longitude': null,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(null);
      }
      return Left(response.data['message'] ?? 'حدث خطأ غير متوقع');
    } catch (e) {
      return Left('تعذر تحديث الحالة: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> groupAlight({
    required List<String> studentIds,
    required String direction,
  }) async {
    try {
      final busId = _busId;
      if (busId == null) return const Left('خطأ: لا توجد حافلة');

      final response = await ApiClient.instance.post(
        '/bus/$busId/group-alight',
        data: {
          'student_ids': studentIds,
          'direction': direction,
          'latitude': null,
          'longitude': null,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(null);
      }
      return Left(response.data['message'] ?? 'فشل التحديث الجماعي');
    } catch (e) {
      return Left('خطأ في التحديث الجماعي: $e');
    }
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
