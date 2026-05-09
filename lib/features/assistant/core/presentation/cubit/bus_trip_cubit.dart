import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/bus_trip_entity.dart';
import '../../domain/entities/bus_student_entity.dart';
import '../../domain/repositories/assistant_repository.dart';

part 'bus_trip_state.dart';

class BusTripCubit extends Cubit<BusTripState> {
  final AssistantRepository repository;

  BusTripCubit({required this.repository}) : super(BusTripInitial());

  Future<void> loadTrip({bool silent = false}) async {
    if (!silent) emit(BusTripLoading());
    final result = await repository.getActiveTrip();
    result.fold(
      (failure) => emit(BusTripError(failure)),
      (trip) => emit(BusTripLoaded(trip)),
    );
  }

  Future<void> confirmTrip(String tripId) async {
    if (state is BusTripLoaded) {
      final currentTrip = (state as BusTripLoaded).trip;
      emit(BusTripLoading()); // Indicate work in progress
      
      final result = await repository.confirmTrip(tripId);
      result.fold(
        (failure) {
          emit(BusTripUpdateError(failure));
          emit(BusTripLoaded(currentTrip));
        },
        (_) {
          emit(const BusTripUpdateSuccess('تم قبول الرحلة بنجاح'));
          loadTrip(); // Reload full list after confirmation
        },
      );
    }
  }

  Future<void> updateStudentStatus(
    String studentId,
    BusStudentStatus status, {
    String? direction,
  }) async {
    if (state is BusTripLoaded) {
      final currentTrip = (state as BusTripLoaded).trip;
      final finalDirection = direction ?? currentTrip.suggestedDirection;

      final updatedStudents = currentTrip.students.map((student) {
        if (student.id == studentId) {
          return student.copyWith(status: status);
        }
        return student;
      }).toList();

      final updatedTrip = currentTrip.copyWith(students: updatedStudents);
      emit(BusTripLoaded(updatedTrip)); // Optimistic UI update

      final result = await repository.updateStudentStatus(studentId, status, finalDirection);
      result.fold((failure) {
        emit(BusTripUpdateError(failure));
        emit(BusTripLoaded(currentTrip));
      }, (_) {
         emit(const BusTripUpdateSuccess('تم التحديث بنجاح'));
         emit(BusTripLoaded(updatedTrip));
      });
    }
  }

  Future<void> groupAlight(List<String> studentIds, String direction) async {
    if (state is BusTripLoaded) {
      final currentTrip = (state as BusTripLoaded).trip;
      
      emit(BusTripLoading()); // Indicate work in progress for batch action
      
      final result = await repository.groupAlight(
        studentIds: studentIds,
        direction: direction,
      );

      result.fold(
        (failure) {
          emit(BusTripUpdateError(failure));
          emit(BusTripLoaded(currentTrip));
        },
        (_) {
          emit(const BusTripUpdateSuccess('تم تحديث الكل بنجاح'));
          loadTrip(); // Reload full list after batch action to be safe
        },
      );
    }
  }

  Future<void> groupBoard(List<String> studentIds, String direction) async {
    if (state is BusTripLoaded) {
      final currentTrip = (state as BusTripLoaded).trip;
      
      emit(BusTripLoading());
      
      final result = await repository.groupBoard(
        studentIds: studentIds,
        direction: direction,
      );

      result.fold(
        (failure) {
          emit(BusTripUpdateError(failure));
          emit(BusTripLoaded(currentTrip));
        },
        (_) {
          emit(const BusTripUpdateSuccess('تم تسجيل ركوب الكل بنجاح'));
          loadTrip(); 
        },
      );
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
