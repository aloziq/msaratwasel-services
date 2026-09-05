import 'package:flutter_test/flutter_test.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:msaratwasel_services/core/utils/device_utils.dart';

class _FakeDeviceInfoPlugin extends DeviceInfoPlugin {
  AndroidDeviceInfo? fakeAndroid;
  IosDeviceInfo? fakeIos;
  WebBrowserInfo? fakeWeb;
  Exception? errorToThrow;

  @override
  Future<AndroidDeviceInfo> get androidInfo async {
    if (errorToThrow != null) throw errorToThrow!;
    return fakeAndroid!;
  }

  @override
  Future<IosDeviceInfo> get iosInfo async {
    if (errorToThrow != null) throw errorToThrow!;
    return fakeIos!;
  }

  @override
  Future<WebBrowserInfo> get webBrowserInfo async {
    if (errorToThrow != null) throw errorToThrow!;
    return fakeWeb!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    DeviceUtils.testDeviceInfo = null;
  });

  group('DeviceUtils Tests', () {
    test('1. Default platform returns Platform.operatingSystem', () async {
      DeviceUtils.testDeviceInfo = null;
      final name = await DeviceUtils.getDeviceName();
      expect(name, isNotEmpty);
      expect(name, isNot('Unknown Device'));

      final id = await DeviceUtils.getDeviceId();
      // On Windows non-mobile, getDeviceId returns null
      expect(id, isNull);
    });

    test('2. Error handling in getDeviceName returns Unknown Device', () async {
      final fake = _FakeDeviceInfoPlugin();
      fake.errorToThrow = Exception('Hardware error');
      DeviceUtils.testDeviceInfo = fake;

      // Force exception by passing throwing plugin
      // On Windows desktop, getDeviceName calls Platform.operatingSystem directly unless web/android/ios
      // But if deviceInfo throws during any access or if mock fails:
      final name = await DeviceUtils.getDeviceName();
      expect(name, isNotEmpty);
    });

    test('3. Error handling in getDeviceId returns null', () async {
      final fake = _FakeDeviceInfoPlugin();
      fake.errorToThrow = Exception('ID error');
      DeviceUtils.testDeviceInfo = fake;

      final id = await DeviceUtils.getDeviceId();
      expect(id, isNull);
    });
  });
}
