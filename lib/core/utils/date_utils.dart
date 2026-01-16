import 'package:intl/intl.dart';

/// Format a date for display in chat date separators.
String formatDate(DateTime date, {String locale = 'en'}) {
  final format = locale == 'ar'
      ? DateFormat('d MMMM yyyy', 'ar')
      : DateFormat('MMMM d, yyyy', 'en');
  return format.format(date);
}

/// Format time for display in message bubbles.
String formatTime(DateTime time, {String locale = 'en'}) {
  final format = locale == 'ar'
      ? DateFormat('h:mm a', 'ar')
      : DateFormat('h:mm a', 'en');
  return format.format(time);
}
