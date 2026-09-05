import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:msaratwasel_services/config/app_config.dart';

class DirectionService {
  final PolylinePoints _polylinePoints;
  
  // Simple in-memory cache for encoded polylines
  final Map<String, List<LatLng>> _cache = {};

  DirectionService({PolylinePoints? polylinePoints})
      : _polylinePoints = polylinePoints ?? PolylinePoints(apiKey: AppConfig.googleMapsApiKey);

  Future<List<LatLng>> getRouteBetweenCoordinates(
    LatLng origin,
    LatLng destination,
  ) async {
    final String cacheKey = '${origin.latitude},${origin.longitude}_${destination.latitude},${destination.longitude}';
    
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        final List<LatLng> points = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        _cache[cacheKey] = points;
        return points;
      } else {
        throw Exception('Directions Error: ${result.errorMessage}');
      }
    } catch (e) {
      throw Exception('Failed to fetch directions: $e');
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
