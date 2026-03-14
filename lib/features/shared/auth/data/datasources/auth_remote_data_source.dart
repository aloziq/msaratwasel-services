import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/services/fcm_service.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String nationalId,
    required String password,
  });

  Future<void> logout({required String token});
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  late final Dio _dio;

  AuthRemoteDataSourceImpl() {
    _dio = ApiClient.instance;
  }

  @override
  Future<UserModel> login({
    required String nationalId,
    required String password,
  }) async {
    try {
      final fcmService = getIt<FcmService>();
      final fcmToken = await fcmService.getToken();

      final response = await _dio.post(
        '/auth/login',
        data: {
          'national_id': nationalId,
          'password': password,
          'device_name': 'device_1',
          'app_context': 'services',
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
      );

      final data = response.data;

      // استخراج بيانات المستخدم من الـ response
      // Laravel يرجع البيانات بهيكلين: data.user أو user مباشرةً
      final userJson = data['data']?['user'] ?? data['user'];
      final token = data['data']?['token'] ?? data['token'];

      if (userJson == null || token == null) {
        throw Exception('الاستجابة من السيرفر غير مكتملة');
      }

      return UserModel.fromJson({
        'id': userJson['id'].toString(),
        'name': userJson['name'],
        'role': userJson['role'],
        'token': token,
        'avatar': userJson['avatar'],
        'bus_id': userJson['bus_id'],
      });
    } on DioException catch (e) {
      // خطأ من السيرفر (مثلاً 422 Validation Error)
      final serverMessage = e.response?.data?['message']
          ?? e.response?.data?['errors']?['national_id']?.first
          ?? 'فشل تسجيل الدخول. تحقق من بياناتك.';
      throw Exception(serverMessage);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<void> logout({required String token}) async {
    try {
      final authenticatedDio = ApiClient.authenticatedInstance(token);
      await authenticatedDio.post('/auth/logout');
    } catch (_) {
      // نتجاهل الخطأ في حالة logout - نمسح التوكن محلياً على أي حال
    }
  }
}
