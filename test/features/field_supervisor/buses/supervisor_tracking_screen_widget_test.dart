import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_services/config/theme/app_theme.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/presentation/screens/supervisor_tracking_screen.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse implements HttpClientResponse {
  static final _transparentImage = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
    0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
    0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ]);

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDioAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) return handler!(options);
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': []}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();

  late _FakeDioAdapter adapter;
  late Dio dio;
  late AppLocalizations l10n;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'USER_ID': '101', 'USER_TOKEN': 'dummy_token'});
    prefs = await SharedPreferences.getInstance();
    if (GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.unregister<SharedPreferences>();
    }
    GetIt.I.registerSingleton<SharedPreferences>(prefs);

    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    adapter = _FakeDioAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://test.msaratwasel.com/api/'));
    dio.httpClientAdapter = adapter;
    ApiClient.testDio = dio;
  });

  tearDown(() {
    ApiClient.testDio = null;
  });

  Widget buildTestWidget({ThemeData? theme, int busId = 15}) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme ?? AppTheme.light,
      home: SupervisorTrackingScreen(busId: busId),
    );
  }

  final mockPassengersPayload = {
    'bus': {
      'trip_type': 'morning',
      'bus_number': 'BUS-15',
      'has_active_trip': true,
      'school_lat': 23.5880,
      'school_lng': 58.3829,
    },
    'passengers': [
      {
        'id': 101,
        'name': 'أحمد الهنائي',
        'parentName': 'خالد الهنائي',
        'latitude': 23.6000,
        'longitude': 58.3900,
        'isOnBus': false,
        'status': 'pending',
      },
      {
        'id': 102,
        'name': 'مريم البوسعيدية',
        'parentName': 'سعيد البوسعيدي',
        'latitude': 23.6100,
        'longitude': 58.4000,
        'isOnBus': true,
        'status': 'boarded',
      },
      {
        'id': 103,
        'name': 'يحيى الرواحي',
        'parentName': 'سالم الرواحي',
        'latitude': 23.6200,
        'longitude': 58.4100,
        'isAbsent': true,
        'status': 'absent',
      },
    ],
  };

  final mockLiveLocationPayload = {
    'success': true,
    'data': {
      'latitude': 23.5950,
      'longitude': 23.5950,
      'speed': 42.5,
      'heading': 90.0,
    },
  };

  group('SupervisorTrackingScreen Comprehensive Tests', () {
    testWidgets('1. Shows error screen with back button when passengers API fails', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'الحافلة غير مصرح بها'}),
          403,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('تنبيه الصلاحية والمتابعة'), findsOneWidget);
      expect(find.text('رجوع'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('2. Loaded state renders tracking pills, speech bubble, and stats bar in Map Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode(mockPassengersPayload),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('live-location')) {
          return ResponseBody.fromString(
            jsonEncode(mockLiveLocationPayload),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Top status
      expect(find.text('في الطريق'), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);

      // Speech bubble
      expect(find.text('النقطة القادمة'), findsOneWidget);
      expect(find.text('أحمد الهنائي'), findsOneWidget);

      // Bottom Tracking Info Card
      expect(find.text('الحافلة BUS-15'), findsOneWidget);
      expect(find.text('المتبقي'), findsOneWidget);
      expect(find.text('في الحافلة'), findsOneWidget);
      expect(find.text('الغياب'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Displays inactive trip warning banner when has_active_trip is false', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final inactivePayload = {
        'bus': {
          'trip_type': 'morning',
          'bus_number': 'BUS-15',
          'has_active_trip': false,
        },
        'passengers': [],
      };

      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode(inactivePayload),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('لا توجد رحلة نشطة حالياً لهذا الباص'), findsOneWidget);
      expect(find.text('الموقع المعروض هو آخر موقع تم تسجيله للحافلة.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('4. Toggles between Map Mode and Student List Mode and renders student details', (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode(mockPassengersPayload),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('live-location')) {
          return ResponseBody.fromString(
            jsonEncode(mockLiveLocationPayload),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Student List Mode button in bottom bar
      final studentListToggle = find.byIcon(Icons.format_list_bulleted_rounded);
      expect(studentListToggle, findsOneWidget);
      await tester.tap(studentListToggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header for student list should appear
      expect(find.text('حالة حضور الطلاب'), findsOneWidget);

      // Verify students and statuses
      expect(find.text('أحمد الهنائي'), findsOneWidget);
      expect(find.text('في الانتظار'), findsOneWidget);

      expect(find.text('مريم البوسعيدية'), findsOneWidget);
      expect(find.text('تم الركوب'), findsOneWidget);

      expect(find.text('يحيى الرواحي'), findsOneWidget);
      expect(find.text('غائب'), findsOneWidget);

      // Tap Map Mode toggle to return
      final mapToggle = find.byIcon(Icons.route_outlined);
      expect(mapToggle, findsOneWidget);
      await tester.tap(mapToggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('حالة حضور الطلاب'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('5. Interacts with Compass and Center Location floating buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      adapter.handler = (options) {
        if (options.path.contains('passengers')) {
          return ResponseBody.fromString(
            jsonEncode(mockPassengersPayload),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('live-location')) {
          return ResponseBody.fromString(
            jsonEncode(mockLiveLocationPayload),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap compass
      final compass = find.byIcon(Icons.explore_outlined);
      expect(compass, findsOneWidget);
      await tester.tap(compass);
      await tester.pump();

      // Tap location centering button
      final locationBtn = find.byIcon(Icons.my_location_rounded);
      expect(locationBtn, findsOneWidget);
      await tester.tap(locationBtn);
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
