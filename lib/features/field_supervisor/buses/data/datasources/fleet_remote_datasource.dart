import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/fleet_bus.dart';
import '../models/fleet_bus_model.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';

abstract class FleetRemoteDataSource {
  Future<List<FleetBusModel>> getFleetBuses();
}

@LazySingleton(as: FleetRemoteDataSource)
class FleetRemoteDataSourceImpl implements FleetRemoteDataSource {
  @override
  Future<List<FleetBusModel>> getFleetBuses() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('field/buses');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((json) {
          // Map API response fields to FleetBusModel fields
          return FleetBusModel(
            id: json['id'].toString(),
            name: json['bus_code'] ?? 'حافلة ${json['bus_number'] ?? ''}',
            driverName: json['driver'] ?? 'N/A',
            supervisorName: json['supervisor'] ?? 'N/A',
            fieldSupervisorName: json['field_supervisor'],
            frontQrUrl: json['front_qr'],
            backQrUrl: json['back_qr'],
            schoolName: json['school'] ?? 'N/A',
            driverPhone: '', // Not returned from this endpoint
            route: '',       // Not returned from this endpoint
            lat: (json['location_lat'] as num?)?.toDouble() ?? 0.0,
            lng: (json['location_lng'] as num?)?.toDouble() ?? 0.0,
            speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
            studentsOnBoard: 0, // Not returned from this endpoint
            status: _mapStatus(json['status']),
            updatedAt: json['last_update'] != null
                ? DateTime.tryParse(json['last_update']) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[FleetRemoteDataSource] Error fetching buses: $e');
    }
    return [];
  }

  FleetBusStatus _mapStatus(String? status) {
    switch (status) {
      case 'active':
        return FleetBusStatus.active;
      case 'maintenance':
        return FleetBusStatus.maintenance;
      default:
        return FleetBusStatus.stopped;
    }
  }
}
