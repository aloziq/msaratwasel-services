import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:msaratwasel_services/core/utils/location_utils.dart';
import 'package:msaratwasel_services/core/utils/active_conversation_tracker.dart';
import 'package:msaratwasel_services/core/utils/date_utils.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/core/responsive/api_language_interceptor.dart';
import 'package:msaratwasel_services/core/services/direction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en', null);
  });

  group('LocationUtils Comprehensive Mathematics & Formatter Suite', () {
    test('1. calculateDistance handles identical points, symmetry, and realistic Muscat coords', () {
      // Identical coordinates
      final zeroDist = LocationUtils.calculateDistance(23.5880, 58.3829, 23.5880, 58.3829);
      expect(zeroDist, closeTo(0.0, 0.001));

      // Muscat points
      final lat1 = 23.5880;
      final lon1 = 58.3829;
      final lat2 = 23.5900;
      final lon2 = 58.3850;

      final distForward = LocationUtils.calculateDistance(lat1, lon1, lat2, lon2);
      final distBackward = LocationUtils.calculateDistance(lat2, lon2, lat1, lon1);

      // Distance should be around 312 meters
      expect(distForward, greaterThan(250.0));
      expect(distForward, lessThan(350.0));

      // Symmetry
      expect(distForward, closeTo(distBackward, 0.0001));
    });

    test('2. calculateEtaMinutes and calculateEtaMinutesRounded calculate correctly at 80 km/h', () {
      expect(LocationUtils.speedKmPerHour, 80.0);

      // 80 km distance -> exactly 60 minutes
      expect(LocationUtils.calculateEtaMinutes(80.0), 60.0);
      expect(LocationUtils.calculateEtaMinutesRounded(80.0), 60);

      // 40 km distance -> exactly 30 minutes
      expect(LocationUtils.calculateEtaMinutes(40.0), 30.0);
      expect(LocationUtils.calculateEtaMinutesRounded(40.0), 30);

      // 20 km distance -> 15 minutes
      expect(LocationUtils.calculateEtaMinutes(20.0), 15.0);
      expect(LocationUtils.calculateEtaMinutesRounded(20.0), 15);

      // 0 km distance -> 0 minutes
      expect(LocationUtils.calculateEtaMinutes(0.0), 0.0);
      expect(LocationUtils.calculateEtaMinutesRounded(0.0), 0);
    });

    test('3. formatEtaArabic formats minutes, exact hours, and composite hour/minutes correctly', () {
      // 0 km -> 0 دقيقة
      expect(LocationUtils.formatEtaArabic(0.0), '0 دقيقة');

      // 20 km -> 15 دقيقة
      expect(LocationUtils.formatEtaArabic(20.0), '15 دقيقة');

      // 80 km -> 1 ساعة
      expect(LocationUtils.formatEtaArabic(80.0), '1 ساعة');

      // 100 km -> 75 min = 1 ساعة و 15 دقيقة
      expect(LocationUtils.formatEtaArabic(100.0), '1 ساعة و 15 دقيقة');

      // 160 km -> 120 min = 2 ساعة
      expect(LocationUtils.formatEtaArabic(160.0), '2 ساعة');
    });

    test('4. formatEtaEnglish formats minutes, exact hours, and composite hour/minutes correctly', () {
      // 0 km -> 0 min
      expect(LocationUtils.formatEtaEnglish(0.0), '0 min');

      // 20 km -> 15 min
      expect(LocationUtils.formatEtaEnglish(20.0), '15 min');

      // 80 km -> 1 hr
      expect(LocationUtils.formatEtaEnglish(80.0), '1 hr');

      // 100 km -> 1 hr 15 min
      expect(LocationUtils.formatEtaEnglish(100.0), '1 hr 15 min');

      // 160 km -> 2 hr
      expect(LocationUtils.formatEtaEnglish(160.0), '2 hr');
    });
  });

  group('ActiveConversationTracker Suite', () {
    test('5. tracks active conversation state and clears cleanly', () {
      // Clear initially
      ActiveConversationTracker.clearActiveConversation();
      expect(ActiveConversationTracker.activeConversationId, isNull);

      // Set conversation
      ActiveConversationTracker.setActiveConversation('conv-12345');
      expect(ActiveConversationTracker.activeConversationId, 'conv-12345');

      // Update conversation
      ActiveConversationTracker.setActiveConversation('conv-67890');
      expect(ActiveConversationTracker.activeConversationId, 'conv-67890');

      // Clear conversation
      ActiveConversationTracker.clearActiveConversation();
      expect(ActiveConversationTracker.activeConversationId, isNull);
    });
  });

  group('Date & Time Formatting Utilities Suite', () {
    test('6. formatDate and formatTime formats dates across Arabic and English locales', () {
      final sampleDate = DateTime(2026, 9, 4, 14, 30);

      // English formatting
      final enDate = formatDate(sampleDate, locale: 'en');
      expect(enDate, contains('September 4, 2026'));

      // Arabic formatting
      final arDate = formatDate(sampleDate, locale: 'ar');
      expect(arDate, isNotEmpty);
      expect(arDate, contains('2026'));

      // Time formatting (2:30 PM)
      final enTime = formatTime(sampleDate, locale: 'en');
      expect(enTime, contains('2:30'));

      final arTime = formatTime(sampleDate, locale: 'ar');
      expect(arTime, contains('2:30'));
    });
  });

  group('ApiLanguageInterceptor Suite', () {
    test('7. injects standard Accept and Accept-Language headers into Dio request', () {
      final interceptor = ApiLanguageInterceptor();
      final options = RequestOptions(path: '/api/v1/test');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['Accept'], 'application/json');
      expect(options.headers.containsKey('Accept-Language'), isTrue);
      expect(options.headers['Accept-Language'], isNotEmpty);
    });
  });

  group('Failure Domain Models Hierarchy Suite', () {
    test('8. Failure subclasses preserve messages and value equality via Equatable', () {
      const f1 = ServerFailure('خطأ في السيرفر');
      const f2 = ServerFailure('خطأ في السيرفر');
      const f3 = ServerFailure('خطأ آخر');

      expect(f1, equals(f2));
      expect(f1, isNot(equals(f3)));
      expect(f1.props, ['خطأ في السيرفر']);

      const netFail = NetworkFailure('لا يوجد اتصال');
      expect(netFail.message, 'لا يوجد اتصال');

      const valFail = ValidationFailure('البيانات غير مكتملة');
      expect(valFail.message, 'البيانات غير مكتملة');

      const authFail = AuthFailure('انتهت الجلسة');
      expect(authFail.message, 'انتهت الجلسة');

      const cacheFail = CacheFailure('فشل القراءة من الكاش');
      expect(cacheFail.message, 'فشل القراءة من الكاش');
    });
  });

  group('DirectionService Cache Operations Suite', () {
    test('9. DirectionService clearCache operates cleanly', () {
      final service = DirectionService();
      // Service instantiated and cache cleared
      service.clearCache();
      expect(service, isNotNull);
    });
  });
}
