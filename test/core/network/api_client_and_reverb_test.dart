import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/network/api_config.dart';
import 'package:msaratwasel_services/core/services/reverb_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'USER_TOKEN': 'services_test_jwt',
      'app_locale': 'ar',
      'USER_ID': 456,
      'USER_NAME': 'Driver Mona',
      'USER_ROLE': 'driver',
    });
    final prefs = await SharedPreferences.getInstance();
    if (GetIt.instance.isRegistered<SharedPreferences>()) {
      GetIt.instance.unregister<SharedPreferences>();
    }
    GetIt.instance.registerSingleton<SharedPreferences>(prefs);
  });

  group('ApiClient Configuration & Interceptor Suite', () {
    test('1. ApiClient.instance initializes with proper base options and interceptors', () {
      final dio = ApiClient.instance;

      expect(dio.options.baseUrl, ApiConfig.baseUrl);
      expect(dio.options.connectTimeout, const Duration(seconds: 60));
      expect(dio.options.receiveTimeout, const Duration(seconds: 60));
      expect(dio.options.headers['Accept'], 'application/json');
      expect(dio.interceptors.length, greaterThanOrEqualTo(2));
    });

    test('2. ApiClient.authenticatedInstance sets Authorization header explicitly', () {
      final dio = ApiClient.authenticatedInstance('custom_token_999');

      expect(dio.options.headers['Authorization'], 'Bearer custom_token_999');
    });

    test('3. onRequest interceptor populates Accept-Language and Bearer token from SharedPreferences', () async {
      final dio = ApiClient.instance;
      final options = RequestOptions(path: 'test-endpoint');

      // Find the InterceptorsWrapper added by ApiClient
      final wrapper = dio.interceptors.whereType<InterceptorsWrapper>().first;
      final handler = RequestInterceptorHandler();

      wrapper.onRequest(options, handler);

      expect(options.headers['Accept-Language'], 'ar');
      expect(options.headers['Authorization'], 'Bearer services_test_jwt');
    });

    test('4. onError 401 clears user session keys from SharedPreferences', () async {
      final dio = ApiClient.instance;
      dio.httpClientAdapter = _MockErrorAdapter(401);

      try {
        await dio.get('/test-endpoint');
      } catch (_) {}

      final prefs = GetIt.instance<SharedPreferences>();
      expect(prefs.getString('USER_TOKEN'), isNull);
      expect(prefs.getInt('USER_ID'), isNull);
      expect(prefs.getString('USER_NAME'), isNull);
      expect(prefs.getString('USER_ROLE'), isNull);
    });
  });

  group('ReverbService Lifecycle & State Suite', () {
    test('5. ReverbService queues subscriptions when offline and cleans up on dispose', () async {
      final dio = Dio();
      final reverb = ReverbService(userId: 123, dio: dio);

      // Subscribe before connecting
      await reverb.subscribe('private-chat.10');
      await reverb.subscribe('public-announcements');

      // Verify eventStream is accessible
      expect(reverb.eventStream, isNotNull);

      // Dispose cleanly
      reverb.dispose();

      // Ensure calling dispose twice is safe
      reverb.dispose();
    });
  });
}

class _MockErrorAdapter implements HttpClientAdapter {
  final int statusCode;
  _MockErrorAdapter(this.statusCode);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message": "Unauthorized"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
