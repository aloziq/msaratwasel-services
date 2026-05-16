import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:msaratwasel_services/core/utils/active_conversation_tracker.dart';
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
  
  final data = message.data;
  final String? cid = data['correlation_id']?.toString() ?? 
                     data['notification_id']?.toString() ?? 
                     data['id']?.toString() ?? 
                     message.messageId;

  // 1. Persistent Deduplication check
  final prefs = await SharedPreferences.getInstance();
  final List<String> processedCids = prefs.getStringList('processed_fcm_cids') ?? [];
  if (cid != null && processedCids.contains(cid)) {
    debugPrint('🚫 [FCM BG] Skipping persistent duplicate (CID: $cid)');
    return;
  }
  
  // Save CID
  if (cid != null) {
    processedCids.add(cid);
    if (processedCids.length > 50) processedCids.removeAt(0);
    await prefs.setStringList('processed_fcm_cids', processedCids);
  }

  // 2. Avoid Double Notification: 
  // If notification object is present, Android/iOS OS will show it automatically.
  if (message.notification != null) {
    debugPrint('🔔 [FCM BG] OS handles UI. Skipping local show.');
    return;
  }

  // 3. Robust Content Extraction (Fallback to data fields)
  String? pick(List<dynamic> options) {
    for (final opt in options) {
      final str = opt?.toString();
      if (str != null && str.trim().isNotEmpty) return str;
    }
    return null;
  }

  final String title = pick([message.notification?.title, data['title_ar'], data['title_en'], data['title'], data['sender_name']]) ?? 'رسالة جديدة';
  final String body = pick([message.notification?.body, data['message_ar'], data['message_en'], data['message'], data['body'], data['content'], data['messagePreview']]) ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: DarwinInitializationSettings());
    await localNotifications.initialize(initializationSettings);

    String channelId = 'chat_messages';
    String channelName = 'رسائل المحادثة';
    
    await localNotifications.show(
      cid.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: json.encode(data),
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
  bool _isInitialized = false;

  // Channel Constants
  static const String _channelId = 'msarat_wasel_high_importance_v4';
  static const String _channelName = 'تنبيهات خدمات مسارات';
  static const String _channelDesc = 'تستخدم لإرسال تنبيهات الرحلات والرسائل الهامة للعمليات';

  FcmService(this._authCubit);

  void setRouter(GoRouter router) {
    _router = router;
    debugPrint('🔔 [FCM] Router has been set');
  }

  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('🔔 [FCM] FcmService already initialized, skipping...');
      return;
    }
    _isInitialized = true;

    // 1. Background Message Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request FCM permissions
    await requestPermission();

    // 2b. Disable OS foreground banners (we show them manually via _showLocalNotification for better control)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false, // 🚫 No OS banner in foreground
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
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleDataTap(data);
          } catch (e) {
            debugPrint('❌ [FCM] Error parsing local notification payload: $e');
          }
        }
      },
    );

    // 3b. Request iOS local notification permissions explicitly
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // 4. Create Android Notification Channels
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'رسائل المحادثة',
      description: 'إشعارات الرسائل الجديدة في المحادثة',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final plugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(channel);
    await plugin?.createNotificationChannel(chatChannel);

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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('🔔 [FCM] Message received in foreground: ${message.notification?.title ?? "Data Message"}');
      
      final data = message.data;
      final correlationId = _pick([data['correlation_id']]);
      final notificationId = _pick([data['notification_id'], data['id'], message.messageId]);

      final prefs = await SharedPreferences.getInstance();
      final List<String> persistentCids = prefs.getStringList('processed_fcm_cids') ?? [];

      // Check both in-memory and persistent storage
      bool isDuplicate = false;
      if (correlationId != null && (_processedCorrelationIds.contains(correlationId) || persistentCids.contains(correlationId))) {
        isDuplicate = true;
      } else if (notificationId != null && (_processedIds.contains(notificationId) || persistentCids.contains(notificationId))) {
        isDuplicate = true;
      }

      if (isDuplicate) {
        debugPrint('⚠️ [FCM] Skipping duplicate message (ID: $notificationId / CID: $correlationId)');
        return;
      }

      // Track it everywhere
      if (notificationId != null) {
        _processedIds.add(notificationId);
        if (!persistentCids.contains(notificationId)) {
          persistentCids.add(notificationId);
        }
      }
      if (correlationId != null) {
        _processedCorrelationIds.add(correlationId);
        if (!persistentCids.contains(correlationId)) {
          persistentCids.add(correlationId);
        }
      }

      // Limit persistence
      if (persistentCids.length > 50) persistentCids.removeAt(0);
      await prefs.setStringList('processed_fcm_cids', persistentCids);

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

  String? _pick(List<dynamic> options) {
    for (final opt in options) {
      final str = opt?.toString();
      if (str != null && str.trim().isNotEmpty) return str;
    }
    return null;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final data = message.data;
    final String? cid = _pick([data['correlation_id'], data['id'], data['notification_id'], message.messageId]);

    // 1. Deduplication check
    final prefs = await SharedPreferences.getInstance();
    final processedCids = prefs.getStringList('processed_fcm_cids') ?? [];
    if (cid != null && processedCids.contains(cid)) {
      debugPrint('♻️ [FCM FG] Skipping duplicate message (CID: $cid)');
      return;
    }
    
    // Save CID
    if (cid != null) {
      processedCids.add(cid);
      if (processedCids.length > 50) processedCids.removeAt(0);
      await prefs.setStringList('processed_fcm_cids', processedCids);
    }

    // 2. Suppress if active in conversation
    final type = data['type']?.toString();
    if (type == 'chat' || type == 'new_message' || type == 'chat_message' || data.containsKey('conversation_id')) {
      final convId = data['conversation_id']?.toString() ?? data['id']?.toString();
      if (convId != null && convId == ActiveConversationTracker.activeConversationId) {
        debugPrint('🔇 [FCM FG] Suppressing notification - active in conversation $convId');
        return;
      }
    }

    // 3. Content extraction with fallback
    final String title = _pick([message.notification?.title, data['title_ar'], data['title_en'], data['title'], data['sender_name']]) ?? 'رسالة جديدة';
    final String body = _pick([message.notification?.body, data['message_ar'], data['message_en'], data['message'], data['body'], data['content'], data['messagePreview']]) ?? '';

    if (title.isEmpty && body.isEmpty) return;

    final notificationId = cid.hashCode;

    String channelId = _channelId;
    String channelName = _channelName;
    if (type == 'chat' || type == 'new_message' || type == 'chat_message' || data.containsKey('conversation_id')) {
      channelId = 'chat_messages';
      channelName = 'رسائل المحادثة';
    }

    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
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
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    _handleDataTap(message.data);
  }

  void _handleDataTap(Map<String, dynamic> data) {
    debugPrint('🔔 [FCM] Handling tap for data: $data');
    final type = data['type']?.toString();
    
    // Check for chat/message types
    if (type == 'chat' || type == 'new_message' || type == 'chat_message' || type == 'supervisorMessage' || data.containsKey('conversation_id')) {
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
