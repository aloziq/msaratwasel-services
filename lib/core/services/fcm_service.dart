import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
}

@lazySingleton
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthCubit _authCubit;
  GoRouter? _router;

  FcmService(this._authCubit);

  void setRouter(GoRouter router) {
    _router = router;
    debugPrint('🔔 [FCM] Router has been set');
  }

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await requestPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification?.title}');
        // TODO: show local notification if needed
      }
    });

    // Handle notification taps when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle initial message when app is opened from a terminated state
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 [FCM] App opened from terminated state via notification');
        _handleNotificationTap(message);
      }
    });
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
        // We use pushNamed to allow the user to go back to the previous screen
        _router?.pushNamed('messages', extra: {
          'id': id,
          'name': name,
          'receiverId': receiverId,
        });
      }
    } 
    // Handle Address Change (for Driver/Assistant)
    else if (type == 'address_change') {
      final authState = _authCubit.state;
      if (authState is AuthAuthenticated && _router != null) {
        if (authState.user.role == UserRole.driver) {
          debugPrint('🚀 [FCM] Navigating to Driver Route');
          _router?.push(AppRoutes.driverRoute);
        } else if (authState.user.role == UserRole.assistant) {
          debugPrint('🚀 [FCM] Navigating to Assistant Bus Map');
          _router?.push(AppRoutes.busMap);
        }
      }
    }
    // Handle Location Request (for Field Supervisor)
    else if (type == 'location_request') {
      final authState = _authCubit.state;
      if (authState is AuthAuthenticated && _router != null) {
        if (authState.user.role == UserRole.fieldSupervisor) {
          debugPrint('🚀 [FCM] Navigating to Supervisor Home/Alerts');
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
