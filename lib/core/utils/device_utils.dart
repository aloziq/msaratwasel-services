import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceUtils {
  static DeviceInfoPlugin? testDeviceInfo;

  static Future<String> getDeviceName() async {
    final deviceInfo = testDeviceInfo ?? DeviceInfoPlugin();
    
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return 'Web: ${webInfo.browserName.name}';
      }
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model} (${androidInfo.id})';
      }
      
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      }
      
      return Platform.operatingSystem;
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return 'Unknown Device';
    }
  }

  static Future<String?> getDeviceId() async {
    final deviceInfo = testDeviceInfo ?? DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return webInfo.userAgent;
      }
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      }
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return null;
    }
  }
}
