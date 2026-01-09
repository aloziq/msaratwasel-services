import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_history_entity.dart';

abstract class AttendanceHistoryState extends Equatable {
  const AttendanceHistoryState();

  @override
  List<Object?> get props => [];
}

class AttendanceHistoryInitial extends AttendanceHistoryState {}

class AttendanceHistoryLoading extends AttendanceHistoryState {}

class AttendanceHistoryLoaded extends AttendanceHistoryState {
  final List<AttendanceHistoryEntity> history;

  const AttendanceHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class AttendanceHistoryError extends AttendanceHistoryState {
  final String message;

  const AttendanceHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
