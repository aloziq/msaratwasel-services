import 'package:flutter_bloc/flutter_bloc.dart';
import 'qr_scan_state.dart';

class QRScanCubit extends Cubit<QRScanState> {
  QRScanCubit() : super(QRScanInitial());

  void onCodeScanned(String code) {
    emit(QRScanSuccess(code));
  }

  void reset() {
    emit(QRScanInitial());
  }

  void emitError(String message) {
    emit(QRScanError(message));
  }
}
