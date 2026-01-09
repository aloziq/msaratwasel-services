import 'package:equatable/equatable.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';

abstract class MyClassesState extends Equatable {
  const MyClassesState();

  @override
  List<Object?> get props => [];
}

class MyClassesInitial extends MyClassesState {}

class MyClassesLoading extends MyClassesState {}

class MyClassesLoaded extends MyClassesState {
  final List<ClassroomEntity> classrooms;

  const MyClassesLoaded(this.classrooms);

  @override
  List<Object?> get props => [classrooms];
}

class MyClassesError extends MyClassesState {
  final String message;

  const MyClassesError(this.message);

  @override
  List<Object?> get props => [message];
}
