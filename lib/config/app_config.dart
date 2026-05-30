import '../core/network/api_config.dart';

class AppConfig {
  // Set to true for indoor testing/simulation, false for real hardware GPS tracking
  static const bool enableLocationSimulation = false;

  // Distance filter (in meters) before triggering a GPS location update
  // Recommended: 0 for local testing/simulation, 20 for real production
  static const int locationDistanceFilter = 10;

  // Throttle time (in seconds) between sending updates to the server
  // Recommended: 3 for local testing/simulation, 6 for real production
  static const int locationUploadThrottleSeconds = 5;

  static const String googleMapsApiKey =
      'AIzaSyA2ZcFQqhauhU3l-Rj36fbRYomIO7L-ahs';
  static const String apiBaseUrl =
      'https://masaratwasal.com/api/'; // Legacy, use ApiConfig.baseUrl instead

  // ─── Reverb / WebSocket ──────────────────────────────────────────────────
  static String get reverbHost => ApiConfig.isLocal ? '192.168.8.188' : 'masaratwasal.com';
  static int get reverbPort => ApiConfig.isLocal ? 8080 : 443;
  static bool get reverbUseSsl => !ApiConfig.isLocal;
  static const String reverbKey = 'masarat-wasel-key';
}
