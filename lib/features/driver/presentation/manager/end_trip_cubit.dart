import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/driver_repository.dart';

// States
abstract class EndTripState extends Equatable {
  const EndTripState();
  @override
  List<Object?> get props => [];
}

class EndTripInitial extends EndTripState {} // Step 0: Waiting for first scan

class EndTripScanningFront extends EndTripState {}

class EndTripRecording extends EndTripState {}

class EndTripScanningBack extends EndTripState {}

class EndTripSubmitting extends EndTripState {}

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
  final DriverRepository _repository;

  EndTripCubit(this._repository) : super(EndTripInitial());

  // Step 1: Scan Front QR
  void scanFrontQr(String code) {
    // Validate code...
    emit(EndTripRecording());
  }

  // Step 2: Record Video
  void recordVideo(String videoPath) {
    // Save video path temporarily...
    emit(EndTripScanningBack());
  }

  // Step 3: Scan Back QR
  void scanBackQr(String code) {
    // Validate code...
    submitTripEnd();
  }

  Future<void> submitTripEnd() async {
    emit(EndTripSubmitting());
    try {
      await _repository.endTrip('current_trip_id');
      emit(EndTripSuccess());
    } catch (e) {
      emit(EndTripError(e.toString()));
      // Reset to last valid state or handle retry
    }
  }
}
