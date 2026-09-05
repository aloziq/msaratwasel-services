import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/driver/route/data/repositories/route_repository_impl.dart';
import 'package:msaratwasel_services/features/driver/route/domain/entities/student_stop.dart';
import 'package:msaratwasel_services/features/shared/messages/data/repositories/messages_repository_impl.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString(
      jsonEncode({'data': {}, 'success': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHttpAdapter adapter;
  late Dio dio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'USER_BUS_ID': '12',
      'USER_ID': '5',
      'USER_TOKEN': 'driver_jwt_token',
    });
    final prefs = await SharedPreferences.getInstance();
    if (GetIt.instance.isRegistered<SharedPreferences>()) {
      GetIt.instance.unregister<SharedPreferences>();
    }
    GetIt.instance.registerSingleton<SharedPreferences>(prefs);

    adapter = _FakeHttpAdapter();
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://test.msaratwasel.com/api/',
      ),
    );
    dio.httpClientAdapter = adapter;
    ApiClient.testDio = dio;
  });

  tearDown(() {
    ApiClient.testDio = null;
  });

  group('RouteRepositoryImpl Production Logic Suite', () {
    test('1. getTripStops fetches user bus and maps morning stops correctly', () async {
      adapter.handler = (options) {
        if (options.path.contains('auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'bus_id': 12, 'name': 'Driver Ali'}
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('bus/12/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_type': 'morning',
                'trip_status': 'in_progress',
                'school_lat': 23.6080,
                'school_lng': 58.4500,
              },
              'passengers': [
                {
                  'id': 101,
                  'name': 'سالم الأحمد',
                  'parentName': 'أحمد',
                  'parentUserId': 201,
                  'forth_latitude': 23.6000,
                  'forth_longitude': 58.4400,
                  'status': 'boarded',
                  'isOnBus': true,
                  'isAbsent': false,
                  'isWaiting': false,
                },
                {
                  'id': 102,
                  'name': 'فاطمة النور',
                  'parentName': 'النور',
                  'status': 'dropped',
                  'isAbsent': false,
                  'lastEvent': {
                    'type': 'alighting',
                    'direction': 'to_school',
                  },
                },
                {
                  'id': 103,
                  'name': 'خالد عمر',
                  'parentName': 'عمر',
                  'status': 'absent',
                  'isAbsent': true,
                },
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = RouteRepositoryImpl();
      final stops = await repo.getTripStops();

      expect(stops.length, 3);
      expect(repo.currentTripType, 'morning');
      expect(repo.currentTripStatus, 'in_progress');
      expect(repo.schoolLocation, const LatLng(23.6080, 58.4500));

      // Stop 1: Boarded student
      expect(stops[0].id, '101');
      expect(stops[0].nameAr, 'سالم الأحمد');
      expect(stops[0].isBoarded, isTrue);
      expect(stops[0].isDroppedOff, isFalse);
      expect(stops[0].isAbsent, isFalse);
      expect(stops[0].location.latitude, 23.6000);

      // Stop 2: Dropped off student
      expect(stops[1].id, '102');
      expect(stops[1].isDroppedOff, isTrue);

      // Stop 3: Absent student
      expect(stops[2].id, '103');
      expect(stops[2].isAbsent, isTrue);

      // Count calculations
      expect(repo.getOnBoardCount(stops), 1); // 101 is boarded and not dropped
      expect(repo.getUnprocessedCount(stops), 0); // 101 boarded, 102 dropped, 103 absent

      // Route points returns empty list (drawn dynamically on screen)
      final points = await repo.getRoutePoints();
      expect(points, isEmpty);
    });

    test('2. getTripStops maps afternoon stops and waiting status correctly', () async {
      adapter.handler = (options) {
        if (options.path.contains('auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'has_bus': 12}
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('bus/12/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_type': 'afternoon',
                'trip_status': 'in_progress',
              },
              'passengers': [
                {
                  'id': 201,
                  'name': 'ياسر كريم',
                  'back_latitude': 23.5900,
                  'back_longitude': 58.4300,
                  'status': 'waiting',
                  'isWaiting': true,
                  'waitingElapsedSeconds': 45,
                },
                {
                  'id': 202,
                  'name': 'منى ناصر',
                  'latitude': 23.5800,
                  'longitude': 58.4200,
                  'status': 'atHome',
                },
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = RouteRepositoryImpl();
      final stops = await repo.getTripStops();

      expect(stops.length, 2);
      expect(repo.currentTripType, 'afternoon');

      // In afternoon, waiting student is effectively boarded
      expect(stops[0].isBoarded, isTrue);
      expect(stops[0].isWaiting, isTrue);
      expect(stops[0].waitingElapsedSeconds, 45);

      // atHome in afternoon is dropped off
      expect(stops[1].isDroppedOff, isTrue);
      expect(repo.getUnprocessedCount(stops), 1); // Stop 0 not dropped off
    });

    test('3. getTripStops throws Exception when user has no bus assigned', () async {
      adapter.handler = (options) {
        if (options.path.contains('auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'has_bus': null, 'bus_id': null}
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = RouteRepositoryImpl();
      expect(() => repo.getTripStops(), throwsException);
    });

    test('4. markStudentBoarded, markStudentDropped, markStudentAbsent send POST with student_id', () async {
      final requestedPaths = <String>[];
      final requestedData = <dynamic>[];

      adapter.handler = (options) {
        requestedPaths.add(options.path);
        requestedData.add(options.data);
        if (options.path.contains('auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'bus_id': 12}
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final repo = RouteRepositoryImpl();

      await repo.markStudentBoarded(studentId: '101');
      expect(requestedPaths.any((p) => p.contains('bus/12/mark-boarded')), isTrue);
      expect(requestedData.any((d) => d is Map && d['student_id'] == '101'), isTrue);

      await repo.markStudentDropped(studentId: '102');
      expect(requestedPaths.any((p) => p.contains('bus/12/mark-dropped')), isTrue);

      await repo.markStudentAbsent(studentId: '103');
      expect(requestedPaths.any((p) => p.contains('bus/12/mark-absent')), isTrue);
    });

    test('5. groupBoard, notifyParentNearHouse, arriveAtSchool execute cleanly', () async {
      final postedPaths = <String>[];

      adapter.handler = (options) {
        postedPaths.add(options.path);
        if (options.path.contains('auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'bus_id': 12}
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final repo = RouteRepositoryImpl();

      await repo.groupBoard(studentIds: ['101', '102', '103']);
      expect(postedPaths.any((p) => p.contains('bus/12/group-board')), isTrue);

      await repo.notifyParentNearHouse(studentId: '101');
      expect(postedPaths.any((p) => p.contains('bus/12/notify-near-house')), isTrue);

      await repo.arriveAtSchool();
      expect(postedPaths.any((p) => p.contains('bus/12/arrive')), isTrue);
    });

    test('6. updateLocation broadcasts bus GPS, speed, heading, and target coordinates', () async {
      Map<String, dynamic>? broadcastPayload;

      adapter.handler = (options) {
        if (options.path.contains('bus/12/location')) {
          broadcastPayload = options.data as Map<String, dynamic>;
          return ResponseBody.fromString(
            jsonEncode({'status': 'broadcast_ok'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 200);
      };

      final repo = RouteRepositoryImpl();

      await repo.updateLocation(
        latitude: 23.5885,
        longitude: 58.4120,
        speed: 55.0,
        heading: 180.0,
        targetLat: 23.6080,
        targetLng: 58.4500,
      );

      expect(broadcastPayload, isNotNull);
      expect(broadcastPayload!['bus_id'], 12);
      expect(broadcastPayload!['latitude'], 23.5885);
      expect(broadcastPayload!['longitude'], 58.4120);
      expect(broadcastPayload!['speed'], 55.0);
      expect(broadcastPayload!['heading'], 180.0);
      expect(broadcastPayload!['target_lat'], 23.6080);
      expect(broadcastPayload!['target_lng'], 58.4500);
      expect(broadcastPayload!['timestamp'], isNotNull);
    });

    test('6b. Error handling across all student status mutation methods', () async {
      adapter.handler = (options) {
        if (options.path.contains('auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'bus_id': 12}
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'message': 'فشل الاتصال بالخادم'}),
          500,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final repo = RouteRepositoryImpl();

      await expectLater(
        () => repo.markStudentBoarded(studentId: '101'),
        throwsA(predicate((e) => e.toString().contains('فشل تسجيل ركوب الطالب'))),
      );

      await expectLater(
        () => repo.groupBoard(studentIds: ['101', '102']),
        throwsA(predicate((e) => e.toString().contains('فشل تسجيل ركوب الطلاب'))),
      );

      await expectLater(
        () => repo.markStudentDropped(studentId: '101'),
        throwsA(predicate((e) => e.toString().contains('فشل تسجيل نزول الطالب'))),
      );

      await expectLater(
        () => repo.markStudentAbsent(studentId: '101'),
        throwsA(predicate((e) => e.toString().contains('فشل تسجيل غياب الطالب'))),
      );

      await expectLater(
        () => repo.notifyParentNearHouse(studentId: '101'),
        throwsA(predicate((e) => e.toString().contains('فشل إرسال الإشعار لولي الأمر'))),
      );

      await expectLater(
        () => repo.arriveAtSchool(),
        throwsA(predicate((e) => e.toString().contains('فشل تحديث الوصول'))),
      );
    });

    test('6c. updateLocation safely catches network and general errors without throwing', () async {
      adapter.handler = (options) => throw DioException(requestOptions: options);

      final repo = RouteRepositoryImpl();
      await expectLater(
        repo.updateLocation(latitude: 23.5, longitude: 58.4),
        completes,
      );
    });

    test('6d. getTripStops falls back to school or default location when coordinates are 0.0', () async {
      adapter.handler = (options) {
        if (options.path.contains('auth/user')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {'bus_id': 12}
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('bus/12/passengers')) {
          return ResponseBody.fromString(
            jsonEncode({
              'bus': {
                'trip_type': 'morning',
                'school_lat': 23.6080,
                'school_lng': 58.4500,
              },
              'passengers': [
                {
                  'id': 999,
                  'name': 'طالب بدون موقع',
                  'forth_latitude': 0.0,
                  'forth_longitude': 0.0,
                  'latitude': 0.0,
                  'longitude': 0.0,
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      final repo = RouteRepositoryImpl();
      final stops = await repo.getTripStops();
      expect(stops.first.location, const LatLng(23.6080, 58.4500));
    });
  });

  group('MessagesRepositoryImpl Production Logic Suite', () {
    test('7. getConversations parses participants, avatars, and unread counts', () async {
      adapter.handler = (options) {
        if (options.path.contains('/chat/conversations')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {
                  'id': 55,
                  'participants': [
                    {'id': 100, 'name': 'أم ريم', 'avatar_url': 'https://avatars.com/55.png'}
                  ],
                  'last_message': {
                    'body': 'هل وصل الباص للمحطة؟',
                    'created_at': '2026-09-04T07:30:00.000Z',
                  },
                  'unread_count': 3,
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = MessagesRepositoryImpl();
      final conversations = await repo.getConversations();

      expect(conversations.length, 1);
      expect(conversations[0].id, '55');
      expect(conversations[0].parentName, 'أم ريم');
      expect(conversations[0].lastMessage, 'هل وصل الباص للمحطة؟');
      expect(conversations[0].unreadCount, 3);
      expect(conversations[0].avatarUrl, 'https://avatars.com/55.png');
    });

    test('8. getMessages parses message models with sender and incoming flag', () async {
      adapter.handler = (options) {
        if (options.path.contains('/chat/conversations/55/messages')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {
                  'id': 1001,
                  'body': 'السلام عليكم',
                  'created_at': '2026-09-04T07:25:00.000Z',
                  'is_mine': false,
                  'attachment_url': null,
                  'sender': {'name': 'أم ريم'}
                },
                {
                  'id': 1002,
                  'body': 'وعليكم السلام، نعم وصلنا',
                  'created_at': '2026-09-04T07:26:00.000Z',
                  'is_mine': true,
                  'attachment_url': null,
                  'sender': {'name': 'السائق'}
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = MessagesRepositoryImpl();
      final messages = await repo.getMessages('55');

      expect(messages.length, 2);
      expect(messages[0].id, '1001');
      expect(messages[0].text, 'السلام عليكم');
      expect(messages[0].incoming, isTrue);
      expect(messages[0].sender, 'أم ريم');

      expect(messages[1].id, '1002');
      expect(messages[1].text, 'وعليكم السلام، نعم وصلنا');
      expect(messages[1].incoming, isFalse);
    });

    test('9. sendMessage posts body and text type to conversation endpoint', () async {
      String? postedBody;
      String? postedType;

      adapter.handler = (options) {
        if (options.path.contains('/chat/conversations/55/messages') && options.method == 'POST') {
          final map = options.data as Map;
          postedBody = map['body'];
          postedType = map['type'];
          return ResponseBody.fromString(
            jsonEncode({'success': true}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = MessagesRepositoryImpl();
      await repo.sendMessage('55', 'سأكون هناك خلال 5 دقائق');

      expect(postedBody, 'سأكون هناك خلال 5 دقائق');
      expect(postedType, 'text');
    });

    test('10. getContacts maps contact list accurately', () async {
      adapter.handler = (options) {
        if (options.path.contains('/chat/contacts')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {
                  'id': 301,
                  'name': 'أستاذ أحمد',
                  'chat_description': 'معلم الفصل',
                  'avatar_url': 'https://avatars.com/teacher.png',
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = MessagesRepositoryImpl();
      final contacts = await repo.getContacts();

      expect(contacts.length, 1);
      expect(contacts[0].id, '301');
      expect(contacts[0].name, 'أستاذ أحمد');
      expect(contacts[0].description, 'معلم الفصل');
      expect(contacts[0].avatarUrl, 'https://avatars.com/teacher.png');
    });

    test('11. startConversation creates conversation and resolves counterpart', () async {
      adapter.handler = (options) {
        if (options.path.contains('/chat/conversations') && options.method == 'POST') {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'id': 70,
                'participants': [
                  {'id': 500, 'name': 'ولي أمر بدر', 'avatar_url': 'https://avatars.com/p.png'},
                ]
              }
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = MessagesRepositoryImpl();
      final conversation = await repo.startConversation('500');

      expect(conversation.id, '70');
      expect(conversation.parentName, 'ولي أمر بدر');
      expect(conversation.lastMessage, 'بدء محادثة');
    });

    test('12. markAsRead posts to conversation read endpoint', () async {
      bool markReadCalled = false;

      adapter.handler = (options) {
        if (options.path.contains('/chat/conversations/70/read')) {
          markReadCalled = true;
          return ResponseBody.fromString(
            jsonEncode({'success': true}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 404);
      };

      final repo = MessagesRepositoryImpl();
      await repo.markAsRead('70');

      expect(markReadCalled, isTrue);
    });
  });
}
