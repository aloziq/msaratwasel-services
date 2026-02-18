/// Shared time formatting utilities for the Field Supervisor module.
String formatRelativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inMinutes < 60) {
    return 'منذ ${diff.inMinutes} دقيقة';
  } else if (diff.inHours < 24) {
    return 'منذ ${diff.inHours} ساعة';
  } else {
    return 'منذ ${diff.inDays} يوم';
  }
}

/// Compact relative time (e.g. "10د", "3س", "1ي").
String formatRelativeTimeCompact(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inMinutes < 60) return '${diff.inMinutes}د';
  if (diff.inHours < 24) return '${diff.inHours}س';
  return '${diff.inDays}ي';
}
