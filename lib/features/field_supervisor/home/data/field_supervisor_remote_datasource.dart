import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';

/// Remote data source for Field Supervisor dashboard.
class FieldSupervisorRemoteDataSource {
  /// Fetches dashboard statistics (active buses, drivers, trips).
  static Future<Map<String, int>> getDashboardStats() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('field/dashboard-stats');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return {
          'active_buses': data['active_buses'] ?? 0,
          'active_drivers': data['active_drivers'] ?? 0,
          'active_trips': data['active_trips'] ?? 0,
        };
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error fetching dashboard stats: $e');
    }
    // Return zeros on failure
    return {'active_buses': 0, 'active_drivers': 0, 'active_trips': 0};
  }

  /// Fetches the list of active buses with details.
  static Future<List<Map<String, dynamic>>> getBuses() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('field/buses');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error fetching buses: $e');
    }
    return [];
  }

  /// Fetches the list of drivers and supervisors.
  static Future<Map<String, List<Map<String, dynamic>>>> getStaff() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('field/staff');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return {
          'drivers': List<Map<String, dynamic>>.from(data['drivers'] ?? []),
          'supervisors': List<Map<String, dynamic>>.from(
            data['supervisors'] ?? [],
          ),
        };
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error fetching staff: $e');
    }
    return {'drivers': [], 'supervisors': []};
  }

  /// Fetches inspection items checklist.
  static Future<List<Map<String, dynamic>>> getInspectionItems() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('field/inspection-items');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error fetching inspection items: $e');
    }
    return [];
  }

  /// Submits an inspection report.
  static Future<Map<String, dynamic>?> submitInspection({
    required int busId,
    required String overallStatus,
    required List<Map<String, dynamic>> results,
    String? notes,
    List<File>? photos,
  }) async {
    try {
      final dio = ApiClient.instance;

      if (photos == null || photos.isEmpty) {
        final response = await dio.post(
          'field/inspections',
          data: {
            'bus_id': busId,
            'overall_status': overallStatus,
            'results': results,
            'notes': notes,
          },
        );

        if (response.statusCode == 201 && response.data['success'] == true) {
          return response.data['data'];
        }
        return null;
      }

      final Map<String, dynamic> mapData = {
        'bus_id': busId,
        'overall_status': overallStatus,
      };
      if (notes != null) mapData['notes'] = notes;

      for (int i = 0; i < results.length; i++) {
        mapData['results[$i][item_id]'] = results[i]['item_id'];
        mapData['results[$i][is_passed]'] = results[i]['is_passed'] ?? false;
        if (results[i]['notes'] != null) {
          mapData['results[$i][notes]'] = results[i]['notes'];
        }
      }

      for (int i = 0; i < photos.length; i++) {
        final file = photos[i];
        final fileName = file.path.split('/').last;
        mapData['photos[$i]'] = await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap(mapData);
      final response = await dio.post('field/inspections', data: formData);

      if (response.statusCode == 201 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error submitting inspection: $e');
    }
    return null;
  }

  /// Reports an incident (SOS, accident, breakdown, health).
  static Future<Map<String, dynamic>?> reportIncident({
    int? busId,
    required String type,
    required String severity,
    required String description,
    double? locationLat,
    double? locationLng,
    List<int>? studentIds,
    List<File>? photos,
  }) async {
    try {
      final dio = ApiClient.instance;

      final Map<String, dynamic> mapData = {
        'bus_id': busId,
        'type': type,
        'severity': severity,
        'description': description,
      };

      if (locationLat != null) mapData['location_lat'] = locationLat;
      if (locationLng != null) mapData['location_lng'] = locationLng;

      if (studentIds != null && studentIds.isNotEmpty) {
        // Send array of integers
        for (int i = 0; i < studentIds.length; i++) {
          mapData['student_ids[$i]'] = studentIds[i];
        }
      }

      if (photos != null && photos.isNotEmpty) {
        for (int i = 0; i < photos.length; i++) {
          final file = photos[i];
          final fileName = file.path.split('/').last;
          mapData['photos[$i]'] = await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          );
        }
      }

      final formData = FormData.fromMap(mapData);

      final response = await dio.post('field/incidents', data: formData);

      if (response.statusCode == 201 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error reporting incident: $e');
    }
    return null;
  }

  /// Submits a violation report.
  static Future<Map<String, dynamic>?> submitViolation({
    required int busId,
    required String type,
    required String description,
  }) async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.post(
        'field/violations',
        data: {'bus_id': busId, 'type': type, 'description': description},
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error submitting violation: $e');
    }
    return null;
  }

  /// Fetches list of incidents.
  static Future<List<Map<String, dynamic>>> getIncidents() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('field/incidents');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error fetching incidents: $e');
    }
    return [];
  }

  /// Fetches list of inspections.
  static Future<List<Map<String, dynamic>>> getInspections() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('field/inspections');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error fetching inspections: $e');
    }
    return [];
  }

  /// Fetches list of field trips.
  static Future<List<Map<String, dynamic>>> getFieldTrips() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('field/field-trips');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error fetching field trips: $e');
    }
    return [];
  }

  /// Fetches dashboard report summary.
  static Future<Map<String, dynamic>> getDashboardReport() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('field/report');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error fetching report: $e');
    }
    return {};
  }

  /// Fetches list of delays, optionally filtered by type.
  static Future<List<Map<String, dynamic>>> getDelays({String? type}) async {
    try {
      final dio = ApiClient.instance;
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      final response = await dio.get(
        'field/delays',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error fetching delays: $e');
    }
    return [];
  }

  /// Stores a new delay record.
  static Future<Map<String, dynamic>?> storeDelay({
    required String type,
    int? studentId,
    int? busId,
    required int durationMinutes,
    String? reason,
    String? notes,
  }) async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.post(
        'field/delays',
        data: {
          'type': type,
          'student_id': studentId,
          'bus_id': busId,
          'duration_minutes': durationMinutes,
          'reason': reason,
          'notes': notes,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error storing delay: $e');
    }
    return null;
  }

  /// Fetches list of students for search.
  static Future<List<Map<String, dynamic>>> getStudents({
    String? search,
  }) async {
    try {
      final dio = ApiClient.instance;
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      final response = await dio.get(
        'field/students',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('[FieldSupervisor] Error fetching students: $e');
    }
    return [];
  }
}
