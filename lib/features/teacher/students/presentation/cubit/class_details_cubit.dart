import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/usecases/get_students_usecase.dart';
import '../../domain/usecases/confirm_attendance_usecase.dart';
import '../../domain/usecases/mark_attendance_usecase.dart';
import 'class_details_state.dart';

@injectable
class ClassDetailsCubit extends Cubit<ClassDetailsState> {
  final GetStudentsUseCase getStudentsUseCase;
  final MarkAttendanceUseCase markAttendanceUseCase;
  final ConfirmAttendanceUseCase confirmAttendanceUseCase;

  ClassDetailsCubit({
    required this.getStudentsUseCase,
    required this.markAttendanceUseCase,
    required this.confirmAttendanceUseCase,
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
    if (state is! ClassDetailsLoaded) return;
    
    final currentState = state as ClassDetailsLoaded;
    final currentStudent = currentState.students.firstWhere((s) => s.id == studentId);

    // Rule: Cannot change status of locked students if they were already marked (present/absent)
    if (currentStudent.isLocked && currentStudent.status != AttendanceStatus.unknown) {
      return;
    }

    // تحديث واجهة المستخدم فوراً (Optimistic Update)
    final previousStudents = List<StudentEntity>.from(currentState.students);
    final updatedStudents = currentState.students.map((student) {
      if (student.id == studentId) {
        return student.copyWith(status: status);
      }
      return student;
    }).toList();
    
    emit(ClassDetailsLoaded(updatedStudents, classId));

    final result = await markAttendanceUseCase(studentId, status);
    
    result.fold((l) {
      // Return to previous state on failure
      if (state is ClassDetailsLoaded) {
        emit(ClassDetailsLoaded(previousStudents, classId));
      }
    }, (r) {
      // Success: Keep the optimistic state
    });
  }

  Future<bool> submitDailyReport() async {
    if (state is! ClassDetailsLoaded) return false;
    
    final currentState = state as ClassDetailsLoaded;
    
    final result = await confirmAttendanceUseCase(currentState.classId);
    
    return result.fold(
      (failure) {
        return false;
      },
      (success) {
        // Lock all students that have been marked
        final lockedStudents = currentState.students.map((student) {
          if (student.status != AttendanceStatus.unknown) {
            return student.copyWith(isLocked: true);
          }
          return student;
        }).toList();
        
        emit(ClassDetailsLoaded(lockedStudents, currentState.classId));
        return true;
      },
    );
  }
}
