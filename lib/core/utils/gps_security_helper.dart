import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GpsSecurityHelper {
  /// Checks if GPS is enabled and permissions are granted.
  /// If not, shows a descriptive premium dialog to the driver and returns false.
  static Future<bool> checkLocationServices(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.gps_off_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'خدمة الموقع مغلقة' : 'GPS Service Disabled',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            isArabic
                ? 'يرجى تشغيل خدمة الموقع (GPS) في هاتفك للتمكن من الانتقال للرحلة وتتبع خط سير الحافلة.'
                : 'Please enable GPS/Location services on your device to be able to access the trip and track the bus.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              child: Text(isArabic ? 'فتح الإعدادات' : 'Open Settings'),
            ),
          ],
        ),
      );
      return false;
    }

    // 2. Check location permissions
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.security_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'إذن الموقع مطلوب' : 'Location Permission Required',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            isArabic
                ? 'إذن الوصول إلى الموقع تم رفضه نهائياً. يرجى تفعيله يدوياً من إعدادات التطبيق لكي تتمكن من الوصول للرحلة.'
                : 'Location permission is permanently denied. Please enable it from app settings to access the trip.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text(isArabic ? 'فتح الإعدادات' : 'Open Settings'),
            ),
          ],
        ),
      );
      return false;
    }

    if (!status.isGranted) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic
              ? 'يجب منح إذن الوصول إلى الموقع للوصول للرحلة.'
              : 'Location permission must be granted to access the trip.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }
}
