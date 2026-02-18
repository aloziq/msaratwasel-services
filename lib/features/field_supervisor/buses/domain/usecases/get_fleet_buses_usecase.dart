import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/core/usecases/usecase.dart';
import '../entities/fleet_bus.dart';
import '../repositories/fleet_repository.dart';

@lazySingleton
class GetFleetBusesUseCase implements UseCase<List<FleetBus>, NoParams> {
  final FleetRepository repository;

  GetFleetBusesUseCase(this.repository);

  @override
  Future<Either<Failure, List<FleetBus>>> call(NoParams params) {
    return repository.getFleetBuses();
  }
}
