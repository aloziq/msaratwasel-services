import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../network/api_config.dart';

/// خدمة الاتصال بـ Laravel Reverb عبر WebSocket للمشرفة والسائق
class ReverbService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isDisposed = false;
  String? _lastSocketId;

  final Dio _dio;
  final void Function(Map<String, dynamic> data)? _onBusLocationUpdated;
  final void Function(Map<String, dynamic> data)? _onStudentStatusUpdated;
  final void Function(Map<String, dynamic> data)? _onTripStatusUpdated;
  final void Function(Map<String, dynamic> data)? _onStudentLocationUpdated;
  final void Function(Map<String, dynamic> data)? _onNotificationReceived;

  static const String _reverbKey = 'masarat-wasel-key';

  static String get _reverbHost {
    if (!ApiConfig.isLocal) return '187.77.162.203';
    final apiUrl = ApiConfig.baseUrl;
    final uri = Uri.parse(apiUrl);
    return uri.host;
  }

  static const int _reverbPort = 8080;
  static const bool _forceNonSecure = true;
  static bool get _isSecure =>
      _forceNonSecure ? false : ApiConfig.baseUrl.startsWith('https');

  final Set<String> _subscribedChannels = {};

  ReverbService({
    required Dio dio,
    void Function(Map<String, dynamic> data)? onBusLocationUpdated,
    void Function(Map<String, dynamic> data)? onStudentStatusUpdated,
    void Function(Map<String, dynamic> data)? onTripStatusUpdated,
    void Function(Map<String, dynamic> data)? onStudentLocationUpdated,
    void Function(Map<String, dynamic> data)? onNotificationReceived,
  }) : _dio = dio,
       _onBusLocationUpdated = onBusLocationUpdated,
       _onStudentStatusUpdated = onStudentStatusUpdated,
       _onTripStatusUpdated = onTripStatusUpdated,
       _onStudentLocationUpdated = onStudentLocationUpdated,
       _onNotificationReceived = onNotificationReceived;

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
    } catch (e) {
      developer.log('❌ Failed to connect to Reverb: $e', name: 'REVERB');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final message = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final event = message['event'] as String?;

      switch (event) {
        case 'pusher:connection_established':
          _isConnected = true;
          final data = jsonDecode(message['data'] as String);
          final socketId = data['socket_id'] as String;
          _lastSocketId = socketId;
          developer.log('✅ Connected! Socket ID: $socketId', name: 'REVERB');
          break;

        case 'bus.location.updated':
          final data = _parseData(message['data']);
          _onBusLocationUpdated?.call(data);
          break;

        case 'student.status.updated':
          final data = _parseData(message['data']);
          _onStudentStatusUpdated?.call(data);
          break;

        case 'trip.status.updated':
          final data = _parseData(message['data']);
          _onTripStatusUpdated?.call(data);
          break;

        case 'student.location.updated':
          final data = _parseData(message['data']);
          _onStudentLocationUpdated?.call(data);
          break;

        case 'notification.pushed':
        case 'NotificationPushed':
          final data = _parseData(message['data']);
          _onNotificationReceived?.call(data);
          break;

        case 'pusher_internal:subscription_succeeded':
          developer.log(
            '✅ Subscription succeeded for: ${message['channel']}',
            name: 'REVERB',
          );
          break;
      }
    } catch (e) {
      developer.log('❌ Error parsing message: $e', name: 'REVERB');
    }
  }

  Map<String, dynamic> _parseData(dynamic data) {
    if (data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  Future<void> subscribe(String channelName, [String? socketId]) async {
    if (!_isConnected || _channel == null) return;
    if (_subscribedChannels.contains(channelName)) return;

    final effectiveSocketId = socketId ?? _lastSocketId;

    try {
      if (channelName.startsWith('private-')) {
        if (effectiveSocketId == null) {
          developer.log(
            '⚠️ Cannot subscribe to private channel $channelName without socketId',
            name: 'REVERB',
          );
          return;
        }
        final authData = await _authenticateChannel(
          channelName,
          effectiveSocketId,
        );
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
    } catch (e) {
      developer.log(
        '❌ Subscription failed for $channelName: $e',
        name: 'REVERB',
      );
    }
  }

  Future<Map<String, dynamic>> _authenticateChannel(
    String channelName,
    String socketId,
  ) async {
    try {
      final response = await _dio.post(
        'broadcasting/auth',
        data: {'socket_id': socketId, 'channel_name': channelName},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Auth failed with status ${response.statusCode}');
    } catch (e) {
      developer.log(
        '❌ Channel auth failed for $channelName: $e',
        name: 'REVERB',
      );
      rethrow;
    }
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      developer.log('❌ Failed to send: $e', name: 'REVERB');
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      developer.log('🔄 Reconnecting to Reverb...', name: 'REVERB');
      connect();
    });
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    developer.log('🔌 ReverbService disposed', name: 'REVERB');
  }
}
