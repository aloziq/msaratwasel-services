import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:msaratwasel_services/core/services/direction_service.dart';
import 'package:msaratwasel_services/core/utils/device_utils.dart';
import 'package:msaratwasel_services/core/utils/gps_security_helper.dart';

class FakePolylinePoints implements PolylinePoints {
  PolylineResult? mockResult;
  Exception? exceptionToThrow;
  int callCount = 0;

  @override
  String get apiKey => 'test_key';

  @override
  Future<PolylineResult> getRouteBetweenCoordinates({
    required PolylineRequest request,
    Duration? timeout,
  }) async {
    callCount++;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return mockResult ??
        PolylineResult(
          status: 'OK',
          points: [
            PointLatLng(23.5880, 58.3829),
            PointLatLng(23.5900, 58.3900),
          ],
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDeviceInfoPlugin implements DeviceInfoPlugin {
  AndroidDeviceInfo? mockAndroid;
  IosDeviceInfo? mockIos;
  WebBrowserInfo? mockWeb;
  Exception? exceptionToThrow;

  @override
  Future<AndroidDeviceInfo> get androidInfo async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return mockAndroid ??
        AndroidDeviceInfo.fromMap({
          'manufacturer': 'Samsung',
          'model': 'Galaxy S24',
          'id': 'android_id_123',
          'version': {'release': '14'},
        });
  }

  @override
  Future<IosDeviceInfo> get iosInfo async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return mockIos ??
        IosDeviceInfo.fromMap({
          'name': 'iPhone 15 Pro',
          'model': 'iPhone',
          'identifierForVendor': 'vendor_id_abc',
          'systemVersion': '17.2',
        });
  }

  @override
  Future<WebBrowserInfo> get webBrowserInfo async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return mockWeb ??
        WebBrowserInfo.fromMap({
          'browserName': 'chrome',
          'userAgent': 'Mozilla/5.0 Test WebAgent',
        });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');
  const MethodChannel permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');

  bool mockLocationServiceEnabled = true;
  int mockLocationPermissionStatus = 1; // 1 = granted, 0 = denied, 4 = permanentlyDenied
  int mockLocationAlwaysPermissionStatus = 1;

  setUp(() {
    mockLocationServiceEnabled = true;
    mockLocationPermissionStatus = 1;
    mockLocationAlwaysPermissionStatus = 1;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, (MethodCall call) async {
      if (call.method == 'isLocationServiceEnabled') {
        return mockLocationServiceEnabled;
      }
      if (call.method == 'openLocationSettings') {
        return true;
      }
      if (call.method == 'openAppSettings') {
        return true;
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (MethodCall call) async {
      print('PERMISSION CALL: ${call.method}, args: ${call.arguments}');
      if (call.method == 'checkPermissionStatus') {
        final permission = call.arguments as int;
        if (permission == 4 || permission == 5) {
          return mockLocationAlwaysPermissionStatus;
        }
        return mockLocationPermissionStatus;
      }
      if (call.method == 'requestPermissions') {
        final List<dynamic> permissions = call.arguments as List<dynamic>;
        final map = <int, int>{};
        for (final p in permissions) {
          final pInt = p as int;
          if (pInt == 4 || pInt == 5) {
            map[pInt] = mockLocationAlwaysPermissionStatus;
          } else {
            map[pInt] = mockLocationPermissionStatus;
          }
        }
        return map;
      }
      if (call.method == 'openAppSettings') {
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
    DeviceUtils.testDeviceInfo = null;
  });

  Widget createTestWidget({
    required Widget Function(BuildContext) builder,
    Locale locale = const Locale('ar'),
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(builder: builder),
      ),
    );
  }

  group('1. DirectionService Unit Tests', () {
    test('getRouteBetweenCoordinates fetches and caches polyline points successfully', () async {
      final fakePolyline = FakePolylinePoints();
      final service = DirectionService(polylinePoints: fakePolyline);

      const origin = LatLng(23.5880, 58.3829);
      const destination = LatLng(23.6000, 58.4000);

      final points1 = await service.getRouteBetweenCoordinates(origin, destination);
      expect(points1.length, 2);
      expect(points1.first.latitude, 23.5880);
      expect(points1.first.longitude, 58.3829);
      expect(fakePolyline.callCount, 1);

      // Second call should return from cache without invoking PolylinePoints again
      final points2 = await service.getRouteBetweenCoordinates(origin, destination);
      expect(points2.length, 2);
      expect(fakePolyline.callCount, 1);

      // clearCache should invalidate cache
      service.clearCache();
      final points3 = await service.getRouteBetweenCoordinates(origin, destination);
      expect(points3.length, 2);
      expect(fakePolyline.callCount, 2);
    });

    test('getRouteBetweenCoordinates throws Exception when points are empty', () async {
      final fakePolyline = FakePolylinePoints()
        ..mockResult = PolylineResult(
          status: 'ZERO_RESULTS',
          errorMessage: 'No route found',
          points: [],
        );
      final service = DirectionService(polylinePoints: fakePolyline);

      expect(
        () => service.getRouteBetweenCoordinates(
          const LatLng(23.5880, 58.3829),
          const LatLng(23.6000, 58.4000),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('getRouteBetweenCoordinates wraps and rethrows unexpected exception', () async {
      final fakePolyline = FakePolylinePoints()
        ..exceptionToThrow = Exception('Network down');
      final service = DirectionService(polylinePoints: fakePolyline);

      expect(
        () => service.getRouteBetweenCoordinates(
          const LatLng(23.5880, 58.3829),
          const LatLng(23.6000, 58.4000),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('2. DeviceUtils Unit Tests', () {
    test('getDeviceName returns formatted device info for Android/iOS', () async {
      final fakeInfo = FakeDeviceInfoPlugin();
      DeviceUtils.testDeviceInfo = fakeInfo;

      final name = await DeviceUtils.getDeviceName();
      expect(name, isNotEmpty);
      if (Platform.isAndroid) {
        expect(name, 'Samsung Galaxy S24 (android_id_123)');
      } else if (Platform.isIOS) {
        expect(name, 'iPhone 15 Pro (iPhone)');
      } else {
        expect(name, Platform.operatingSystem);
      }
    });

    test('getDeviceId returns platform ID or null', () async {
      final fakeInfo = FakeDeviceInfoPlugin();
      DeviceUtils.testDeviceInfo = fakeInfo;

      final id = await DeviceUtils.getDeviceId();
      if (Platform.isAndroid) {
        expect(id, 'android_id_123');
      } else if (Platform.isIOS) {
        expect(id, 'vendor_id_abc');
      } else {
        expect(id, isNull);
      }
    });

    test('DeviceUtils handles exceptions gracefully', () async {
      final fakeInfo = FakeDeviceInfoPlugin()
        ..exceptionToThrow = Exception('Device info plugin crash');
      DeviceUtils.testDeviceInfo = fakeInfo;

      final name = await DeviceUtils.getDeviceName();
      if (Platform.isAndroid || Platform.isIOS) {
        expect(name, 'Unknown Device');
      }

      final id = await DeviceUtils.getDeviceId();
      if (Platform.isAndroid || Platform.isIOS) {
        expect(id, isNull);
      }
    });
  });

  group('3. GpsSecurityHelper Widget Tests', () {
    testWidgets('checkLocationServices: displays disabled GPS dialog and handles cancel/settings (Arabic)', (tester) async {
      mockLocationServiceEnabled = false;

      bool? checkResult;
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('ar'),
          builder: (context) => ElevatedButton(
            onPressed: () async {
              checkResult = await GpsSecurityHelper.checkLocationServices(context);
            },
            child: const Text('Check'),
          ),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('خدمة الموقع مغلقة'), findsOneWidget);
      expect(find.byIcon(Icons.gps_off_rounded), findsOneWidget);
      expect(find.text('فتح الإعدادات'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);

      // Tap settings button
      await tester.tap(find.text('فتح الإعدادات'));
      await tester.pumpAndSettle();

      expect(checkResult, isFalse);
    });

    testWidgets('checkLocationServices: displays disabled GPS dialog in English and handles Cancel', (tester) async {
      mockLocationServiceEnabled = false;

      bool? checkResult;
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('en'),
          builder: (context) => ElevatedButton(
            onPressed: () async {
              checkResult = await GpsSecurityHelper.checkLocationServices(context);
            },
            child: const Text('Check'),
          ),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('GPS Service Disabled'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(checkResult, isFalse);
    });

    testWidgets('checkLocationServices: handles permanently denied permission dialog', (tester) async {
      mockLocationServiceEnabled = true;
      mockLocationPermissionStatus = 4; // permanentlyDenied

      bool? checkResult;
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('ar'),
          builder: (context) => ElevatedButton(
            onPressed: () async {
              checkResult = await GpsSecurityHelper.checkLocationServices(context);
            },
            child: const Text('Check'),
          ),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('إذن الموقع مطلوب'), findsOneWidget);
      expect(find.byIcon(Icons.security_rounded), findsOneWidget);

      // Tap open settings
      await tester.tap(find.text('فتح الإعدادات'));
      await tester.pumpAndSettle();

      expect(checkResult, isFalse);
    });

    testWidgets('checkLocationServices: permanently denied dialog in English', (tester) async {
      mockLocationServiceEnabled = true;
      mockLocationPermissionStatus = 4; // permanentlyDenied

      bool? checkResult;
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('en'),
          builder: (context) => ElevatedButton(
            onPressed: () async {
              checkResult = await GpsSecurityHelper.checkLocationServices(context);
            },
            child: const Text('Check'),
          ),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('Location Permission Required'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(checkResult, isFalse);
    });

    testWidgets('checkLocationServices: shows SnackBar when permission is not granted', (tester) async {
      mockLocationServiceEnabled = true;
      mockLocationPermissionStatus = 0; // denied

      bool? checkResult;
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('ar'),
          builder: (context) => ElevatedButton(
            onPressed: () async {
              checkResult = await GpsSecurityHelper.checkLocationServices(context);
            },
            child: const Text('Check'),
          ),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('يجب منح إذن الوصول إلى الموقع للوصول للرحلة.'), findsOneWidget);
      expect(checkResult, isFalse);
    });

    testWidgets('checkLocationServices: returns true when GPS and permission are granted', (tester) async {
      mockLocationServiceEnabled = true;
      mockLocationPermissionStatus = 1; // granted

      bool? checkResult;
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('ar'),
          builder: (context) => ElevatedButton(
            onPressed: () async {
              checkResult = await GpsSecurityHelper.checkLocationServices(context);
            },
            child: const Text('Check'),
          ),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(checkResult, isTrue);
    });

    testWidgets('requestBackgroundLocationWithDisclosure: returns true immediately if already granted', (tester) async {
      mockLocationAlwaysPermissionStatus = 1; // granted

      bool? result;
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('ar'),
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await GpsSecurityHelper.requestBackgroundLocationWithDisclosure(context);
            },
            child: const Text('RequestBG'),
          ),
        ),
      );

      await tester.tap(find.text('RequestBG'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('requestBackgroundLocationWithDisclosure: shows disclosure and handles user Deny (Arabic)', (tester) async {
      mockLocationAlwaysPermissionStatus = 0; // denied

      bool? result;
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('ar'),
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await GpsSecurityHelper.requestBackgroundLocationWithDisclosure(context);
            },
            child: const Text('RequestBG'),
          ),
        ),
      );

      await tester.tap(find.text('RequestBG'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('استخدام الموقع في الخلفية'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
      expect(find.text('رفض'), findsOneWidget);
      expect(find.text('موافق'), findsOneWidget);

      await tester.tap(find.text('رفض'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('requestBackgroundLocationWithDisclosure: shows disclosure in English and handles Accept', (tester) async {
      mockLocationAlwaysPermissionStatus = 0; // initially denied

      bool? result;
      await tester.pumpWidget(
        createTestWidget(
          locale: const Locale('en'),
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await GpsSecurityHelper.requestBackgroundLocationWithDisclosure(context);
            },
            child: const Text('RequestBG'),
          ),
        ),
      );

      await tester.tap(find.text('RequestBG'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Background Location Usage'), findsOneWidget);
      expect(find.text('Deny'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);

      // When user accepts, simulate permission request being granted
      mockLocationAlwaysPermissionStatus = 1;
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
