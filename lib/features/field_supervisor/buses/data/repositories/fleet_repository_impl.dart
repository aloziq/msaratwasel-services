import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import '../../domain/entities/fleet_bus.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../datasources/fleet_remote_datasource.dart';

@LazySingleton(as: FleetRepository)
class FleetRepositoryImpl implements FleetRepository {
  final FleetRemoteDataSource remoteDataSource;

  FleetRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<FleetBus>>> getFleetBuses() async {
    try {
      final buses = await remoteDataSource.getFleetBuses();
      return Right(buses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
