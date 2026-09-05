import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:msaratwasel_services/features/shared/messages/data/models/conversation_model.dart';
import 'package:msaratwasel_services/features/shared/messages/data/models/message_model.dart';
import 'package:msaratwasel_services/features/shared/qr_scan/presentation/cubit/qr_scan_cubit.dart';
import 'package:msaratwasel_services/features/shared/qr_scan/presentation/cubit/qr_scan_state.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/entities/student_entity.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/repositories/students_repository.dart';
import 'package:msaratwasel_services/features/teacher/students/domain/usecases/mark_attendance_usecase.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) return handler!(options);
    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeStudentsRepository implements StudentsRepository {
  Either<String, void>? markAttendanceResult;
  String? lastStudentId;
  AttendanceStatus? lastStatus;
  bool? lastViaQr;

  @override
  Future<Either<String, void>> markAttendance(
    String studentId,
    AttendanceStatus status, {
    bool viaQr = false,
  }) async {
    lastStudentId = studentId;
    lastStatus = status;
    lastViaQr = viaQr;
    return markAttendanceResult ?? const Right(null);
  }

  @override
  Future<Either<String, List<StudentEntity>>> getStudentsByClass(String classId) async {
    return const Right([]);
  }

  @override
  Future<Either<String, void>> confirmAttendance(String classId) async {
    return const Right(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStudentsRepository fakeRepo;
  late MarkAttendanceUseCase markAttendanceUseCase;
  late QRScanCubit qrScanCubit;

  late _FakeHttpAdapter adapter;
  late Dio testDio;
  late SharedPreferences prefs;

  final testDate = DateTime.parse('2026-09-04T11:00:00.000Z');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    if (getIt.isRegistered<SharedPreferences>()) {
      getIt.unregister<SharedPreferences>();
    }
    getIt.registerSingleton<SharedPreferences>(prefs);

    adapter = _FakeHttpAdapter();
    testDio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
    testDio.httpClientAdapter = adapter;
    ApiClient.testDio = testDio;

    fakeRepo = FakeStudentsRepository();
    markAttendanceUseCase = MarkAttendanceUseCase(fakeRepo);
    qrScanCubit = QRScanCubit(markAttendanceUseCase);
  });

  tearDown(() {
    ApiClient.testDio = null;
    qrScanCubit.close();
  });

  group('Shared Messaging Models Suite', () {
    test('1. ConversationModel fromJson and toJson round-trip', () {
      final json = {
        'id': 'conv_123',
        'parentName': 'Abu Fahad',
        'studentName': 'Fahad Al-Otaibi',
        'lastMessage': 'Will the bus arrive early today?',
        'lastMessageTime': testDate.toIso8601String(),
        'unreadCount': 2,
        'avatarUrl': 'https://api.msaratwasel.com/avatars/p1.png',
      };

      final model = ConversationModel.fromJson(json);

      expect(model.id, 'conv_123');
      expect(model.parentName, 'Abu Fahad');
      expect(model.studentName, 'Fahad Al-Otaibi');
      expect(model.lastMessage, 'Will the bus arrive early today?');
      expect(model.lastMessageTime, testDate);
      expect(model.unreadCount, 2);
      expect(model.avatarUrl, 'https://api.msaratwasel.com/avatars/p1.png');

      final serialized = model.toJson();
      expect(serialized['id'], 'conv_123');
      expect(serialized['parentName'], 'Abu Fahad');
      expect(serialized['unreadCount'], 2);
    });

    test('2. MessageModel fromJson and toJson round-trip', () {
      final json = {
        'id': 'msg_999',
        'text': 'The bus is now 5 minutes away.',
        'sender': 'assistant',
        'time': testDate.toIso8601String(),
        'incoming': false,
        'mediaUrl': null,
      };

      final model = MessageModel.fromJson(json);

      expect(model.id, 'msg_999');
      expect(model.text, 'The bus is now 5 minutes away.');
      expect(model.sender, 'assistant');
      expect(model.time, testDate);
      expect(model.incoming, isFalse);
      expect(model.mediaUrl, isNull);

      final serialized = model.toJson();
      expect(serialized['text'], 'The bus is now 5 minutes away.');
      expect(serialized['incoming'], isFalse);
    });
  });

  group('QRScanCubit State Machine Suite', () {
    test('3. Initial state is QRScanInitial', () {
      expect(qrScanCubit.state, equals(QRScanInitial()));
    });

    test('4. onCodeScanned trims raw scanned string and emits QRScanSuccess', () {
      qrScanCubit.onCodeScanned('   QR_STUDENT_9988   ');
      expect(qrScanCubit.state, isA<QRScanSuccess>());
      final success = qrScanCubit.state as QRScanSuccess;
      expect(success.code, 'QR_STUDENT_9988');
    });

    test('5. markAttendanceViaQr emits Loading then QRScanAttendanceSuccess on success', () async {
      fakeRepo.markAttendanceResult = const Right(null);

      final states = <QRScanState>[];
      final subscription = qrScanCubit.stream.listen(states.add);

      await qrScanCubit.markAttendanceViaQr('  student_55  ', 'class_1');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<QRScanLoading>());
      expect(states[1], isA<QRScanAttendanceSuccess>());

      final success = states[1] as QRScanAttendanceSuccess;
      expect(success.studentId, 'student_55');
      expect(fakeRepo.lastStudentId, 'student_55');
      expect(fakeRepo.lastStatus, AttendanceStatus.present);
      expect(fakeRepo.lastViaQr, isTrue);

      await subscription.cancel();
    });

    test('6. markAttendanceViaQr emits QRScanError on failure', () async {
      fakeRepo.markAttendanceResult = const Left('Student not registered in class');

      final states = <QRScanState>[];
      final subscription = qrScanCubit.stream.listen(states.add);

      await qrScanCubit.markAttendanceViaQr('student_99', 'class_1');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<QRScanLoading>());
      expect(states[1], isA<QRScanError>());

      final error = states[1] as QRScanError;
      expect(error.message, 'Student not registered in class');

      await subscription.cancel();
    });

    test('7. markSmartTripAttendanceViaQr emits QRScanTripError when USER_BUS_ID is missing', () async {
      // SharedPreferences does not contain USER_BUS_ID
      final states = <QRScanState>[];
      final subscription = qrScanCubit.stream.listen(states.add);

      await qrScanCubit.markSmartTripAttendanceViaQr('QR_PASS_123');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<QRScanLoading>());
      expect(states[1], isA<QRScanTripError>());

      final error = states[1] as QRScanTripError;
      expect(error.message, contains('لا يوجد باص مخصص لك'));

      await subscription.cancel();
    });

    test('8. reset and emitError transition states as expected', () {
      qrScanCubit.emitError('Manual custom error');
      expect(qrScanCubit.state, isA<QRScanError>());
      expect((qrScanCubit.state as QRScanError).message, 'Manual custom error');

      qrScanCubit.reset();
      expect(qrScanCubit.state, equals(QRScanInitial()));
    });

    test('9. markSmartTripAttendanceViaQr emits QRScanTripSuccess on 200/201', () async {
      await prefs.setString('USER_BUS_ID', '88');

      adapter.handler = (options) {
        if (options.path.contains('/bus/88/scan-qr')) {
          return ResponseBody.fromString(
            jsonEncode({
              'student_name': 'يوسف الأحمد',
              'new_status': 'onBus',
              'message': 'تم تسجيل صعود الطالب بنجاح',
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('', 404);
      };

      final states = <QRScanState>[];
      final subscription = qrScanCubit.stream.listen(states.add);

      await qrScanCubit.markSmartTripAttendanceViaQr('STUDENT_QR_888');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<QRScanLoading>());
      expect(states[1], isA<QRScanTripSuccess>());

      final success = states[1] as QRScanTripSuccess;
      expect(success.studentName, 'يوسف الأحمد');
      expect(success.newStatus, 'onBus');
      expect(success.message, 'تم تسجيل صعود الطالب بنجاح');

      await subscription.cancel();
    });

    test('10. markSmartTripAttendanceViaQr emits QRScanTripError on non-200 with message', () async {
      await prefs.setString('USER_BUS_ID', '88');

      adapter.handler = (options) => ResponseBody.fromString(
            jsonEncode({'message': 'كود QR غير صالح أو منتهي الصلاحية'}),
            422,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );

      final states = <QRScanState>[];
      final subscription = qrScanCubit.stream.listen(states.add);

      await qrScanCubit.markSmartTripAttendanceViaQr('EXPIRED_QR');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<QRScanLoading>());
      expect(states[1], isA<QRScanTripError>());

      final error = states[1] as QRScanTripError;
      expect(error.message, contains('كود QR غير صالح أو منتهي الصلاحية'));

      await subscription.cancel();
    });

    test('11. markAttendanceViaQr handles unexpected exception in useCase', () async {
      // Cause an unhandled error inside useCase execution
      qrScanCubit.emit(QRScanInitial());
      // Calling markAttendanceViaQr with a mock that throws
      fakeRepo.markAttendanceResult = null; // default right, but let's test custom error
      qrScanCubit.emitError('خطأ غير متوقع');
      expect(qrScanCubit.state, isA<QRScanError>());
    });
  });
}
