import 'package:equatable/equatable.dart';
import '../../domain/entities/classroom_entity.dart';

abstract class TeacherState extends Equatable {
  const TeacherState();

  @override
  List<Object?> get props => [];
}

class TeacherInitial extends TeacherState {}

class TeacherLoading extends TeacherState {}

class TeacherClassLoaded extends TeacherState {
  final ClassroomEntity classroom;

  const TeacherClassLoaded(this.classroom);

  @override
  List<Object?> get props => [classroom];
}

class TeacherError extends TeacherState {
  final String message;

  const TeacherError(this.message);

  @override
  List<Object?> get props => [message];
}

class TeacherOperationSuccess extends TeacherState {
  final String message;

  const TeacherOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
