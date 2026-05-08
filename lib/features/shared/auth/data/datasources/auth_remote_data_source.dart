import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<String> updateAvatar({required String imagePath});

  Future<void> updateProfile({
    required String phone,
    required String email,
    String? address,
    double? latitude,
    double? longitude,
  });
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
          'fcm_token': ?fcmToken,
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
        'avatar': userJson['image_url'] ?? userJson['avatar'],
        'bus_id': userJson['bus_id'],
        'email': userJson['email'],
        'phone': userJson['phone'],
        'national_id': userJson['national_id'],
        'school_name': userJson['school_name'],
        'bus': userJson['bus'],
      });
    } on DioException catch (e) {
      // خطأ من السيرفر (مثلاً 422 Validation Error)
      final serverMessage =
          e.response?.data?['message'] ??
          e.response?.data?['errors']?['national_id']?.first ??
          'فشل تسجيل الدخول. تحقق من بياناتك.';
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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'فشل تغيير كلمة السر';
      throw Exception(message);
    }
  }

  @override
  Future<String> updateAvatar({required String imagePath}) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imagePath,
          filename: 'avatar.jpg',
        ),
      });
      final response = await _dio.post('/auth/profile/avatar', data: formData);
      return response.data['image_url'] ?? '';
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'فشل تحديث الصورة');
    }
  }

  @override
  Future<void> updateProfile({
    required String phone,
    required String email,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final Map<String, dynamic> data = {'phone': phone, 'email': email};
      if (address != null) data['address'] = address;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;

      await _dio.post('/auth/profile/update', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'فشل تحديث البيانات');
    }
  }
}
