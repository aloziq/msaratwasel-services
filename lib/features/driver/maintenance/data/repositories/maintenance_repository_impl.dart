import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/entities/bus_expense.dart';
import '../models/bus_expense_model.dart';

@LazySingleton(as: MaintenanceRepository)
class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final Dio _dio = ApiClient.instance;

  @override
  Future<List<BusExpense>> getExpenses({int page = 1}) async {
    try {
      final response = await _dio.get('/driver/expenses', queryParameters: {'page': page});
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((json) => BusExpenseModel.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch expenses');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error fetching expenses');
    }
  }

  @override
  Future<void> submitFuelRefill({
    required double amount,
    required int odometer,
    required DateTime date,
    String? photoPath,
  }) async {
    final formData = FormData.fromMap({
      'type': 'fuel',
      'amount': amount,
      'date': date.toIso8601String().split('T')[0],
      'extra_info': odometer.toString(),
      if (photoPath != null)
        'receipt_photo': await MultipartFile.fromFile(
          photoPath,
          filename: photoPath.split('/').last,
        ),
    });

    try {
      final response = await _dio.post('/driver/expenses', data: formData);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit fuel refill');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error connecting to server');
    }
  }

  @override
  Future<void> submitMaintenanceRequest({
    required String description,
    required DateTime date,
    double? cost,
    String? photoPath,
  }) async {
    final formData = FormData.fromMap({
      'type': 'maintenance',
      'amount': cost ?? 0.0,
      'date': date.toIso8601String().split('T')[0],
      'extra_info': description,
      if (photoPath != null)
        'receipt_photo': await MultipartFile.fromFile(
          photoPath,
          filename: photoPath.split('/').last,
        ),
    });

    try {
      final response = await _dio.post('/driver/expenses', data: formData);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit maintenance request');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error connecting to server');
    }
  }
}
