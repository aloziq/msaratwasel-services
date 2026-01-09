import 'package:equatable/equatable.dart';
import '../../domain/entities/student_entity.dart';

abstract class ClassDetailsState extends Equatable {
  const ClassDetailsState();

  @override
  List<Object?> get props => [];
}

class ClassDetailsInitial extends ClassDetailsState {}

class ClassDetailsLoading extends ClassDetailsState {}

class ClassDetailsLoaded extends ClassDetailsState {
  final List<StudentEntity> students;
  final String classId;

  const ClassDetailsLoaded(this.students, this.classId);

  @override
  List<Object?> get props => [students, classId];
}

class ClassDetailsError extends ClassDetailsState {
  final String message;

  const ClassDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
