import '../core/network/api_config.dart';

class AppConfig {
  // تفعيل محاكاة الموقع برمجياً للتجربة المكتبية (true) أو استخدام الـ GPS الفعلي (false)
  static const bool enableLocationSimulation = false;

  // مسافة الفلترة (بالمتر) قبل التقاط إشارة موقع جديدة من الـ GPS
  static const int locationDistanceFilter = 8;

  // فترة خنق التحديث (بالثواني) قبل إرسال إحداثيات الباص الجديدة للسيرفر
  static const int locationUploadThrottleSeconds = 4;

  // المسافة الأدنى (بالمتر) التي يجب أن يقطعها الباص قبل طلب إعادة تخطيط المسار الأزرق من جوجل
  static const int googleDirectionsDistanceThreshold = 100;

  // الفترة الزمنية بالثواني لفحص حالة الطلاب دورياً كأمان إضافي (Polling)
  static const int statusPollingIntervalSeconds = 120;

  static const String googleMapsApiKey =
      'AIzaSyA2ZcFQqhauhU3l-Rj36fbRYomIO7L-ahs';
  static const String apiBaseUrl =
      'https://masaratwasal.com/api/'; // رابط الـ API القديم، يفضل استخدام ApiConfig.baseUrl بدلاً منه

  // ─── Reverb / WebSocket ──────────────────────────────────────────────────
  static String get reverbHost => ApiConfig.isLocal ? '192.168.8.188' : 'masaratwasal.com';
  static int get reverbPort => ApiConfig.isLocal ? 8080 : 443;
  static bool get reverbUseSsl => !ApiConfig.isLocal;
  static const String reverbKey = 'masarat-wasel-key';
}
