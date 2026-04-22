import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/repositories/home_repository.dart';

// States
abstract class DriverHomeState extends Equatable {
  const DriverHomeState();
  @override
  List<Object?> get props => [];
}

class DriverHomeInitial extends DriverHomeState {}

class DriverHomeLoading extends DriverHomeState {}

class DriverHomeLoaded extends DriverHomeState {
  final List<TripStatus> trips;
  const DriverHomeLoaded(this.trips);
  @override
  List<Object?> get props => [trips];
}

/// Special state: trip was confirmed by supervisor → navigate to map
class DriverHomeTripConfirmed extends DriverHomeState {
  final List<TripStatus> trips;
  final String confirmedTripId;
  const DriverHomeTripConfirmed(this.trips, this.confirmedTripId);
  @override
  List<Object?> get props => [trips, confirmedTripId];
}

class DriverHomeError extends DriverHomeState {
  final String message;
  const DriverHomeError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
@injectable
class DriverHomeCubit extends Cubit<DriverHomeState> {
  final HomeRepository _repository;
  Timer? _pollingTimer;
  bool _wasAwaitingConfirmation = false;

  DriverHomeCubit(this._repository) : super(DriverHomeInitial());

  Future<void> loadDashboard() async {
    debugPrint('DriverHomeCubit: loadDashboard called');
    emit(DriverHomeLoading());
    try {
      final trips = await _repository.getMyTrips();
      debugPrint('DriverHomeCubit: trips loaded: ${trips.length}');
      emit(DriverHomeLoaded(trips));
      _checkAndStartPolling(trips);
    } catch (e) {
      debugPrint('DriverHomeCubit: loadDashboard error: $e');
      emit(DriverHomeError(e.toString()));
    }
  }

  Future<void> startTrip(String tripId) async {
    debugPrint('DriverHomeCubit: startTrip called with tripId: $tripId');
    if (state is DriverHomeLoaded) {
      try {
        debugPrint('DriverHomeCubit: calling repository.startTrip');
        await _repository.startTrip(tripId);
        debugPrint('DriverHomeCubit: repository.startTrip success, reloading dashboard');
        
        // After starting, the trip is now awaiting_confirmation
        // Start polling to detect when supervisor confirms
        _wasAwaitingConfirmation = true;
        await loadDashboard(); 
        debugPrint('DriverHomeCubit: after reload dashboard, state is: $state');
      } catch (e) {
        debugPrint('DriverHomeCubit: startTrip catch block error: $e');
        emit(DriverHomeError(e.toString()));
      }
    } else {
      debugPrint('DriverHomeCubit: startTrip ignored because state is ${state.runtimeType}');
    }
  }

  /// Check if we have a trip awaiting confirmation and start polling
  void _checkAndStartPolling(List<TripStatus> trips) {
    final hasAwaitingTrip = trips.any((t) => t.status == 'awaiting_confirmation');
    
    if (hasAwaitingTrip) {
      _startPolling();
    } else {
      _stopPolling();
      
      // If we WERE waiting and now a trip is in_progress, supervisor confirmed!
      if (_wasAwaitingConfirmation) {
        final inProgressTrip = trips.where((t) => t.status == 'in_progress').firstOrNull;
        if (inProgressTrip != null) {
          debugPrint('DriverHomeCubit: 🎉 Trip confirmed by supervisor! Navigating to map...');
          _wasAwaitingConfirmation = false;
          emit(DriverHomeTripConfirmed(trips, inProgressTrip.id.toString()));
          return;
        }
        _wasAwaitingConfirmation = false;
      }
    }
  }

  void _startPolling() {
    _stopPolling(); // Prevent multiple timers
    debugPrint('DriverHomeCubit: 🔄 Starting status polling (every 3s)');
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final trips = await _repository.getMyTrips();
        if (isClosed) return;
        
        final stillAwaiting = trips.any((t) => t.status == 'awaiting_confirmation');
        
        if (!stillAwaiting && _wasAwaitingConfirmation) {
          // Status changed! Check if it became in_progress
          final inProgressTrip = trips.where((t) => t.status == 'in_progress').firstOrNull;
          if (inProgressTrip != null) {
            debugPrint('DriverHomeCubit: 🎉 Poll detected confirmation! Trip ${inProgressTrip.id}');
            _stopPolling();
            _wasAwaitingConfirmation = false;
            emit(DriverHomeTripConfirmed(trips, inProgressTrip.id.toString()));
            return;
          }
        }
        
        if (!stillAwaiting) {
          _stopPolling();
          _wasAwaitingConfirmation = false;
        }
        
        emit(DriverHomeLoaded(trips));
      } catch (e) {
        debugPrint('DriverHomeCubit: polling error (silent): $e');
        // Don't emit error for polling failures - just keep trying
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
