import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/usecases/get_students_usecase.dart';
import '../../domain/usecases/mark_attendance_usecase.dart';
import 'class_details_state.dart';

class ClassDetailsCubit extends Cubit<ClassDetailsState> {
  final GetStudentsUseCase getStudentsUseCase;
  final MarkAttendanceUseCase markAttendanceUseCase;

  ClassDetailsCubit({
    required this.getStudentsUseCase,
    required this.markAttendanceUseCase,
  }) : super(ClassDetailsInitial());

  Future<void> loadStudents(String classId) async {
    emit(ClassDetailsLoading());
    final result = await getStudentsUseCase(classId);
    result.fold(
      (l) => emit(ClassDetailsError(l)),
      (r) => emit(ClassDetailsLoaded(r, classId)),
    );
  }

  Future<void> markAttendance(
    String studentId,
    AttendanceStatus status,
    String classId,
  ) async {
    final result = await markAttendanceUseCase(studentId, status);
    result.fold((l) => emit(ClassDetailsError(l)), (r) {
      if (state is ClassDetailsLoaded) {
        final currentState = state as ClassDetailsLoaded;
        final updatedStudents = currentState.students.map((student) {
          if (student.id == studentId) {
            return student.copyWith(status: status);
          }
          return student;
        }).toList();
        emit(ClassDetailsLoaded(updatedStudents, classId));
      } else {
        // Fallback if state is not loaded for some reason
        loadStudents(classId);
      }
    });
  }
}
