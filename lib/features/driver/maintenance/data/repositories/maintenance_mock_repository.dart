import 'package:injectable/injectable.dart';
import '../../domain/repositories/maintenance_repository.dart';

@LazySingleton(as: MaintenanceRepository)
class MaintenanceMockRepository implements MaintenanceRepository {
  @override
  Future<void> submitFuelRefill({
    required double amount,
    required int odometer,
    required DateTime date,
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> submitMaintenanceRequest({
    required String description,
    required DateTime date,
    double? cost,
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
