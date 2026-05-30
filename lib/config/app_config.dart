import '../core/network/api_config.dart';

class AppConfig {
  // Set to true for indoor testing/simulation, false for real hardware GPS tracking
  static const bool enableLocationSimulation = false;

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
