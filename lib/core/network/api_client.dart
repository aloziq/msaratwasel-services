// **************************************************************************
// ApiClient - Wasel Services App
// **************************************************************************

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'api_config.dart';
import '../responsive/api_language_interceptor.dart';
import '../../features/shared/auth/presentation/cubit/auth_cubit.dart';

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

    // Interceptor لضبط اللغة
    dio.interceptors.add(ApiLanguageInterceptor());

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

    // Dio Logger disabled (removed pretty_dio_logger)

    return dio;
  }

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
      
      // Force AuthCubit to emit AuthUnauthenticated and redirect to Login
      if (GetIt.instance.isRegistered<AuthCubit>()) {
        GetIt.instance<AuthCubit>().forceLogout();
      }
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
