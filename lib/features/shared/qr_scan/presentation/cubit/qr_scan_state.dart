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
