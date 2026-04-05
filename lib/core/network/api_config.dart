class ApiConfig {
  // هذا هو المتغير الوحيد الذي ستغيره للربط بين المحلي والاستضافة
  static const bool isLocal = false;

  // رابط السيرفر المحلي (تأكد من IP جهازك إذا كنت تختبر على هاتف حقيقي بدلاً من 10.0.2.2)
  static const String _localUrl = "http://192.168.8.188:8001/api/"; 
  
  // رابط الاستضافة الحية
  static const String _productionUrl = "https://srv1428362.hstgr.cloud/api/";

  // هذا المتغير هو ما سيستخدمه التطبيق في كل الـ Requests
  static String get baseUrl => isLocal ? _localUrl : _productionUrl;
}
