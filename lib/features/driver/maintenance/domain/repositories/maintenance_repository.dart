import 'package:msaratwasel_services/features/driver/maintenance/domain/entities/bus_expense.dart';

abstract class MaintenanceRepository {
  Future<void> submitFuelRefill({
    required double amount,
    required int odometer,
    required DateTime date,
    String? photoPath,
  });
  Future<void> submitMaintenanceRequest({
    required String description,
    required DateTime date,
    double? cost,
    String? photoPath,
  });
  Future<List<BusExpense>> getExpenses({int page = 1});
}
