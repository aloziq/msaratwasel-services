import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:msaratwasel_services/core/utils/active_conversation_tracker.dart';
import 'package:injectable/injectable.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../features/shared/auth/presentation/cubit/auth_cubit.dart';
import '../../features/shared/auth/presentation/cubit/auth_state.dart';
import '../../features/shared/auth/domain/entities/user_entity.dart';
import '../../config/routes/app_routes.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");

  try {
    FirebaseCrashlytics.instance.log('FCM BG: Handling background message ${message.messageId}');
    FirebaseAnalytics.instance.logEvent(
      name: 'fcm_bg_received',
      parameters: {'message_id': message.messageId ?? ''},
    );
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'FCM BG: Handling background message',
        category: 'fcm.background',
        level: SentryLevel.info,
        data: {
          'message_id': message.messageId ?? 'unknown',
          'data': message.data,
        },
      ),
    );
  } catch (_) {}

  final data = message.data;
  final String? cid =
      data['correlation_id']?.toString() ??
      data['notification_id']?.toString() ??
      data['id']?.toString() ??
      message.messageId;

  // 1. Persistent Deduplication check
  final prefs = await SharedPreferences.getInstance();
  final List<String> processedCids =
      prefs.getStringList('processed_fcm_cids') ?? [];
  if (cid != null && processedCids.contains(cid)) {
    debugPrint('🚫 [FCM BG] Skipping persistent duplicate (CID: $cid)');
    try {
      FirebaseCrashlytics.instance.log('FCM BG: Skipping persistent duplicate (CID: $cid)');
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'FCM BG: Suppressed persistent duplicate',
          category: 'fcm.background.suppressed',
          level: SentryLevel.warning,
          data: {'correlation_id': cid},
        ),
      );
    } catch (_) {}
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
    try {
      FirebaseCrashlytics.instance.log('FCM BG: OS handles UI. Skipping local show.');
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'FCM BG: Suppressed duplicate UI because OS notification exists',
          category: 'fcm.background.suppressed',
          level: SentryLevel.info,
          data: {'message_id': message.messageId ?? 'unknown'},
        ),
      );
    } catch (_) {}
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
        AndroidInitializationSettings('ic_launcher');

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

    try {
      FirebaseCrashlytics.instance.log('FCM BG: Showing local notification ($channelId)');
      FirebaseAnalytics.instance.logEvent(
        name: 'fcm_bg_notification_shown',
        parameters: {'type': type ?? '', 'channel': channelId},
      );
    } catch (_) {}

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
          icon: 'ic_launcher', // تصحيح هنا أيضاً
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
        AndroidInitializationSettings('ic_launcher');

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
            Sentry.captureException(e);
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

      try {
        FirebaseCrashlytics.instance.log('FCM FG: Message received foreground ${message.messageId}');
        FirebaseAnalytics.instance.logEvent(
          name: 'fcm_fg_received',
          parameters: {'message_id': message.messageId ?? ''},
        );
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'FCM FG: Message received in foreground',
            category: 'fcm.foreground',
            level: SentryLevel.info,
            data: {
              'message_id': message.messageId ?? 'unknown',
              'data': message.data,
            },
          ),
        );
      } catch (_) {}

      final data = message.data;
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
        try {
          FirebaseCrashlytics.instance.log('FCM FG: Skipping duplicate message (ID: $notificationId / CID: $correlationId)');
          Sentry.addBreadcrumb(
            Breadcrumb(
              message: 'FCM FG: Suppressed duplicate notification',
              category: 'fcm.foreground.suppressed',
              level: SentryLevel.warning,
              data: {
                'notification_id': notificationId ?? 'unknown',
                'correlation_id': correlationId ?? 'unknown',
              },
            ),
          );
        } catch (_) {}
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
    final data = message.data;
    final String? cid = _pick([
      data['correlation_id'],
      data['id'],
      data['notification_id'],
      message.messageId,
    ]);

    try {
      FirebaseCrashlytics.instance.log('FCM FG: Attempting to show local notification: $cid');
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final processedCids = prefs.getStringList('processed_fcm_cids') ?? [];
    if (cid != null && processedCids.contains(cid)) {
      debugPrint('♻️ [FCM FG] Skipping duplicate message (CID: $cid)');
      try {
        FirebaseCrashlytics.instance.log('FCM FG: Skipping duplicate message (CID: $cid)');
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'FCM FG: Suppressed duplicate local show',
            category: 'fcm.foreground.suppressed',
            level: SentryLevel.warning,
            data: {'correlation_id': cid},
          ),
        );
      } catch (_) {}
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
        try {
          FirebaseCrashlytics.instance.log('FCM FG: Suppressing notification - active in conversation $convId');
          FirebaseAnalytics.instance.logEvent(
            name: 'fcm_fg_suppressed_active_chat',
            parameters: {'conversation_id': convId},
          );
          Sentry.addBreadcrumb(
            Breadcrumb(
              message: 'FCM FG: Suppressed notification because user is actively inside the chat screen',
              category: 'fcm.foreground.suppressed',
              level: SentryLevel.info,
              data: {'conversation_id': convId},
            ),
          );
        } catch (_) {}
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

    try {
      FirebaseCrashlytics.instance.log('FCM FG: Showing local notification ($channelId)');
      FirebaseAnalytics.instance.logEvent(
        name: 'fcm_fg_notification_shown',
        parameters: {'type': type ?? '', 'channel': channelId},
      );
    } catch (_) {}

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
          icon: 'ic_launcher', // تصحيح نهائي هنا لإظهار البانر
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

    try {
      FirebaseCrashlytics.instance.log('FCM Tap: Handling notification tap of type: $type');
      FirebaseAnalytics.instance.logEvent(
        name: 'fcm_notification_tapped',
        parameters: {'type': type ?? ''},
      );
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'FCM Tap: Handling notification tap',
          category: 'fcm.tap',
          level: SentryLevel.info,
          data: {
            'type': type ?? 'unknown',
            'data': data,
          },
        ),
      );
    } catch (_) {}

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
