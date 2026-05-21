import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _handleMessage,
        onDone: () {
          developer.log('🔌 WebSocket disconnected', name: 'REVERB');
          _isConnected = false;
          _scheduleReconnect();
        },
        onError: (error) {
          developer.log('❌ WebSocket error: $error', name: 'REVERB');
          _isConnected = false;
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
      developer.log('❌ Failed to connect to Reverb: $e', name: 'REVERB', stackTrace: stack);
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
          break;

        case 'pusher:pong':
          break;

        default:
          if (event != null && !event.startsWith('pusher:')) {
            developer.log('🔔 Reverb Event: $event on $channel', name: 'REVERB');
            final data = _parseData(message['data']);
            _eventController.add({
              'event': event,
              'channel': channel,
              'data': data,
            });
          }
          break;
      }
    } catch (e, stack) {
      developer.log('❌ Error parsing message: $e', name: 'REVERB', stackTrace: stack);
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
        developer.log('⏳ Subscription queued (not connected): $channelName', name: 'REVERB');
      }
      return;
    }

    final effectiveSocketId = socketId ?? _lastSocketId;

    try {
      if (channelName.startsWith('private-')) {
        if (effectiveSocketId == null) {
          developer.log('⚠️ Cannot subscribe to $channelName without socketId', name: 'REVERB');
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
      developer.log('❌ Subscription failed for $channelName: $e', name: 'REVERB', stackTrace: stack);
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
      developer.log('❌ Channel auth failed for $channelName: $e', name: 'REVERB', stackTrace: stack);
      rethrow;
    }
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      developer.log('❌ Failed to send WS message: $e', name: 'REVERB');
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
