import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/driver_entities.dart';
import 'package:msaratwasel_services/features/driver/domain/repositories/driver_repository.dart';

// States
abstract class RouteNavigationState extends Equatable {
  const RouteNavigationState();
  @override
  List<Object?> get props => [];
}

class RouteNavigationInitial extends RouteNavigationState {}

class RouteNavigationLoading extends RouteNavigationState {}

class RouteNavigationLoaded extends RouteNavigationState {
  final List<StudentStop> stops;
  final List<LatLng> routePoints;
  final int currentStopIndex;
  final bool isArrivedAtStop; // True if driver clicked "Arrive"

  const RouteNavigationLoaded({
    required this.stops,
    required this.routePoints,
    this.currentStopIndex = 0,
    this.isArrivedAtStop = false,
  });

  StudentStop? get currentStop =>
      currentStopIndex < stops.length ? stops[currentStopIndex] : null;

  RouteNavigationLoaded copyWith({
    List<StudentStop>? stops,
    List<LatLng>? routePoints,
    int? currentStopIndex,
    bool? isArrivedAtStop,
  }) {
    return RouteNavigationLoaded(
      stops: stops ?? this.stops,
      routePoints: routePoints ?? this.routePoints,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      isArrivedAtStop: isArrivedAtStop ?? this.isArrivedAtStop,
    );
  }

  @override
  List<Object?> get props => [
    stops,
    routePoints,
    currentStopIndex,
    isArrivedAtStop,
  ];
}

class RouteNavigationError extends RouteNavigationState {
  final String message;
  const RouteNavigationError(this.message);
  @override
  List<Object?> get props => [message];
}

class RouteNavigationCompleted extends RouteNavigationState {}

// Cubit
@injectable
class RouteNavigationCubit extends Cubit<RouteNavigationState> {
  final DriverRepository _repository;

  RouteNavigationCubit(this._repository) : super(RouteNavigationInitial());

  Future<void> loadRoute() async {
    emit(RouteNavigationLoading());
    try {
      final stops = await _repository.getTripStops();
      final points = await _repository.getRoutePoints();
      emit(RouteNavigationLoaded(stops: stops, routePoints: points));
    } catch (e) {
      emit(RouteNavigationError(e.toString()));
    }
  }

  void arriveAtStop() {
    if (state is RouteNavigationLoaded) {
      final currentState = state as RouteNavigationLoaded;
      emit(currentState.copyWith(isArrivedAtStop: true));
    }
  }

  void advanceToNextStop() {
    if (state is RouteNavigationLoaded) {
      final currentState = state as RouteNavigationLoaded;
      if (currentState.currentStopIndex >= currentState.stops.length - 1) {
        emit(RouteNavigationCompleted());
      } else {
        emit(
          currentState.copyWith(
            currentStopIndex: currentState.currentStopIndex + 1,
            isArrivedAtStop: false,
          ),
        );
      }
    }
  }
}
