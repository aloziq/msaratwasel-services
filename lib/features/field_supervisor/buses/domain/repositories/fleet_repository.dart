import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import '../../domain/entities/fleet_bus.dart';

abstract class FleetRepository {
  Future<Either<Failure, List<FleetBus>>> getFleetBuses();
}
