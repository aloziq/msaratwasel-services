// **************************************************************************
// ApiClient - Wasel Services App
// **************************************************************************

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'api_config.dart';

class ApiClient {
  static Dio get instance {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),

        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Interceptor لإضافة token تلقائياً في كل request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          try {
            final prefs = GetIt.instance<SharedPreferences>();

            // Add Accept-Language header dynamically based on app settings
            final appLocale = prefs.getString('app_locale');
            String lang = 'ar';
            if (appLocale != null && appLocale != 'system') {
              lang = appLocale;
            } else {
              try {
                lang = ui.PlatformDispatcher.instance.locale.languageCode;
              } catch (_) {
                lang = 'ar';
              }
            }
            options.headers['Accept-Language'] = lang;

            final token = prefs.getString('USER_TOKEN');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              // تم إخفاء طباعة إضافة التوكن العادية لتقليل الزحمة
            } else {
              debugPrint('[ApiClient] ⚠️ No token found for ${options.path}');
            }
          } catch (e) {
            debugPrint('[ApiClient] ❌ Error reading token: $e');
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // معالجة خطأ 401 - التوكن منتهي أو غير صالح
          if (e.response?.statusCode == 401) {
            debugPrint(
              '[ApiClient] 🚫 401 Unauthenticated - Token expired or invalid',
            );
            _handleUnauthorized();
          }
          return handler.next(e);
        },
      ),
    );

    // ── إضافة أداة طباعة وتتبع مفصلة للطلبات في بيئة التطوير ──
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    return dio;
  }

  /// مسح التوكن المنتهي من التخزين المحلي
  static void _handleUnauthorized() {
    try {
      final prefs = GetIt.instance<SharedPreferences>();
      prefs.remove('USER_TOKEN');
      prefs.remove('USER_ID');
      prefs.remove('USER_NAME');
      prefs.remove('USER_ROLE');
      prefs.remove('USER_AVATAR');
      prefs.remove('USER_BUS_ID');
      debugPrint('[ApiClient] 🗑️ Cleared expired session data');
    } catch (e) {
      debugPrint('[ApiClient] Error clearing session: $e');
    }
  }

  /// إنشاء instance مع token للـ endpoints المحمية
  static Dio authenticatedInstance(String token) {
    final dio = instance;
    dio.options.headers['Authorization'] = 'Bearer $token';
    return dio;
  }
}
