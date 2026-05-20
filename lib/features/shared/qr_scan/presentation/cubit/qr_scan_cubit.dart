import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/usecases/mark_attendance_usecase.dart';
import 'qr_scan_state.dart';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/di/injection.dart';

@injectable
class QRScanCubit extends Cubit<QRScanState> {
  final MarkAttendanceUseCase _markAttendanceUseCase;

  QRScanCubit(this._markAttendanceUseCase) : super(QRScanInitial());

  void onCodeScanned(String code) {
    emit(QRScanSuccess(code));
  }

  Future<void> markAttendanceViaQr(String studentId, String classId) async {
    emit(QRScanLoading());
    final result = await _markAttendanceUseCase(
      studentId,
      AttendanceStatus.present,
    );
    result.fold(
      (l) => emit(QRScanError(l)),
      (r) => emit(QRScanAttendanceSuccess(studentId)),
    );
  }

  Future<void> markSmartTripAttendanceViaQr(String code) async {
    emit(QRScanLoading());
    try {
      final busId = getIt<SharedPreferences>().getString('USER_BUS_ID') ?? '';
      if (busId.isEmpty) {
        emit(const QRScanTripError('لا يوجد باص مخصص لك حالياً'));
        return;
      }

      final response = await ApiClient.instance.post('/bus/$busId/scan-qr', data: {
        'code': code,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        emit(QRScanTripSuccess(
          studentName: data['student_name'] ?? 'طالب مسجل',
          newStatus: data['new_status'] ?? data['current_status'] ?? 'غير معروف',
          message: data['message'] ?? 'تم العملية بنجاح',
        ));
      } else {
        emit(QRScanTripError(response.data['message'] ?? 'حدث خطأ أثناء الاتصال بالخادم'));
      }
    } catch (e) {
      if (e is DioException && e.response != null && e.response!.data != null) {
        emit(QRScanTripError(e.response!.data['message'] ?? 'حدث خطأ أثناء قراءة الكود'));
      } else {
        emit(QRScanTripError('تأكد من اتصالك بالإنترنت'));
      }
    }
  }

  void reset() {
    emit(QRScanInitial());
  }

  void emitError(String message) {
    emit(QRScanError(message));
  }
}
