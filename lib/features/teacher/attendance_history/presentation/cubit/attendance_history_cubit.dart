import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_attendance_history_usecase.dart';
import 'attendance_history_state.dart';

class AttendanceHistoryCubit extends Cubit<AttendanceHistoryState> {
  final GetAttendanceHistoryUseCase getAttendanceHistoryUseCase;

  AttendanceHistoryCubit({required this.getAttendanceHistoryUseCase})
    : super(AttendanceHistoryInitial());

  Future<void> loadHistory() async {
    emit(AttendanceHistoryLoading());
    final result = await getAttendanceHistoryUseCase();
    result.fold(
      (l) => emit(AttendanceHistoryError(l)),
      (r) => emit(AttendanceHistoryLoaded(r)),
    );
  }
}
