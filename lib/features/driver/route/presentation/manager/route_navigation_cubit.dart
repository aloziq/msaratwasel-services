import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/student_stop.dart';
import '../../domain/repositories/route_repository.dart';
import '../../../../../core/services/reverb_service.dart';
import '../../../../../core/network/api_client.dart';

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
  final RouteRepository _repository;
  ReverbService? _reverbService;

  RouteNavigationCubit(this._repository) : super(RouteNavigationInitial()) {
    _initReverb();
  }

  Future<void> _initReverb() async {
    final busId = GetIt.instance<SharedPreferences>().getString('USER_BUS_ID') ?? '';
    if (busId.isNotEmpty) {
      _reverbService = ReverbService(
        dio: ApiClient.instance,
        onStudentLocationUpdated: (data) {
          // Parent updated location, refetch stops and points
          loadRoute(preserveIndex: true);
        }
      );
      _reverbService!.connect();
      _reverbService!.subscribe('private-bus.$busId');
    }
  }

  Future<void> loadRoute({bool preserveIndex = false}) async {
    final int previousIndex = (state is RouteNavigationLoaded && preserveIndex) 
        ? (state as RouteNavigationLoaded).currentStopIndex 
        : 0;
    
    emit(RouteNavigationLoading());
    try {
      final stops = await _repository.getTripStops();
      final points = await _repository.getRoutePoints();
      emit(RouteNavigationLoaded(
        stops: stops, 
        routePoints: points, 
        currentStopIndex: previousIndex
      ));
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

  @override
  Future<void> close() {
    _reverbService?.dispose();
    return super.close();
  }
}
