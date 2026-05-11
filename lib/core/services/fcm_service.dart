import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:go_router/go_router.dart';
import '../../features/shared/auth/presentation/cubit/auth_cubit.dart';
import '../../features/shared/auth/presentation/cubit/auth_state.dart';
import '../../features/shared/auth/domain/entities/user_entity.dart';
import '../../config/routes/app_routes.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  
  // Create local notification in background
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(),
  );

  await localNotifications.initialize(initializationSettings);

  final notification = message.notification;
  final data = message.data;
  final String title = notification?.title ?? data['title'] ?? 'رسالة جديدة';
  final String body = notification?.body ?? data['body'] ?? data['message'] ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    const String channelId = 'msarat_wasel_high_importance_v3';
    const String channelName = 'تنبيهات خدمات مسارات';

    await localNotifications.show(
      message.messageId.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }
}

@lazySingleton
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AuthCubit _authCubit;
  GoRouter? _router;
  
  // Track processed notification IDs to prevent duplicates
  final Set<String> _processedIds = {};
  final Set<String> _processedCorrelationIds = {};

  // Channel Constants
  static const String _channelId = 'msarat_wasel_high_importance_v3';
  static const String _channelName = 'تنبيهات خدمات مسارات';
  static const String _channelDesc = 'تستخدم لإرسال تنبيهات الرحلات والرسائل الهامة للعمليات';

  FcmService(this._authCubit);

  void setRouter(GoRouter router) {
    _router = router;
    debugPrint('🔔 [FCM] Router has been set');
  }

  Future<void> init() async {
    // 1. Background Message Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request FCM permissions
    await requestPermission();

    // 2b. Enable iOS foreground notification banners (CRITICAL for iOS popup)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Initialize Local Notifications for foreground support
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle tap on local notification
        if (response.payload != null) {
          // Add logic if needed
        }
      },
    );

    // 3b. Request iOS local notification permissions explicitly
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // 4. Create Android Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. iOS APNS Token Retry Logic
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('🍎 [FCM] iOS detected: waiting for APNS token...');
      String? apnsToken;
      int retryCount = 0;
      while (apnsToken == null && retryCount < 10) {
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('⏳ [FCM] APNS token not ready, retrying ($retryCount/10)...');
          await Future.delayed(const Duration(milliseconds: 500));
          retryCount++;
        }
      }
      if (apnsToken != null) {
        debugPrint('✅ [FCM] APNS token ready: $apnsToken');
      }
    }

    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 [FCM] Message received in foreground: ${message.notification?.title ?? "Data Message"}');
      
      final data = message.data;
      final correlationId = data['correlation_id']?.toString();
      final notificationId = data['notification_id']?.toString() ?? message.messageId;

      // Deduplication
      if (correlationId != null && _processedCorrelationIds.contains(correlationId)) {
        debugPrint('⚠️ [FCM] Skipping duplicate message via CID: $correlationId');
        return;
      }
      if (notificationId != null && _processedIds.contains(notificationId)) {
        debugPrint('⚠️ [FCM] Skipping duplicate message via ID: $notificationId');
        return;
      }

      if (notificationId != null) _processedIds.add(notificationId);
      if (correlationId != null) _processedCorrelationIds.add(correlationId);

      // Show notification if it has either notification OR data content
      if (message.notification != null || data.isNotEmpty) {
        _showLocalNotification(message);
      }
    });

    // 7. Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 8. Handle initial message
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 [FCM] App opened from terminated state via notification');
        _handleNotificationTap(message);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    
    // Fallback title/body from data if notification is null
    final String title = notification?.title ?? data['title'] ?? 'رسالة جديدة';
    final String body = notification?.body ?? data['body'] ?? data['message'] ?? '';

    final notificationId = int.tryParse(data['notification_id']?.toString() ?? '') ?? 
                           message.messageId.hashCode;

    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
          // Use default sound explicitly
          sound: null, 
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 [FCM] Notification tapped: ${message.data}');
    final data = message.data;
    final type = data['type']?.toString();
    
    // Check for chat/message types
    if (type == 'chat' || type == 'supervisorMessage' || data.containsKey('conversation_id')) {
      final id = data['conversation_id']?.toString() ?? data['id']?.toString();
      final name = data['sender_name']?.toString() ?? data['name']?.toString();
      final receiverId = data['sender_id']?.toString() ?? data['receiverId']?.toString();

      if (id != null && _router != null) {
        debugPrint('🚀 [FCM] Navigating to chat screen for conversation: $id');
        _router?.pushNamed('messages', extra: {
          'id': id,
          'name': name,
          'receiverId': receiverId,
        });
      }
    } 
    // Handle Address Change
    else if (type == 'address_change') {
      final authState = _authCubit.state;
      if (authState is AuthAuthenticated && _router != null) {
        if (authState.user.role == UserRole.driver) {
          _router?.push(AppRoutes.driverRoute);
        } else if (authState.user.role == UserRole.assistant) {
          _router?.push(AppRoutes.busMap);
        }
      }
    }
    // Handle Location Request
    else if (type == 'location_request') {
      final authState = _authCubit.state;
      if (authState is AuthAuthenticated && _router != null) {
        if (authState.user.role == UserRole.fieldSupervisor) {
          _router?.push(AppRoutes.supervisorHome);
        }
      }
    }
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }
}
