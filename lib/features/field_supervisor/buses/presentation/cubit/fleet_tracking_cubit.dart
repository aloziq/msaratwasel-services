import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:msaratwasel_services/core/usecases/usecase.dart';

import '../../domain/entities/fleet_bus.dart';
import '../../domain/usecases/get_fleet_buses_usecase.dart';

// ── States ──────────────────────────────────────────────────────────────────

abstract class FleetTrackingState extends Equatable {
  const FleetTrackingState();
  @override
  List<Object?> get props => [];
}

class FleetTrackingInitial extends FleetTrackingState {}

class FleetTrackingLoading extends FleetTrackingState {}

class FleetTrackingLoaded extends FleetTrackingState {
  final List<FleetBus> buses;
  final String? selectedBusId;

  const FleetTrackingLoaded(this.buses, {this.selectedBusId});

  FleetTrackingLoaded copyWith({
    List<FleetBus>? buses,
    String? selectedBusId,
    bool clearSelection = false,
  }) {
    return FleetTrackingLoaded(
      buses ?? this.buses,
      selectedBusId: clearSelection
          ? null
          : (selectedBusId ?? this.selectedBusId),
    );
  }

  FleetBus? get selectedBus => selectedBusId == null
      ? null
      : buses.cast<FleetBus?>().firstWhere(
          (b) => b?.id == selectedBusId,
          orElse: () => null,
        );

  int get activeCount =>
      buses.where((b) => b.status == FleetBusStatus.active).length;
  int get stoppedCount =>
      buses.where((b) => b.status == FleetBusStatus.stopped).length;
  int get maintenanceCount =>
      buses.where((b) => b.status == FleetBusStatus.maintenance).length;

  @override
  List<Object?> get props => [buses, selectedBusId];
}

class FleetTrackingError extends FleetTrackingState {
  final String message;
  const FleetTrackingError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ───────────────────────────────────────────────────────────────────

@injectable
class FleetTrackingCubit extends Cubit<FleetTrackingState> {
  final GetFleetBusesUseCase getFleetBuses;

  FleetTrackingCubit(this.getFleetBuses) : super(FleetTrackingInitial());

  Future<void> loadFleet() async {
    emit(FleetTrackingLoading());

    final result = await getFleetBuses(NoParams());

    result.fold(
      (failure) => emit(FleetTrackingError(failure.message ?? 'Unknown error')),
      (buses) => emit(FleetTrackingLoaded(buses)),
    );
  }

  void selectBus(String busId) {
    final current = state;
    if (current is FleetTrackingLoaded) {
      emit(current.copyWith(selectedBusId: busId));
    }
  }

  void clearSelection() {
    final current = state;
    if (current is FleetTrackingLoaded) {
      emit(current.copyWith(clearSelection: true));
    }
  }
}
