import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/bus_trip_entity.dart';
import '../../domain/entities/bus_student_entity.dart';
import '../../domain/repositories/assistant_repository.dart';

part 'bus_trip_state.dart';

class BusTripCubit extends Cubit<BusTripState> {
  final AssistantRepository repository;

  BusTripCubit({required this.repository}) : super(BusTripInitial());

  Future<void> loadTrip() async {
    emit(BusTripLoading());
    final result = await repository.getActiveTrip();
    result.fold(
      (failure) => emit(BusTripError(failure)),
      (trip) => emit(BusTripLoaded(trip)),
    );
  }

  Future<void> updateStudentStatus(
    String studentId,
    BusStudentStatus status,
  ) async {
    if (state is BusTripLoaded) {
      final currentTrip = (state as BusTripLoaded).trip;
      final updatedStudents = currentTrip.students.map((student) {
        if (student.id == studentId) {
          return student.copyWith(status: status);
        }
        return student;
      }).toList();

      final updatedTrip = currentTrip.copyWith(students: updatedStudents);
      emit(BusTripLoaded(updatedTrip));

      final result = await repository.updateStudentStatus(studentId, status);
      result.fold((failure) {
        // Revert on failure
        emit(BusTripLoaded(currentTrip));
        emit(BusTripError(failure));
      }, (_) => null);
    }
  }

  Future<void> updateBehavioralNote(String studentId, String note) async {
    if (state is BusTripLoaded) {
      final currentTrip = (state as BusTripLoaded).trip;
      final updatedStudents = currentTrip.students.map((student) {
        if (student.id == studentId) {
          return student.copyWith(behavioralNote: note);
        }
        return student;
      }).toList();

      emit(BusTripLoaded(currentTrip.copyWith(students: updatedStudents)));

      await repository.updateBehavioralNote(studentId, note);
    }
  }
}
