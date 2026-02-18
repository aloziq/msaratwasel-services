import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

/// Helper class for getting localized status strings.
///
/// Use this to convert status keys to localized display strings.
///
/// Example:
/// ```dart
/// final displayStatus = LocalizationHelper.getStatusText(l10n, 'active');
/// // Returns "نشط" in Arabic or "Active" in English
/// ```
class LocalizationHelper {
  /// Converts a status key to a localized status string.
  static String getStatusText(AppLocalizations l10n, String statusKey) {
    return switch (statusKey) {
      'active' => l10n.statusActive,
      'stopped' => l10n.statusStopped,
      'completed' => l10n.statusCompleted,
      'in_progress' => l10n.statusInProgress,
      'scheduled' => l10n.statusScheduled,
      'maintenance' => l10n.statusMaintenance,
      'excellent' => l10n.statusExcellent,
      'good' => l10n.statusGood,
      'pending' => l10n.statusPending,
      _ => statusKey, // Return the key as-is if not found
    };
  }

  /// Converts a type key to a localized type string.
  static String getTypeText(AppLocalizations l10n, String typeKey) {
    return switch (typeKey) {
      'technical' => l10n.typeTechnical,
      'behavioral' => l10n.typeBehavioral,
      'health' => l10n.typeHealth,
      'traffic' => l10n.typeTraffic,
      'sos' => l10n.typeSOS,
      _ => typeKey,
    };
  }

  /// Converts a role key to a localized role string.
  static String getRoleText(AppLocalizations l10n, String roleKey) {
    return switch (roleKey) {
      'admin' => l10n.roleAdmin,
      'driver' => l10n.roleDriver,
      _ => roleKey,
    };
  }

  /// Gets the attendance status text.
  static String getAttendanceText(AppLocalizations l10n, String key) {
    return switch (key) {
      'present' => l10n.present,
      'absent' => l10n.absent,
      'late' => l10n.late,
      _ => key,
    };
  }
}
