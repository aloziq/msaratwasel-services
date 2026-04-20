import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/repositories/trip_repository.dart';

@LazySingleton(as: TripRepository)
class TripRepositoryImpl implements TripRepository {
  String? get _busId {
    try {
      return GetIt.instance<SharedPreferences>().getString('USER_BUS_ID');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> endTrip({
    required String videoPath,
    required String startQrData,
    required String endQrData,
    void Function(int sent, int total)? onProgress,
  }) async {
    final busId = _busId;
    if (busId == null) throw Exception('No bus assigned');

    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(videoPath, filename: 'verify.mp4'),
      'start_qr_scanned': true,
      'end_qr_scanned': true,
      'start_qr_data': startQrData,
      'end_qr_data': endQrData,
    });

    final response = await ApiClient.instance.post(
      '/bus/$busId/end-trip',
      data: formData,
      onSendProgress: onProgress,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.data['message'] ?? 'Failed to end trip');
    }
  }

  @override
  Future<void> updateStudentStatus(
    String studentId, {
    bool? isAbsent,
    bool? isBoarded,
    bool? isDroppedOff,
  }) async {
    final busId = _busId;
    if (busId == null) throw Exception('No bus assigned');

    // This is used by the driver to update specific student status if needed
    // In our unified flow, we have board/alight endpoints
    String endpoint = '/bus/$busId/board';
    String direction = 'to_school'; // Default, should be dynamic if needed

    if (isDroppedOff == true) {
      endpoint = '/bus/$busId/alight';
    }

    final response = await ApiClient.instance.post(
      endpoint,
      data: {
        'student_id': studentId,
        'direction': direction,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.data['message'] ?? 'Failed to update student status');
    }
  }
}
