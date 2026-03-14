// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ApiClient - Wasel Services App
// **************************************************************************

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiClient {
  static Dio get instance {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
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
            // Fetch token from SharedPreferences via GetIt
            final prefs = GetIt.instance<SharedPreferences>();
            final token = prefs.getString('USER_TOKEN');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            // Silent failure if GetIt is not yet ready
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );

    return dio;
  }

  /// إنشاء instance مع token للـ endpoints المحمية
  static Dio authenticatedInstance(String token) {
    final dio = instance;
    dio.options.headers['Authorization'] = 'Bearer $token';
    return dio;
  }
}
