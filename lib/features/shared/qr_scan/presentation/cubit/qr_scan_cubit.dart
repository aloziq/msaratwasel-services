import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/usecases/mark_attendance_usecase.dart';
import 'qr_scan_state.dart';

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

  void reset() {
    emit(QRScanInitial());
  }

  void emitError(String message) {
    emit(QRScanError(message));
  }
}
