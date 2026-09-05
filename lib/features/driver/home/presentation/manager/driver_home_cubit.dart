import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/repositories/home_repository.dart';
import 'package:msaratwasel_services/core/services/location_service.dart';

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

class DriverHomeNoBus extends DriverHomeState {}

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
  StreamSubscription? _connectivitySubscription;
  bool _wasAwaitingConfirmation = false;

  DriverHomeCubit(this._repository) : super(DriverHomeInitial());

  Future<void> loadDashboard({bool showLoading = true}) async {
    debugPrint('DriverHomeCubit: loadDashboard called (showLoading: $showLoading)');
    if (_connectivitySubscription == null) {
      _initConnectivityListener();
    }
    if (showLoading) {
      emit(DriverHomeLoading());
    }
    try {
      final trips = await _repository.getMyTrips();
      if (isClosed) return;
      debugPrint('DriverHomeCubit: trips loaded: ${trips.length}');
      emit(DriverHomeLoaded(trips));

      // Handle Location Service Lifecycle
      final activeTrip = trips.where((t) => t.status == 'in_progress' || t.status == 'awaiting_confirmation').firstOrNull;
      if (activeTrip != null) {
        LocationService.start();
      } else {
        // If no active trips, we might want to stop the service to save battery
        LocationService.stop();
      }

      _checkAndStartPolling(trips);
    } catch (e) {
      if (isClosed) return;
      debugPrint('DriverHomeCubit: loadDashboard error: $e');
      final err = e.toString();
      if (err.contains('حافلة') ||
          err.contains('403') ||
          err.contains('404') ||
          err.contains('School not found') ||
          err.contains('No bus')) {
        emit(DriverHomeNoBus());
      } else {
        emit(DriverHomeError(e.toString()));
      }
    }
  }

  Future<void> startTrip(String tripId) async {
    debugPrint('DriverHomeCubit: startTrip called with tripId: $tripId');
    if (state is DriverHomeLoaded) {
      try {
        debugPrint('DriverHomeCubit: calling repository.startTrip');
        await _repository.startTrip(tripId);
        debugPrint(
          'DriverHomeCubit: repository.startTrip success, reloading dashboard',
        );

        // After starting, the trip is now awaiting_confirmation
        // Start polling to detect when supervisor confirms
        _wasAwaitingConfirmation = true;
        await loadDashboard();
        debugPrint('DriverHomeCubit: after reload dashboard, state is: $state');
      } catch (e) {
        if (isClosed) return;
        
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('socketexception') || 
            errorStr.contains('network error') || 
            errorStr.contains('failed host lookup') ||
            errorStr.contains('connection refused') ||
            errorStr.contains('os error: 101') ||
            errorStr.contains('dioexception [connection error]')) {
          debugPrint('DriverHomeCubit: Network error detected in startTrip. Stopping polling.');
          _stopPolling();
          emit(const DriverHomeError("عذراً، تعذر الاتصال بالسيرفر. يرجى التحقق من شبكة الإنترنت والمحاولة مجدداً"));
        } else {
          emit(DriverHomeError(e.toString()));
        }
      }
    } else {
      debugPrint(
        'DriverHomeCubit: startTrip ignored because state is ${state.runtimeType}',
      );
    }
  }

  Future<void> confirmTrip(String tripId) async {
    debugPrint('DriverHomeCubit: confirmTrip called with tripId: $tripId');
    try {
      await _repository.confirmTrip(tripId);
      // 🔥 جعلها true بدلاً من false لكي يتم اكتشاف التغيير والانتقال التلقائي لشاشة الخريطة
      _wasAwaitingConfirmation = true; 
      await loadDashboard();
    } catch (e) {
      if (isClosed) return;
      
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') || 
          errorStr.contains('network error') || 
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection refused') ||
          errorStr.contains('os error: 101') ||
          errorStr.contains('dioexception [connection error]')) {
        debugPrint('DriverHomeCubit: Network error detected in confirmTrip. Stopping polling.');
        _stopPolling(); // Prevent random page updates while offline
        emit(const DriverHomeError("عذراً، تعذر الاتصال بالسيرفر. يرجى التحقق من شبكة الإنترنت والمحاولة مجدداً"));
      } else {
        emit(DriverHomeError(e.toString()));
      }
    }
  }

  /// Check if we have a trip awaiting confirmation and start polling
  void _checkAndStartPolling(List<TripStatus> trips) {
    final hasAwaitingTrip = trips.any(
      (t) => t.status == 'awaiting_confirmation',
    );

    // We always start polling to detect new trips or status changes
    // If waiting for confirmation, poll faster (3s), otherwise poll every 10s
    _startPolling(interval: hasAwaitingTrip ? 3 : 10);

    // If we WERE waiting and now a trip is in_progress, supervisor confirmed!
    if (_wasAwaitingConfirmation && !hasAwaitingTrip) {
      final inProgressTrip = trips
          .where((t) => t.status == 'in_progress')
          .firstOrNull;
      if (inProgressTrip != null) {
        debugPrint(
          'DriverHomeCubit: 🎉 Trip confirmed by supervisor! Navigating to map...',
        );
        _wasAwaitingConfirmation = false;
        emit(DriverHomeTripConfirmed(trips, inProgressTrip.id.toString()));
      } else {
        _wasAwaitingConfirmation = false;
      }
    }
  }

  void _startPolling({int interval = 3}) {
    _stopPolling(); // Prevent multiple timers
    debugPrint('DriverHomeCubit: 🔄 Starting status polling (every ${interval}s)');
    _pollingTimer = Timer.periodic(Duration(seconds: interval), (_) async {
      try {
        final trips = await _repository.getMyTrips();
        if (isClosed) return;

        final hasAwaitingTrip = trips.any(
          (t) => t.status == 'awaiting_confirmation',
        );

        // Check for confirmation transition
        if (!hasAwaitingTrip && _wasAwaitingConfirmation) {
          final inProgressTrip = trips
              .where((t) => t.status == 'in_progress')
              .firstOrNull;
          if (inProgressTrip != null) {
            debugPrint(
              'DriverHomeCubit: 🎉 Poll detected confirmation! Trip ${inProgressTrip.id}',
            );
            _wasAwaitingConfirmation = false;
            
            // Start location tracking now that trip is confirmed
            LocationService.start();

            // Stop current polling and emit confirmed state
            _stopPolling();
            emit(DriverHomeTripConfirmed(trips, inProgressTrip.id.toString()));
            return;
          }
        }

        // If the status changed to needing a different interval, restart polling
        if (hasAwaitingTrip && interval != 3) {
          _startPolling(interval: 3);
          return;
        } else if (!hasAwaitingTrip && interval == 3) {
           // We might want to slow down if no longer awaiting
           _startPolling(interval: 10);
           return;
        }

        emit(DriverHomeLoaded(trips));
      } catch (e) {
        debugPrint('DriverHomeCubit: polling error (silent): $e');
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _initConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final List<ConnectivityResult> resultsList = results;

      final hasConnection = resultsList.any((result) => result != ConnectivityResult.none);

      if (hasConnection && state is DriverHomeError) {
        loadDashboard(showLoading: true);
      }
    });
  }

  @override
  Future<void> close() {
    _stopPolling();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
