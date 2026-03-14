import 'package:intl/intl.dart';

class LocationUtils {
  /// Speed constant in km/h as requested by the user
  static const double speedKmPerHour = 80.0;

  /// Calculates ETA in minutes from distance in km
  static double calculateEtaMinutes(double distanceKm) {
    return (distanceKm / speedKmPerHour) * 60.0;
  }

  /// Calculates rounded ETA in minutes from distance in km
  static int calculateEtaMinutesRounded(double distanceKm) {
    return ((distanceKm / speedKmPerHour) * 60.0).round();
  }

  /// Formats ETA in Arabic (e.g., "1 ساعة و 15 دقيقة" or "15 دقيقة")
  static String formatEtaArabic(double distanceKm) {
    final totalMinutes = calculateEtaMinutesRounded(distanceKm);

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      if (minutes == 0) {
        return '$hours ساعة';
      }
      return '$hours ساعة و $minutes دقيقة';
    }
    return '$minutes دقيقة';
  }
  
  /// Formats ETA in English
  static String formatEtaEnglish(double distanceKm) {
    final totalMinutes = calculateEtaMinutesRounded(distanceKm);

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      if (minutes == 0) {
        return '$hours hr';
      }
      return '$hours hr $minutes min';
    }
    return '$minutes min';
  }
}
