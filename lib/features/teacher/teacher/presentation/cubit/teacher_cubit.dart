import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_teacher_classroom_usecase.dart';
import 'teacher_state.dart';

class TeacherCubit extends Cubit<TeacherState> {
  final GetTeacherClassroomUseCase getTeacherClassroomUseCase;

  TeacherCubit({required this.getTeacherClassroomUseCase})
    : super(TeacherInitial());

  Future<void> loadClassroom() async {
    emit(TeacherLoading());
    final result = await getTeacherClassroomUseCase();
    result.fold(
      (l) => emit(TeacherError(l)),
      (r) => emit(TeacherClassLoaded(r)),
    );
  }
}
