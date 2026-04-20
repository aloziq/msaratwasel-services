import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/maintenance_repository.dart';

// States
abstract class MaintenanceState extends Equatable {
  const MaintenanceState();
  @override
  List<Object?> get props => [];
}

class MaintenanceInitial extends MaintenanceState {}

class MaintenanceSubmitting extends MaintenanceState {}

class MaintenanceSuccess extends MaintenanceState {
  final String message;
  const MaintenanceSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class MaintenanceError extends MaintenanceState {
  final String message;
  const MaintenanceError(this.message);
  @override
  List<Object?> get props => [message];
}

class MaintenanceLoadingLogs extends MaintenanceState {}

class MaintenanceLogsLoaded extends MaintenanceState {
  final List<dynamic> expenses;
  final bool hasReachedMax;
  const MaintenanceLogsLoaded({required this.expenses, this.hasReachedMax = false});
  @override
  List<Object?> get props => [expenses, hasReachedMax];
}

class MaintenanceLogsError extends MaintenanceState {
  final String message;
  const MaintenanceLogsError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
@injectable
class MaintenanceCubit extends Cubit<MaintenanceState> {
  final MaintenanceRepository _repository;

  MaintenanceCubit(this._repository) : super(MaintenanceInitial());

  int _currentPage = 1;
  List<dynamic> _allExpenses = [];

  Future<void> fetchLogs({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _allExpenses = [];
    }

    if (_currentPage == 1) {
      emit(MaintenanceLoadingLogs());
    }

    try {
      final newExpenses = await _repository.getExpenses(page: _currentPage);
      
      if (newExpenses.isEmpty) {
        emit(MaintenanceLogsLoaded(expenses: _allExpenses, hasReachedMax: true));
      } else {
        _allExpenses.addAll(newExpenses);
        _currentPage++;
        emit(MaintenanceLogsLoaded(
          expenses: List.from(_allExpenses),
          hasReachedMax: newExpenses.length < 15,
        ));
      }
    } catch (e) {
      emit(MaintenanceLogsError(e.toString()));
    }
  }

  Future<void> submitFuelRefill({
    required double amount,
    required int odometer,
    required DateTime date,
    String? photoPath,
  }) async {
    emit(MaintenanceSubmitting());
    try {
      await _repository.submitFuelRefill(
        amount: amount,
        odometer: odometer,
        date: date,
        photoPath: photoPath,
      );
      emit(const MaintenanceSuccess('fuel_success'));
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> submitMaintenanceRequest({
    required String description,
    required DateTime date,
    double? cost,
    String? photoPath,
  }) async {
    emit(MaintenanceSubmitting());
    try {
      await _repository.submitMaintenanceRequest(
        description: description,
        date: date,
        cost: cost,
        photoPath: photoPath,
      );
      emit(const MaintenanceSuccess('request_success'));
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }
}
