class ApiConfig {
  static const bool isLocal = false; // تم التغيير إلى false لاستخدام الاستضافة الحية (الإنتاج)

  // رابط السيرفر المحلي (تأكد من IP جهازك إذا كنت تختبر على هاتف حقيقي بدلاً من 10.0.2.2)
  static const String _localDomain = "http://192.168.8.188:8001";
  static const String _localUrl = "$_localDomain/api/";

  // رابط الاستضافة الحية
  static const String _productionDomain = "https://masaratwasal.com";

  static const String _productionUrl = "$_productionDomain/api/";

  // هذا المتغير هو ما سيستخدمه التطبيق في كل الـ Requests
  static String get baseUrl => isLocal ? _localUrl : _productionUrl;

  static String get domainUrl => isLocal ? _localDomain : _productionDomain;

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty)
      return "https://ui-avatars.com/api/?name=User&background=random&format=png";
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    // Check if the path already contains 'storage/', if not prepend it
    if (path.startsWith('storage/')) {
      return "$domainUrl/$path";
    }
    return "$domainUrl/storage/$path";
  }
}
