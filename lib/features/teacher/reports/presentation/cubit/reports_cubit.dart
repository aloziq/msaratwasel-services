import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_attendance_stats_usecase.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final GetAttendanceStatsUseCase getAttendanceStatsUseCase;

  ReportsCubit({required this.getAttendanceStatsUseCase})
    : super(ReportsInitial());

  Future<void> loadReports() async {
    emit(ReportsLoading());
    final result = await getAttendanceStatsUseCase();
    result.fold(
      (error) => emit(ReportsError(error)),
      (stats) => emit(ReportsLoaded(stats)),
    );
  }
}
