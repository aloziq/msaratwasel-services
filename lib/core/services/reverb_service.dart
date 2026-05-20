import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../config/app_config.dart';

/// خدمة الاتصال بـ Laravel Reverb عبر WebSocket
class ReverbService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isDisposed = false;
  String? _lastSocketId;

  final int _userId;
  final Dio _dio;
  
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  // إعدادات Reverb المستمدة من AppConfig
  static const String _reverbKey = AppConfig.reverbKey;
  static String get _reverbHost => AppConfig.reverbHost;
  static int get _reverbPort => AppConfig.reverbPort;
  static bool get _isSecure => AppConfig.reverbUseSsl;

  final Set<String> _subscribedChannels = {};
  final List<String> _pendingSubscriptions = [];
  final Set<String> _desiredChannels = {};

  ReverbService({
    required int userId,
    required Dio dio,
    Function(Map<String, dynamic>)? onMessageReceived,
  }) : _userId = userId,
       _dio = dio {
    if (onMessageReceived != null) {
      eventStream.listen(onMessageReceived);
    }
  }

  Future<void> connect() async {
    if (_isDisposed) return;
    _subscribedChannels.clear();

    try {
      final protocol = _isSecure ? 'wss' : 'ws';
      final wsUrl = '$protocol://$_reverbHost:$_reverbPort/app/$_reverbKey';
      developer.log('🔌 Connecting to Reverb: $wsUrl', name: 'REVERB');

      try {
        FirebaseCrashlytics.instance.log('🔌 WebSocket connecting: $wsUrl');
        FirebaseCrashlytics.instance.setCustomKey('reverb_status', 'connecting');
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Reverb Connect: Attempting connection',
            category: 'reverb.connect',
            level: SentryLevel.info,
            data: {'url': wsUrl},
          ),
        );
      } catch (_) {}

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _handleMessage,
        onDone: () {
          developer.log('🔌 WebSocket disconnected', name: 'REVERB');
          _isConnected = false;
          try {
            FirebaseCrashlytics.instance.log('🔌 WebSocket disconnected');
            FirebaseCrashlytics.instance.setCustomKey('reverb_status', 'disconnected');
            FirebaseAnalytics.instance.logEvent(name: 'reverb_disconnected');
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb: WebSocket connection disconnected',
                category: 'reverb.disconnect',
                level: SentryLevel.warning,
              ),
            );
          } catch (_) {}
          _scheduleReconnect();
        },
        onError: (error) {
          developer.log('❌ WebSocket error: $error', name: 'REVERB');
          _isConnected = false;
          try {
            FirebaseCrashlytics.instance.log('❌ WebSocket error: $error');
            FirebaseCrashlytics.instance.recordError(error, null, reason: 'Reverb WebSocket Error');
            FirebaseCrashlytics.instance.setCustomKey('reverb_status', 'error');
            FirebaseAnalytics.instance.logEvent(
              name: 'reverb_error',
              parameters: {'error': error.toString()},
            );
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb: WebSocket connection error',
                category: 'reverb.error',
                level: SentryLevel.error,
                data: {'error': error.toString()},
              ),
            );
            Sentry.captureException(
              error,
              withScope: (scope) {
                scope.setTag('service', 'reverb');
                scope.setTag('wsUrl', wsUrl);
              },
            );
          } catch (_) {}
          _scheduleReconnect();
        },
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_isConnected) {
          _send({'event': 'pusher:ping', 'data': {}});
        }
      });
    } catch (e, stack) {
      developer.log('❌ Failed to connect to Reverb: $e', name: 'REVERB');
      try {
        FirebaseCrashlytics.instance.recordError(e, null, reason: 'Failed to connect to Reverb');
        Sentry.captureException(e, stackTrace: stack);
      } catch (_) {}
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final message = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final event = message['event'] as String?;
      final channel = message['channel'] as String?;

      switch (event) {
        case 'pusher:connection_established':
          _isConnected = true;
          final data = jsonDecode(message['data'] as String);
          final socketId = data['socket_id'] as String;
          _lastSocketId = socketId;
          developer.log('✅ Connected! Socket ID: $socketId', name: 'REVERB');

          try {
            FirebaseCrashlytics.instance.log('✅ Reverb Connected! Socket ID: $socketId');
            FirebaseCrashlytics.instance.setCustomKey('reverb_socket_id', socketId);
            FirebaseCrashlytics.instance.setCustomKey('reverb_status', 'connected');
            FirebaseAnalytics.instance.logEvent(
              name: 'reverb_connected',
              parameters: {'socket_id': socketId},
            );
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb: Connection established',
                category: 'reverb.event',
                level: SentryLevel.info,
                data: {'socket_id': socketId},
              ),
            );
          } catch (_) {}

          // Subscribe to default user channels
          subscribe('private-App.Models.User.$_userId', socketId);

          if (_pendingSubscriptions.isNotEmpty) {
            final pending = List<String>.from(_pendingSubscriptions);
            _pendingSubscriptions.clear();
            for (final ch in pending) {
              subscribe(ch, socketId);
            }
          }

          // Resubscribe to all desired channels upon reconnect
          final resubscribeList = _desiredChannels.where((ch) => ch != 'private-App.Models.User.$_userId').toList();
          for (final ch in resubscribeList) {
            subscribe(ch, socketId);
          }
          break;

        case 'pusher_internal:subscription_succeeded':
          developer.log('✅ Subscription succeeded for: $channel', name: 'REVERB');
          try {
            FirebaseCrashlytics.instance.log('📡 Reverb Subscribed: $channel');
            FirebaseAnalytics.instance.logEvent(
              name: 'reverb_subscribed',
              parameters: {'channel': channel ?? ''},
            );
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb: Subscription succeeded',
                category: 'reverb.subscription',
                level: SentryLevel.info,
                data: {'channel': channel},
              ),
            );
          } catch (_) {}
          break;

        case 'pusher:pong':
          break;

        default:
          if (event != null && !event.startsWith('pusher:')) {
            try {
              FirebaseCrashlytics.instance.log('🔔 Reverb Event: $event on $channel');
              FirebaseAnalytics.instance.logEvent(
                name: 'reverb_event_received',
                parameters: {'event': event, 'channel': channel ?? ''},
              );
            } catch (_) {}
            final data = _parseData(message['data']);
            try {
              Sentry.addBreadcrumb(
                Breadcrumb(
                  message: 'Reverb Event: $event',
                  category: 'reverb.message',
                  level: SentryLevel.info,
                  data: {
                    'event': event,
                    'channel': channel ?? 'unknown',
                    'data': data,
                  },
                ),
              );
            } catch (_) {}
            _eventController.add({
              'event': event,
              'channel': channel,
              'data': data,
            });
          }
          break;
      }
    } catch (e, stack) {
      developer.log('❌ Error parsing message: $e', name: 'REVERB');
      try {
        FirebaseCrashlytics.instance.recordError(e, null, reason: 'Reverb Message Parse Error');
        Sentry.captureException(
          e,
          stackTrace: stack,
          withScope: (scope) {
            scope.setTag('rawMessage', rawMessage.toString());
          },
        );
      } catch (_) {}
    }
  }

  Map<String, dynamic> _parseData(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return {'raw': data};
      }
    }
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<void> subscribe(String channelName, [String? socketId]) async {
    _desiredChannels.add(channelName);
    if (_subscribedChannels.contains(channelName)) return;

    if (!_isConnected || _channel == null) {
      if (!_pendingSubscriptions.contains(channelName)) {
        _pendingSubscriptions.add(channelName);
        try {
          Sentry.addBreadcrumb(
            Breadcrumb(
              message: 'Reverb: Subscription queued (not connected yet)',
              category: 'reverb.subscription',
              level: SentryLevel.warning,
              data: {'channel': channelName},
            ),
          );
        } catch (_) {}
      }
      return;
    }

    final effectiveSocketId = socketId ?? _lastSocketId;

    try {
      if (channelName.startsWith('private-')) {
        if (effectiveSocketId == null) {
          try {
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Reverb: Private subscription deferred (no socketId yet)',
                category: 'reverb.subscription',
                level: SentryLevel.warning,
                data: {'channel': channelName},
              ),
            );
          } catch (_) {}
          return;
        }
        final authData = await _authenticateChannel(channelName, effectiveSocketId);
        _send({
          'event': 'pusher:subscribe',
          'data': {'channel': channelName, 'auth': authData['auth']},
        });
      } else {
        _send({
          'event': 'pusher:subscribe',
          'data': {'channel': channelName},
        });
      }
      _subscribedChannels.add(channelName);
      developer.log('📡 Subscribed to: $channelName', name: 'REVERB');
    } catch (e, stack) {
      developer.log('❌ Subscription failed for $channelName: $e', name: 'REVERB');
      try {
        Sentry.captureException(
          e,
          stackTrace: stack,
          withScope: (scope) {
            scope.setTag('channel', channelName);
            scope.setTag('socket_id', effectiveSocketId ?? 'none');
          },
        );
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> _authenticateChannel(String channelName, String socketId) async {
    try {
      final response = await _dio.post(
        'broadcasting/auth',
        data: {'socket_id': socketId, 'channel_name': channelName},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Auth failed');
    } catch (e, stack) {
      try {
        Sentry.captureException(
          e,
          stackTrace: stack,
          withScope: (scope) {
            scope.setTag('channel', channelName);
            scope.setTag('socket_id', socketId);
          },
        );
      } catch (_) {}
      rethrow;
    }
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e, stack) {
      try {
        Sentry.captureException(
          e,
          stackTrace: stack,
          withScope: (scope) {
            scope.setTag('ws_action', 'send_payload');
          },
        );
      } catch (_) {}
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _eventController.close();
    _isConnected = false;
    developer.log('🔌 ReverbService disposed', name: 'REVERB');
  }
}
