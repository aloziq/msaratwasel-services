import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/features/driver/maintenance/data/repositories/maintenance_repository_impl.dart';

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
      jsonEncode({'data': []}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHttpAdapter adapter;
  late Dio testDio;
  late MaintenanceRepositoryImpl repository;

  setUp(() {
    adapter = _FakeHttpAdapter();
    testDio = Dio(BaseOptions(baseUrl: 'https://api.test.com/'));
    testDio.httpClientAdapter = adapter;
    ApiClient.testDio = testDio;

    repository = MaintenanceRepositoryImpl();
  });

  tearDown(() {
    ApiClient.testDio = null;
  });

  group('MaintenanceRepositoryImpl - getExpenses', () {
    test('1. getExpenses success 200 parses list of BusExpenseModel', () async {
      adapter.handler = (options) {
        expect(options.path, '/driver/expenses');
        expect(options.queryParameters['page'], 2);

        final json = {
          'data': [
            {
              'id': 101,
              'bus_id': 42,
              'type': 'fuel',
              'amount': 250.0,
              'date': '2026-09-04T10:00:00.000Z',
              'extra_info': '60000',
              'receipt_photo': 'uploads/receipt.jpg',
            }
          ]
        };

        return ResponseBody.fromString(
          jsonEncode(json),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final results = await repository.getExpenses(page: 2);
      expect(results.length, 1);
      expect(results.first.id, 101);
      expect(results.first.type, 'fuel');
      expect(results.first.amount, 250.0);
    });

    test('2. getExpenses non-200 status throws Exception', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'error': 'server error'}),
          500,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await expectLater(
        repository.getExpenses(),
        throwsA(isA<Exception>()),
      );
    });

    test('3. getExpenses DioException extracts custom server message', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Invalid session token'}),
          401,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await expectLater(
        repository.getExpenses(),
        throwsA(predicate((e) => e.toString().contains('Invalid session token'))),
      );
    });
  });

  group('MaintenanceRepositoryImpl - submitFuelRefill', () {
    test('4. submitFuelRefill success 201 completes without error and supports photo upload', () async {
      final tempDir = Directory.systemTemp.createTempSync('fuel_test_');
      final tempFile = File('${tempDir.path}/fuel_receipt.jpg');
      tempFile.writeAsStringSync('mock receipt image bytes');

      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          201,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      try {
        await repository.submitFuelRefill(
          amount: 120.50,
          odometer: 48000,
          date: DateTime(2026, 9, 4),
          photoPath: tempFile.path,
        );

        expect(capturedOptions, isNotNull);
        expect(capturedOptions!.path, '/driver/expenses');
        expect(capturedOptions!.data, isA<FormData>());
      } finally {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('5. submitFuelRefill non-200/201 status throws Exception', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'error': 'bad request'}),
          400,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await expectLater(
        repository.submitFuelRefill(
          amount: 50.0,
          odometer: 10000,
          date: DateTime(2026, 9, 4),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('MaintenanceRepositoryImpl - submitMaintenanceRequest', () {
    test('6. submitMaintenanceRequest success 200 completes without error and supports photo upload', () async {
      final tempDir = Directory.systemTemp.createTempSync('maint_test_');
      final tempFile = File('${tempDir.path}/maint_receipt.jpg');
      tempFile.writeAsStringSync('mock maint photo bytes');

      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      try {
        await repository.submitMaintenanceRequest(
          description: 'Engine oil replacement and filters',
          date: DateTime(2026, 9, 4),
          cost: 450.0,
          photoPath: tempFile.path,
        );

        expect(capturedOptions, isNotNull);
        expect(capturedOptions!.path, '/driver/expenses');
        expect(capturedOptions!.data, isA<FormData>());
      } finally {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('7. submitMaintenanceRequest DioException throws backend error message', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Bus not registered to this driver'}),
          422,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      await expectLater(
        repository.submitMaintenanceRequest(
          description: 'Flat tire fix',
          date: DateTime(2026, 9, 4),
        ),
        throwsA(predicate((e) => e.toString().contains('Bus not registered to this driver'))),
      );
    });
  });
}
