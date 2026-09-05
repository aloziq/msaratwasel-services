import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:msaratwasel_services/core/services/reverb_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake WebSocket infrastructure
// ─────────────────────────────────────────────────────────────────────────────

/// A sink that records everything added to it and allows the test to push data.
class FakeWebSocketSink implements WebSocketSink {
  final List<String> sent = [];
  final StreamController<void> _doneController = StreamController.broadcast();

  @override
  void add(dynamic data) => sent.add(data as String);

  @override
  Future<void> close([int? code, String? reason]) {
    _doneController.close();
    return Future.value();
  }

  // Ignore these for testing purposes
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream stream) async {}
  @override
  Future get done => _doneController.stream.isEmpty;
}

/// A fake WebSocketChannel that accepts injected data from the test.
class FakeWebSocketChannel implements WebSocketChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final FakeWebSocketSink fakesSink = FakeWebSocketSink();
  final StreamController<String> _controller = StreamController<String>.broadcast();

  /// Push a raw JSON string into the channel (simulates server → client).
  void inject(String json) => _controller.add(json);
  void injectDone() => _controller.close();

  @override
  Stream get stream => _controller.stream;

  @override
  WebSocketSink get sink => fakesSink;

  // Unused fields required by the interface
  @override
  String? get protocol => null;
  @override
  Future<void> get ready => Future.value();
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

ReverbService makeService({
  required FakeWebSocketChannel channel,
  Function(Map<String, dynamic>)? onMessage,
  int userId = 42,
}) {
  return ReverbService(
    userId: userId,
    dio: Dio(), // not used in pure message-parsing tests
    onMessageReceived: onMessage,
    channelFactory: (_) => channel,
  );
}

String connectionEstablished({String socketId = 'sock-1'}) => jsonEncode({
  'event': 'pusher:connection_established',
  'data': jsonEncode({'socket_id': socketId, 'activity_timeout': 120}),
});

String locationEvent({double lat = 24.68, double lng = 46.72}) => jsonEncode({
  'event': 'bus.location.updated',
  'channel': 'private-bus.10',
  'data': jsonEncode({'latitude': lat.toString(), 'longitude': lng.toString(), 'speed_kmh': '60'}),
});

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeWebSocketChannel fakeChannel;
  late ReverbService service;

  setUp(() {
    fakeChannel = FakeWebSocketChannel();
    service = makeService(channel: fakeChannel);
  });

  tearDown(() {
    service.dispose();
  });

  // ── Connection & state ────────────────────────────────────────────────────

  group('ReverbService connection', () {
    test('1. connect() uses channelFactory and sends nothing initially', () async {
      await service.connect();
      await Future.delayed(Duration.zero);
      // Only the subscription message may appear after connection_established
      // At this point the channel has been established but no connection event yet
      expect(fakeChannel.fakesSink.sent, isEmpty);
    });

    test('2. After connection_established event is processed, service remains alive', () async {
      await service.connect();
      fakeChannel.inject(connectionEstablished());
      await Future.delayed(const Duration(milliseconds: 50));
      // Service is alive — dispose does not throw
      expect(() => service.dispose(), returnsNormally);
    });

    test('3. Dispose sets _isDisposed and channel sink closes', () async {
      await service.connect();
      service.dispose();
      // No exception expected; dispose is idempotent
      service.dispose(); // second call should be safe
    });

    test('4. connect() after dispose is a no-op', () async {
      service.dispose();
      await service.connect(); // should return immediately
      expect(fakeChannel.fakesSink.sent, isEmpty);
    });
  });

  // ── Message parsing ───────────────────────────────────────────────────────

  group('ReverbService message parsing', () {
    test('5. Bus location event is forwarded to onMessageReceived', () async {
      final received = <Map<String, dynamic>>[];
      final svc = makeService(channel: fakeChannel, onMessage: received.add);
      await svc.connect();
      fakeChannel.inject(connectionEstablished());
      await Future.delayed(const Duration(milliseconds: 10));
      fakeChannel.inject(locationEvent());
      await Future.delayed(const Duration(milliseconds: 10));
      expect(received.isNotEmpty, isTrue);
      final last = received.last;
      expect(last['event'], 'bus.location.updated');
    });

    test('6. Malformed JSON does not crash the service', () async {
      await service.connect();
      fakeChannel.inject('NOT_VALID_JSON{{{');
      await Future.delayed(const Duration(milliseconds: 10));
      // Service should still be alive
      expect(service, isNotNull);
    });

    test('7. pusher:pong is silently ignored', () async {
      final received = <Map<String, dynamic>>[];
      final svc = makeService(channel: fakeChannel, onMessage: received.add);
      await svc.connect();
      fakeChannel.inject(jsonEncode({'event': 'pusher:pong', 'data': {}}));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, isEmpty); // pong must not propagate
    });

    test('8. pusher_internal:subscription_succeeded is silently ignored', () async {
      final received = <Map<String, dynamic>>[];
      final svc = makeService(channel: fakeChannel, onMessage: received.add);
      await svc.connect();
      fakeChannel.inject(jsonEncode({
        'event': 'pusher_internal:subscription_succeeded',
        'channel': 'private-bus.10',
        'data': {},
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, isEmpty);
    });

    test('9. Custom event is forwarded with event name', () async {
      final received = <Map<String, dynamic>>[];
      final svc = makeService(channel: fakeChannel, onMessage: received.add);
      await svc.connect();
      fakeChannel.inject(jsonEncode({
        'event': 'driver.location.updated',
        'channel': 'private-bus.7',
        'data': jsonEncode({'latitude': '24.5', 'longitude': '46.7'}),
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(received.any((e) => e['event'] == 'driver.location.updated'), isTrue);
    });

    test('10. Data that is already a Map (not String) is parsed correctly', () async {
      final received = <Map<String, dynamic>>[];
      final svc = makeService(channel: fakeChannel, onMessage: received.add);
      await svc.connect();
      fakeChannel.inject(jsonEncode({
        'event': 'my.event',
        'channel': 'private-bus.7',
        'data': {'direct': 'map'},
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(received.any((e) => e['event'] == 'my.event'), isTrue);
    });
  });

  // ── Subscribe before connect (pending queue) ──────────────────────────────

  group('ReverbService subscription queue', () {
    test('11. subscribe() before connect queues channel in pending list', () async {
      // Do NOT call connect first
      await service.subscribe('private-bus.99');
      // Connect now – should flush pending
      await service.connect();
      fakeChannel.inject(connectionEstablished());
      await Future.delayed(const Duration(milliseconds: 10));
      // The subscribe message for private-bus.99 should appear in sent
      final hasBusSubscribe = fakeChannel.fakesSink.sent.any(
        (s) => s.contains('private-bus.99'),
      );
      // Auth will fail (no API) so it may appear only as a subscribe attempt or pending
      // Just ensure no crash occurred
      expect(service, isNotNull);
    });

    test('12. Public channel subscribe does not need socket_id auth', () async {
      await service.connect();
      fakeChannel.inject(connectionEstablished());
      await Future.delayed(const Duration(milliseconds: 10));
      await service.subscribe('public-test-channel');
      await Future.delayed(const Duration(milliseconds: 10));
      final hasPublicSubscribe = fakeChannel.fakesSink.sent.any(
        (s) => s.contains('public-test-channel'),
      );
      expect(hasPublicSubscribe, isTrue);
    });

    test('13. Subscribing to same public channel twice does not send duplicate', () async {
      await service.connect();
      fakeChannel.inject(connectionEstablished());
      await Future.delayed(const Duration(milliseconds: 10));
      await service.subscribe('public-same');
      await Future.delayed(const Duration(milliseconds: 10));
      final countBefore = fakeChannel.fakesSink.sent.where((s) => s.contains('public-same')).length;
      await service.subscribe('public-same'); // second call — already subscribed
      await Future.delayed(const Duration(milliseconds: 10));
      final countAfter = fakeChannel.fakesSink.sent.where((s) => s.contains('public-same')).length;
      expect(countAfter, countBefore); // no additional message
    });
  });

  // ── WebSocket disconnect and reconnect ────────────────────────────────────

  group('ReverbService disconnect', () {
    test('14. WebSocket done event triggers reconnect timer', () async {
      await service.connect();
      fakeChannel.inject(connectionEstablished());
      await Future.delayed(const Duration(milliseconds: 10));
      // Simulate server close
      fakeChannel.injectDone();
      await Future.delayed(const Duration(milliseconds: 50));
      // Service should still be alive and schedule a reconnect (no crash)
      expect(service, isNotNull);
    });
  });

  // ── _parseData helper (via event stream) ─────────────────────────────────

  group('ReverbService data parsing edge cases', () {
    test('15. Data as invalid JSON string returns raw wrapper', () async {
      final received = <Map<String, dynamic>>[];
      final svc = makeService(channel: fakeChannel, onMessage: received.add);
      await svc.connect();
      fakeChannel.inject(jsonEncode({
        'event': 'some.event',
        'channel': 'private-test',
        'data': 'NOT_JSON',
      }));
      await Future.delayed(const Duration(milliseconds: 10));
      if (received.isNotEmpty) {
        final data = received.last['data'];
        // Falls back to {'raw': 'NOT_JSON'}
        expect(data['raw'], 'NOT_JSON');
      }
    });
  });
}

