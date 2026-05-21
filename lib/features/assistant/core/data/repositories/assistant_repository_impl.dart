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
        final driverData = data['driver'] as Map<String, dynamic>?;
        
        return Right(
          BusTripModel(
            id: busData['trip_id']?.toString() ?? 'trip-$busId',
            busNumber: busData['bus_number']?.toString() ?? '-',
            driverName: driverData?['name']?.toString() ?? '-',
            driverPhone: driverData?['phone']?.toString() ?? '-',
            driverPhoto: driverData?['photo']?.toString(),
            assistantName: '-',
            students: passengers,
            startTime: DateTime.now(), 
            suggestedDirection: busData['suggested_direction']?.toString(),
            suggestedTripType: (busData['trip_type']?.toString() == 'afternoon' || busData['trip_type']?.toString() == 'back') ? 'to_home' : 'to_school',
            tripStatus: busData['trip_status']?.toString(),
          ),
        );
      }
      return const Left('فشل في جلب بيانات الرحلة');
    } catch (e) {
      return Left('خطأ في الاتصال: $e');
    }
  }

  @override
  Future<Either<String, void>> confirmTrip(String tripId) async {
    try {
      final busId = _busId;
      if (busId == null) {
        return const Left('لم يتم العثور على حافلة معينة لحسابك.');
      }

      final response = await ApiClient.instance.post(
        '/bus/$busId/confirm-trip',
        data: {'trip_id': tripId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(null);
      }
      return Left(response.data['message'] ?? 'فشل تأكيد الرحلة');
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
        endpoint = '/bus/$busId/mark-boarded';
        // Use provided direction or ask backend? Defaulting to morning if null.
        finalDirection = direction ?? 'to_school'; 
      } else if (status == BusStudentStatus.atSchool || status == BusStudentStatus.atHome) {
        endpoint = '/bus/$busId/mark-dropped';
        finalDirection = direction ?? (status == BusStudentStatus.atSchool ? 'to_school' : 'to_home');
      } else if (status == BusStudentStatus.absent) {
        endpoint = '/bus/$busId/mark-absent';
        finalDirection = direction ?? 'to_school';
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
  Future<Either<String, void>> groupBoard({
    required List<String> studentIds,
    required String direction,
  }) async {
    try {
      final busId = _busId;
      if (busId == null) return const Left('خطأ: لا توجد حافلة');

      final response = await ApiClient.instance.post(
        '/bus/$busId/group-board',
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
    try {
      final response = await ApiClient.instance.post(
        '/field/incidents',
        data: {
          'student_id': studentId,
          'type': type,
          'description': description,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(null);
      }
      return Left(response.data['message'] ?? 'فشل تقديم البلاغ');
    } catch (e) {
      return Left('خطأ في الاتصال: $e');
    }
  }

  @override
  Future<Either<String, void>> submitDailyChecklist(
    Map<String, bool> items,
  ) async {
    try {
      final busId = _busId;
      if (busId == null) return const Left('خطأ: لا توجد حافلة');

      final response = await ApiClient.instance.post(
        '/field/inspections',
        data: {
          'bus_id': busId,
          'checklist': items,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(null);
      }
      return Left(response.data['message'] ?? 'فشل تقديم الفحص');
    } catch (e) {
      return Left('خطأ في الاتصال: $e');
    }
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
