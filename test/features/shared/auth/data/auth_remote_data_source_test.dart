import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/services/fcm_service.dart';
import 'package:msaratwasel_services/features/shared/auth/data/datasources/auth_remote_data_source.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) return handler!(options);
    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeFcmService implements FcmService {
  String? tokenToReturn = 'fake_fcm_token_123';

  @override
  Future<String?> getToken() async => tokenToReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHttpAdapter adapter;
  late Dio testDio;
  late _FakeFcmService fakeFcmService;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    adapter = _FakeHttpAdapter();
    testDio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
    testDio.httpClientAdapter = adapter;
    ApiClient.testDio = testDio;

    fakeFcmService = _FakeFcmService();
    if (GetIt.I.isRegistered<FcmService>()) {
      GetIt.I.unregister<FcmService>();
    }
    GetIt.I.registerSingleton<FcmService>(fakeFcmService);

    dataSource = AuthRemoteDataSourceImpl();
  });

  tearDown(() {
    ApiClient.testDio = null;
    if (GetIt.I.isRegistered<FcmService>()) {
      GetIt.I.unregister<FcmService>();
    }
  });

  group('AuthRemoteDataSourceImpl - Login', () {
    test('1. Successful login with nested data.user and data.token', () async {
      adapter.handler = (options) {
        expect(options.path, '/auth/login');
        expect(options.method, 'POST');
        final data = options.data as Map<String, dynamic>;
        expect(data['national_id'], '1234567890');
        expect(data['password'], 'secret123');
        expect(data['fcm_token'], 'fake_fcm_token_123');

        return ResponseBody.fromString(
          jsonEncode({
            'status': 'success',
            'data': {
              'user': {
                'id': 42,
                'name': 'أحمد علي',
                'name_en': 'Ahmed Ali',
                'role': 'driver',
                'email': 'driver@example.com',
                'phone': '0501112233',
                'national_id': '1234567890',
                'avatar': 'https://example.com/avatar.png',
                'bus_id': 12,
                'school_name': 'مدرسة النور',
              },
              'token': 'bearer_token_abc_123',
            }
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final user = await dataSource.login(
        nationalId: '1234567890',
        password: 'secret123',
      );

      expect(user.id, '42');
      expect(user.name, 'أحمد علي');
      expect(user.role, UserRole.driver);
      expect(user.token, 'bearer_token_abc_123');
      expect(user.busId, 12);
    });

    test('2. Successful login with flat user and token keys', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'user': {
              'id': 99,
              'name': 'سارة المشرفة',
              'role': 'assistant',
              'email': 'assistant@example.com',
              'phone': '0509998877',
              'national_id': '9876543210',
              'image_url': 'https://example.com/sara.png',
            },
            'token': 'token_flat_xyz',
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final user = await dataSource.login(
        nationalId: '9876543210',
        password: 'pass',
      );

      expect(user.id, '99');
      expect(user.name, 'سارة المشرفة');
      expect(user.role, UserRole.assistant);
      expect(user.token, 'token_flat_xyz');
      expect(user.avatar, 'https://example.com/sara.png');
    });

    test('3. Throws when response is missing user or token', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'status': 'ok'}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      expect(
        () => dataSource.login(nationalId: '123', password: '456'),
        throwsA(predicate((e) => e.toString().contains('الاستجابة من السيرفر غير مكتملة'))),
      );
    });

    test('4. Handles DioException with server message', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'بيانات الاعتماد غير صحيحة'}),
          401,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      expect(
        () => dataSource.login(nationalId: '123', password: '456'),
        throwsA(predicate((e) => e.toString().contains('بيانات الاعتماد غير صحيحة'))),
      );
    });

    test('5. Handles DioException with validation errors for national_id', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'errors': {
              'national_id': ['رقم الهوية غير مسجل'],
            }
          }),
          422,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      expect(
        () => dataSource.login(nationalId: '123', password: '456'),
        throwsA(predicate((e) => e.toString().contains('رقم الهوية غير مسجل'))),
      );
    });

    test('6. Handles DioException with fallback message', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({}),
          500,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      expect(
        () => dataSource.login(nationalId: '123', password: '456'),
        throwsA(predicate((e) => e.toString().contains('فشل تسجيل الدخول. تحقق من بياناتك.'))),
      );
    });
  });

  group('AuthRemoteDataSourceImpl - Logout', () {
    test('7. Logout sends post request to /auth/logout with fcm_token and ignores errors', () async {
      bool called = false;
      adapter.handler = (options) {
        if (options.path.contains('/auth/logout')) {
          called = true;
          expect(options.data['fcm_token'], 'fcm_to_delete');
          return ResponseBody.fromString(
            jsonEncode({'success': true}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      await dataSource.logout(token: 'active_token', fcmToken: 'fcm_to_delete');
      expect(called, isTrue);

      // Verify it catches errors without rethrowing
      adapter.handler = (options) => throw DioException(requestOptions: options);
      await expectLater(
        dataSource.logout(token: 'active_token'),
        completes,
      );
    });
  });

  group('AuthRemoteDataSourceImpl - Profile & Password', () {
    test('8. changePassword success and DioException', () async {
      bool changed = false;
      adapter.handler = (options) {
        if (options.path.contains('/auth/change-password')) {
          changed = true;
          final d = options.data as Map<String, dynamic>;
          expect(d['current_password'], 'oldPass');
          expect(d['new_password'], 'newPass');
          expect(d['new_password_confirmation'], 'newPass');
          return ResponseBody.fromString(jsonEncode({'message': 'تم التغيير'}), 200);
        }
        return ResponseBody.fromString('', 404);
      };

      await dataSource.changePassword(
        currentPassword: 'oldPass',
        newPassword: 'newPass',
        confirmPassword: 'newPass',
      );
      expect(changed, isTrue);

      // Failure
      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({'message': 'كلمة المرور الحالية غير مطابقة'}),
            400,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
      expect(
        () => dataSource.changePassword(
          currentPassword: 'wrong',
          newPassword: 'new',
          confirmPassword: 'new',
        ),
        throwsA(predicate((e) => e.toString().contains('كلمة المرور الحالية غير مطابقة'))),
      );
    });

    test('9. updateProfile success and failure', () async {
      bool updated = false;
      adapter.handler = (options) {
        if (options.path.contains('/auth/profile/update')) {
          updated = true;
          final d = options.data as Map<String, dynamic>;
          expect(d['phone'], '0501234567');
          expect(d['email'], 'test@profile.com');
          expect(d['address'], 'شارع الملك فهد');
          expect(d['latitude'], 24.7136);
          expect(d['longitude'], 46.6753);
          return ResponseBody.fromString(jsonEncode({'success': true}), 200);
        }
        return ResponseBody.fromString('', 404);
      };

      await dataSource.updateProfile(
        phone: '0501234567',
        email: 'test@profile.com',
        address: 'شارع الملك فهد',
        latitude: 24.7136,
        longitude: 46.6753,
      );
      expect(updated, isTrue);

      // Failure
      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({'message': 'رقم الهاتف مستخدم بالفعل'}),
            422,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
      expect(
        () => dataSource.updateProfile(phone: '050', email: 'e@mail.com'),
        throwsA(predicate((e) => e.toString().contains('رقم الهاتف مستخدم بالفعل'))),
      );
    });

    test('10. updateLanguage success and failure', () async {
      bool languageUpdated = false;
      adapter.handler = (options) {
        if (options.path.contains('/auth/profile/language')) {
          languageUpdated = true;
          expect(options.data['language'], 'en');
          return ResponseBody.fromString(jsonEncode({'success': true}), 200);
        }
        return ResponseBody.fromString('', 404);
      };

      await dataSource.updateLanguage('en');
      expect(languageUpdated, isTrue);

      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({'message': 'اللغة غير مدعومة'}),
            400,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
      expect(
        () => dataSource.updateLanguage('fr'),
        throwsA(predicate((e) => e.toString().contains('اللغة غير مدعومة'))),
      );
    });

    test('11. fetchUserProfile success and failure', () async {
      adapter.handler = (options) {
        if (options.path.contains('/auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'id': 77,
                'name': 'خالد المشرف',
                'role': 'field_supervisor',
                'email': 'supervisor@test.com',
                'phone': '0598765432',
                'national_id': '1020304050',
              }
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      final profile = await dataSource.fetchUserProfile();
      expect(profile.id, '77');
      expect(profile.name, 'خالد المشرف');
      expect(profile.role, UserRole.fieldSupervisor);

      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({'message': 'المستخدم غير موجود'}),
            404,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
      expect(
        () => dataSource.fetchUserProfile(),
        throwsA(predicate((e) => e.toString().contains('المستخدم غير موجود'))),
      );
    });

    test('12. updateFcmToken sends post and catches error gracefully', () async {
      bool tokenSent = false;
      adapter.handler = (options) {
        if (options.path.contains('/auth/fcm-token')) {
          tokenSent = true;
          expect(options.data['fcm_token'], 'new_fcm_abc');
          return ResponseBody.fromString(jsonEncode({'success': true}), 200);
        }
        return ResponseBody.fromString('', 404);
      };

      await dataSource.updateFcmToken('new_fcm_abc');
      expect(tokenSent, isTrue);

      // Test catch block
      adapter.handler = (options) => throw DioException(requestOptions: options);
      await expectLater(dataSource.updateFcmToken('bad_token'), completes);
    });

    test('13. resetPassword success and failure', () async {
      adapter.handler = (options) {
        if (options.path.contains('/auth/forgot-password')) {
          return ResponseBody.fromString(
            jsonEncode({'message': 'تم إرسال رمز التحقق إلى هاتفك'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      final msg = await dataSource.resetPassword(nationalId: '1020304050');
      expect(msg, 'تم إرسال رمز التحقق إلى هاتفك');

      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({
              'errors': {
                'national_id': ['رقم الهوية الوطنية غير مسجل'],
              }
            }),
            422,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
      expect(
        () => dataSource.resetPassword(nationalId: '0000000000'),
        throwsA(predicate((e) => e.toString().contains('رقم الهوية الوطنية غير مسجل'))),
      );
    });

    test('14. updateAvatar with file upload success and failure', () async {
      final tempDir = Directory.systemTemp.createTempSync('avatar_test');
      final tempFile = File('${tempDir.path}/test_avatar.jpg');
      tempFile.writeAsBytesSync([1, 2, 3, 4]);

      try {
        adapter.handler = (options) {
          if (options.path.contains('/auth/profile/avatar')) {
            expect(options.data, isA<FormData>());
            return ResponseBody.fromString(
              jsonEncode({
                'success': true,
                'image_url': 'https://cdn.test.com/avatars/new_avatar.jpg',
              }),
              200,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
          return ResponseBody.fromString('', 404);
        };

        final url = await dataSource.updateAvatar(imagePath: tempFile.path);
        expect(url, 'https://cdn.test.com/avatars/new_avatar.jpg');

        // Failure
        adapter.handler = (options) => ResponseBody.fromString(
              jsonEncode({'message': 'حجم الصورة كبير جداً'}),
              413,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
        expect(
          () => dataSource.updateAvatar(imagePath: tempFile.path),
          throwsA(predicate((e) => e.toString().contains('حجم الصورة كبير جداً'))),
        );
      } finally {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });
  });
}
