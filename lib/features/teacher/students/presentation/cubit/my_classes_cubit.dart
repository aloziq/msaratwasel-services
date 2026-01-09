import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart';
import 'my_classes_state.dart';

class MyClassesCubit extends Cubit<MyClassesState> {
  final GetTeacherClassroomsUseCase getTeacherClassroomsUseCase;

  MyClassesCubit({required this.getTeacherClassroomsUseCase})
    : super(MyClassesInitial());

  Future<void> loadClasses() async {
    emit(MyClassesLoading());
    final result = await getTeacherClassroomsUseCase();
    result.fold(
      (l) => emit(MyClassesError(l)),
      (r) => emit(MyClassesLoaded(r)),
    );
  }
}
