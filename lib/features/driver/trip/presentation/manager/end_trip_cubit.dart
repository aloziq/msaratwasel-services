import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/trip_repository.dart';

// States
abstract class EndTripState extends Equatable {
  const EndTripState();
  @override
  List<Object?> get props => [];
}

class EndTripInitial extends EndTripState {} 
class EndTripScanningFront extends EndTripState {}
class EndTripRecording extends EndTripState {}
class EndTripScanningBack extends EndTripState {}
class EndTripCompressing extends EndTripState {}
class EndTripUploading extends EndTripState {
  final double progress;
  const EndTripUploading(this.progress);
  @override
  List<Object?> get props => [progress];
}
class EndTripSuccess extends EndTripState {}
class EndTripError extends EndTripState {
  final String message;
  const EndTripError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
@injectable
class EndTripCubit extends Cubit<EndTripState> {
  final TripRepository _repository;
  String? _frontData;
  String? _backData;
  String? _videoPath;

  EndTripCubit(this._repository) : super(EndTripInitial());

  void restart() => emit(EndTripInitial());

  void scanFrontQr(String code) {
    _frontData = code;
    emit(EndTripRecording());
  }

  void prepareScanBack(String videoPath) {
    _videoPath = videoPath;
    emit(EndTripScanningBack());
  }

  void scanBackQr(String code) {
    _backData = code;
    submitTripEnd();
  }

  Future<void> submitTripEnd() async {
    if (_frontData == null || _backData == null || _videoPath == null) {
      emit(const EndTripError('بيانات التحقق غير مكتملة'));
      return;
    }

    emit(EndTripCompressing());
    
    // Compression logic will be triggered from UI or a service
    // For now, we move to compressing state
  }

  void startCompressing() {
    emit(EndTripCompressing());
  }

  void updateUploadProgress(double progress) {
    emit(EndTripUploading(progress));
  }

  Future<void> finalizeUpload(String compressedPath) async {
    try {
      await _repository.endTrip(
        videoPath: compressedPath,
        startQrData: _frontData!,
        endQrData: _backData!,
        onProgress: (sent, total) {
          updateUploadProgress(sent / total);
        },
      );
      emit(EndTripSuccess());
    } catch (e) {
      emit(EndTripError(e.toString()));
    }
  }
}
