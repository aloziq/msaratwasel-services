import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/features/driver/route/data/repositories/route_repository_impl.dart';

@pragma('vm:entry-point')
class LocationService {
  static bool _isConfigured = false;

  static Future<void> initialize() async {
    if (_isConfigured) return;
    
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_tracking', // id
      'Location Tracking', // title
      description: 'This channel is used for location tracking notifications.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (defaultTargetPlatform == TargetPlatform.android) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracking',
        initialNotificationTitle: 'تتبع الرحلة نشط',
        initialNotificationContent: 'يتم الآن مشاركة موقعك لتأمين سلامة الطلاب',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    _isConfigured = true;
    debugPrint('✅ [LocationService] Configured successfully');
  }

  static Future<void> start() async {
    await initialize(); // Ensure it's initialized before starting
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      service.startService();
      debugPrint('🚀 [LocationService] Service started');
    }
  }

  static void stop() {
    FlutterBackgroundService().invoke('stopService');
    debugPrint('🛑 [LocationService] Service stopped');
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  try {
    // Minimal dependency injection for background isolate
    final prefs = await SharedPreferences.getInstance();
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
    }

    final repository = RouteRepositoryImpl();
    DateTime? lastEmitTime;

    // Send immediate initial location update on service startup
    try {
      try {
        await prefs.reload();
      } catch (_) {}
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      await repository.updateLocation(
        latitude: initialPosition.latitude,
        longitude: initialPosition.longitude,
        heading: initialPosition.heading,
        speed: initialPosition.speed,
        accuracy: initialPosition.accuracy,
      );
      lastEmitTime = DateTime.now();
      debugPrint('🚀 [LocationService] Sent initial position update successfully');
    } catch (e) {
      debugPrint('⚠️ [LocationService] Failed to send initial position update: $e');
    }

    int simStep = 0;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((Position position) async {
      try {
        final now = DateTime.now();
        // Throttler: Do not emit more frequently than every 3 seconds
        if (lastEmitTime != null && now.difference(lastEmitTime!).inSeconds < 3) {
          return;
        }
        lastEmitTime = now;

        try {
          await prefs.reload();
        } catch (_) {}

        simStep++;
        final double finalLat = position.latitude + (simStep * 0.00015);
        final double finalLng = position.longitude + (simStep * 0.00008);

        await repository.updateLocation(
          latitude: finalLat,
          longitude: finalLng,
          heading: position.heading,
          speed: position.speed,
          accuracy: position.accuracy,
        );

        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            service.setForegroundNotificationInfo(
              title: "تتبع الموقع نشط",
              content:
                  "تم تحديث الموقع: ${finalLat.toStringAsFixed(4)}, ${finalLng.toStringAsFixed(4)}",
            );
          }
        }
      } catch (e) {
        debugPrint('Background update error: $e');
      }
    });
  } catch (e) {
    debugPrint('Background initialization error: $e');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}
