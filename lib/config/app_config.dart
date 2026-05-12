import '../core/network/api_config.dart';

class AppConfig {
  static const String googleMapsApiKey =
      'AIzaSyAbfF78GQP30cJOgdSDnc_vM77oXWZSBQM';
  static const String apiBaseUrl =
      'https://masaratwasal.com/api/'; // Legacy, use ApiConfig.baseUrl instead

  // ─── Reverb / WebSocket ──────────────────────────────────────────────────
  static String get reverbHost => ApiConfig.isLocal ? '192.168.8.188' : 'masaratwasal.com';
  static int get reverbPort => ApiConfig.isLocal ? 8080 : 443;
  static bool get reverbUseSsl => !ApiConfig.isLocal;
  static const String reverbKey = 'masarat-wasel-key';
}
