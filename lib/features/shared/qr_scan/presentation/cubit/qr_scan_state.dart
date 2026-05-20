import 'package:equatable/equatable.dart';

abstract class QRScanState extends Equatable {
  const QRScanState();

  @override
  List<Object?> get props => [];
}

class QRScanInitial extends QRScanState {}

class QRScanLoading extends QRScanState {}

class QRScanSuccess extends QRScanState {
  final String code;

  const QRScanSuccess(this.code);

  @override
  List<Object?> get props => [code];
}

class QRScanError extends QRScanState {
  final String message;

  const QRScanError(this.message);

  @override
  List<Object?> get props => [message];
}

class QRScanAttendanceSuccess extends QRScanState {
  final String studentId;

  const QRScanAttendanceSuccess(this.studentId);

  @override
  List<Object?> get props => [studentId, DateTime.now().millisecondsSinceEpoch]; // Force update even for same ID
}

class QRScanTripSuccess extends QRScanState {
  final String studentName;
  final String newStatus;
  final String message;

  const QRScanTripSuccess({required this.studentName, required this.newStatus, required this.message});

  @override
  List<Object?> get props => [studentName, newStatus, message, DateTime.now().millisecondsSinceEpoch];
}

class QRScanTripError extends QRScanState {
  final String message;

  const QRScanTripError(this.message);

  @override
  List<Object?> get props => [message, DateTime.now().millisecondsSinceEpoch];
}
