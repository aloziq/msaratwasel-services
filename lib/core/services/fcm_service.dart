import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:msaratwasel_services/core/utils/active_conversation_tracker.dart';
import 'package:injectable/injectable.dart';
import 'package:go_router/go_router.dart';
import '../../features/shared/auth/presentation/cubit/auth_cubit.dart';
import '../../features/shared/auth/presentation/cubit/auth_state.dart';
import '../../features/shared/auth/domain/entities/user_entity.dart';
import '../../config/routes/app_routes.dart';
import '../../config/routes/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");

  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('USER_TOKEN');
  if (token == null || token.trim().isEmpty) {
    debugPrint('🚫 [FCM BG] No active user session (USER_TOKEN is null/empty). Skipping notification.');
    return;
  }

  final data = message.data;
  final String? cid =
      data['correlation_id']?.toString() ??
      data['notification_id']?.toString() ??
      data['id']?.toString() ??
      message.messageId;

  // 1. Persistent Deduplication check
  final List<String> processedCids =
      prefs.getStringList('processed_fcm_cids') ?? [];
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
  if (message.notification != null) {
    debugPrint('🔔 [FCM BG] OS handles UI. Skipping local show.');
    return;
  }

  // 3. Robust Content Extraction
  String? pick(List<dynamic> options) {
    for (final opt in options) {
      final str = opt?.toString();
      if (str != null && str.trim().isNotEmpty) return str;
    }
    return null;
  }

  final String title =
      pick([
        message.notification?.title,
        data['title_ar'],
        data['title_en'],
        data['title'],
        data['sender_name'],
      ]) ??
      'رسالة جديدة';
  final String body =
      pick([
        message.notification?.body,
        data['message_ar'],
        data['message_en'],
        data['message'],
        data['body'],
        data['content'],
        data['messagePreview'],
      ]) ??
      '';

  if (title.isNotEmpty || body.isNotEmpty) {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    // تصحيح: إزالة البادئة @mipmap/ لتفادي الفشل الصامت
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: DarwinInitializationSettings(),
        );
    await localNotifications.initialize(initializationSettings);

    final type = data['type']?.toString();
    bool isChat =
        (type == 'chat_message' || type == 'chat' || type == 'new_message');

    String channelId = isChat
        ? 'chat_messages_v3'
        : 'msarat_wasel_high_importance_v4';
    String channelName = isChat ? 'رسائل المحادثة' : 'إشعارات مسارات';

    debugPrint('🔔 [FCM BG] Showing local notification ($channelId)');

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
          icon: 'ic_notification', // تصحيح هنا أيضاً
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
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthCubit _authCubit;
  GoRouter? _router;

  final Set<String> _processedIds = {};
  final Set<String> _processedCorrelationIds = {};
  bool _isInitialized = false;

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

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await requestPermission();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    // تصحيح هنا أيضاً لتهيئة التطبيق في الواجهة الأمامية
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
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

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'chat_messages_v3',
      'رسائل المحادثة',
      description: 'إشعارات الرسائل الجديدة بصوت عالٍ',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
          'msarat_wasel_high_importance_v4',
          'إشعارات مسارات واصل',
          description: 'تنبيهات الرحلات والنظام',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

    final plugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await plugin?.createNotificationChannel(chatChannel);
    await plugin?.createNotificationChannel(generalChannel);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('🍎 [FCM] iOS detected: waiting for APNS token...');
      String? apnsToken;
      int retryCount = 0;
      while (apnsToken == null && retryCount < 10) {
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint(
            '⏳ [FCM] APNS token not ready, retrying ($retryCount/10)...',
          );
          await Future.delayed(const Duration(milliseconds: 500));
          retryCount++;
        }
      }
      if (apnsToken != null) {
        debugPrint('✅ [FCM] APNS token ready: $apnsToken');
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        '🔔 [FCM] Message received in foreground: ${message.notification?.title ?? "Data Message"}',
      );

      final data = message.data;
      final type = data['type']?.toString();


      final correlationId = _pick([data['correlation_id']]);
      final notificationId = _pick([
        data['notification_id'],
        data['id'],
        message.messageId,
      ]);

      final prefs = await SharedPreferences.getInstance();
      final List<String> persistentCids =
          prefs.getStringList('processed_fcm_cids') ?? [];

      bool isDuplicate = false;
      if (correlationId != null &&
          (_processedCorrelationIds.contains(correlationId) ||
              persistentCids.contains(correlationId))) {
        isDuplicate = true;
      } else if (notificationId != null &&
          (_processedIds.contains(notificationId) ||
              persistentCids.contains(notificationId))) {
        isDuplicate = true;
      }

      if (isDuplicate) {
        debugPrint(
          '⚠️ [FCM] Skipping duplicate message (ID: $notificationId / CID: $correlationId)',
        );
        return;
      }

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

      if (persistentCids.length > 50) persistentCids.removeAt(0);
      await prefs.setStringList('processed_fcm_cids', persistentCids);

      if (message.notification != null || data.isNotEmpty) {
        _showLocalNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          '🔔 [FCM] App opened from terminated state via notification',
        );
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
    final authState = _authCubit.state;
    if (authState is! AuthAuthenticated) {
      debugPrint('🔇 [FCM FG] Suppressing notification - user is not authenticated.');
      return;
    }

    final data = message.data;
    final String? cid = _pick([
      data['correlation_id'],
      data['id'],
      data['notification_id'],
      message.messageId,
    ]);


    final prefs = await SharedPreferences.getInstance();
    final processedCids = prefs.getStringList('processed_fcm_cids') ?? [];
    if (cid != null && processedCids.contains(cid)) {
      debugPrint('♻️ [FCM FG] Skipping duplicate message (CID: $cid)');
      return;
    }

    if (cid != null) {
      processedCids.add(cid);
      if (processedCids.length > 50) processedCids.removeAt(0);
      await prefs.setStringList('processed_fcm_cids', processedCids);
    }

    final type = data['type']?.toString();
    if (type == 'chat' ||
        type == 'new_message' ||
        type == 'chat_message' ||
        data.containsKey('conversation_id')) {
      final convId =
          data['conversation_id']?.toString() ?? data['id']?.toString();
      if (convId != null &&
          convId == ActiveConversationTracker.activeConversationId) {
        debugPrint(
          '🔇 [FCM FG] Suppressing notification - active in conversation $convId',
        );
        return;
      }
    }

    final String title =
        _pick([
          message.notification?.title,
          data['title_ar'],
          data['title_en'],
          data['title'],
          data['sender_name'],
        ]) ??
        'رسالة جديدة';
    final String body =
        _pick([
          message.notification?.body,
          data['message_ar'],
          data['message_en'],
          data['message'],
          data['body'],
          data['content'],
          data['messagePreview'],
        ]) ??
        '';

    if (title.isEmpty && body.isEmpty) return;

    final notificationId = cid.hashCode;

    bool isChat =
        (type == 'chat_message' || type == 'chat' || type == 'new_message');
    String channelId = isChat
        ? 'chat_messages_v3'
        : 'msarat_wasel_high_importance_v4';
    String channelName = isChat ? 'رسائل المحادثة' : 'إشعارات مسارات';

    debugPrint('🔔 [FCM FG] Showing local notification ($channelId)');

    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
          icon: 'ic_notification', // تصحيح نهائي هنا لإظهار البانر
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
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

    debugPrint('🔔 [FCM] Handling notification tap of type: $type');



    if (type == 'chat' ||
        type == 'new_message' ||
        type == 'chat_message' ||
        type == 'supervisorMessage' ||
        data.containsKey('conversation_id')) {
      final id = data['conversation_id']?.toString() ?? data['id']?.toString();
      final name = data['sender_name']?.toString() ?? data['name']?.toString();
      final receiverId =
          data['sender_id']?.toString() ?? data['receiverId']?.toString();

      if (id != null && _router != null) {
        debugPrint('🚀 [FCM] Navigating to chat screen for conversation: $id');
        _router?.pushNamed(
          'messages',
          extra: {'id': id, 'name': name, 'receiverId': receiverId},
        );
      }
    } else if (type == 'address_change') {
      final authState = _authCubit.state;
      if (authState is AuthAuthenticated && _router != null) {
        if (authState.user.role == UserRole.driver) {
          _router?.push(AppRoutes.driverRoute);
        } else if (authState.user.role == UserRole.assistant) {
          _router?.push(AppRoutes.busMap);
        }
      }
    } else if (type == 'location_request') {
      final authState = _authCubit.state;
      if (authState is AuthAuthenticated && _router != null) {
        if (authState.user.role == UserRole.fieldSupervisor) {
          _router?.push(AppRoutes.supervisorHome);
        }
      }
    } else if (type == 'trip_created' || type == 'field_trip_assigned') {
      final authState = _authCubit.state;
      if (authState is AuthAuthenticated && _router != null) {
        if (authState.user.role == UserRole.driver) {
          _router?.push(AppRoutes.driverHome);
        } else if (authState.user.role == UserRole.fieldSupervisor) {
          _router?.push(AppRoutes.supervisorTrips);
        }
      }
    } else if (type == 'student_added_to_route') {
      final authState = _authCubit.state;
      if (authState is AuthAuthenticated && _router != null) {
        if (authState.user.role == UserRole.driver) {
          _router?.push(AppRoutes.driverStudents);
        } else if (authState.user.role == UserRole.fieldSupervisor) {
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

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('✅ [FCM] Token deleted successfully');
    } catch (e) {
      debugPrint('❌ [FCM] Error deleting token: $e');
    }
  }
}
