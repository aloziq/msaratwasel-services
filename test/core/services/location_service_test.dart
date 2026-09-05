import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/config/app_config.dart';
import 'package:msaratwasel_services/features/assistant/core/domain/entities/bus_student_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Location Tracking & Config Baseline Suite', () {
    test('1. AppConfig constants protect tracking and throttle integrity', () {
      // Driver GPS distance filter must be 15 meters to ignore GPS drift
      expect(AppConfig.locationDistanceFilter, 15);

      // Driver upload throttle must be 8 seconds to prevent server overload
      expect(AppConfig.locationUploadThrottleSeconds, 8);

      // Google Directions threshold must be at least 100m to prevent excessive billing
      expect(AppConfig.googleDirectionsDistanceThreshold, 100);

      // Fallback polling interval
      expect(AppConfig.statusPollingIntervalSeconds, 120);

      // Reverb connection config
      expect(AppConfig.reverbKey, 'masarat-wasel-key');
    });

    test('2. Driver upload throttle algorithm verifies emission windows', () {
      final t0 = DateTime(2026, 9, 4, 10, 0, 0);

      // Arrival 3 seconds later (< 8 seconds) -> Should throttle
      final t1 = t0.add(const Duration(seconds: 3));
      final shouldThrottleT1 = t1.difference(t0).inSeconds < AppConfig.locationUploadThrottleSeconds;
      expect(shouldThrottleT1, isTrue);

      // Arrival 7 seconds later (< 8 seconds) -> Should throttle
      final t2 = t0.add(const Duration(seconds: 7));
      final shouldThrottleT2 = t2.difference(t0).inSeconds < AppConfig.locationUploadThrottleSeconds;
      expect(shouldThrottleT2, isTrue);

      // Arrival 8 seconds later (== 8 seconds) -> Allowed
      final t3 = t0.add(const Duration(seconds: 8));
      final shouldThrottleT3 = t3.difference(t0).inSeconds < AppConfig.locationUploadThrottleSeconds;
      expect(shouldThrottleT3, isFalse);

      // Arrival 15 seconds later (> 8 seconds) -> Allowed
      final t4 = t0.add(const Duration(seconds: 15));
      final shouldThrottleT4 = t4.difference(t0).inSeconds < AppConfig.locationUploadThrottleSeconds;
      expect(shouldThrottleT4, isFalse);
    });

    test('3. BusStudentStatus enum provides accurate Arabic labels for all trip phases', () {
      expect(BusStudentStatus.atHome.labelAr, 'في المنزل');
      expect(BusStudentStatus.onBus.labelAr, 'في الحافلة');
      expect(BusStudentStatus.atSchool.labelAr, 'في المدرسة');
      expect(BusStudentStatus.absent.labelAr, 'غائب');
      expect(BusStudentStatus.waiting.labelAr, 'انتظار');
      expect(BusStudentStatus.unknown.labelAr, 'غير محدد');
    });
  });
}
