import 'package:equatable/equatable.dart';
import '../../domain/entities/report_entity.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final AttendanceStatsEntity stats;

  const ReportsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}
