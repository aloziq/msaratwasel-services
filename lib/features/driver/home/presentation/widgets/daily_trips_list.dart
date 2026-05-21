import 'package:flutter/material.dart';
import 'package:msaratwasel_services/core/presentation/widgets/directional_icon.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/features/driver/home/domain/entities/trip_status.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:intl/intl.dart';

class DailyTripsList extends StatelessWidget {
  final List<TripStatus> trips;
  final bool isArabic;
  final bool isDark;
  final UserRole userRole;
  final Function(TripStatus) onTripAction;
  final Function(TripStatus) onConfirm;

  const DailyTripsList({
    super.key,
    required this.trips,
    required this.isArabic,
    required this.isDark,
    required this.userRole,
    required this.onTripAction,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        alignment: Alignment.center,
        child: Text(
          isArabic ? 'لا توجد رحلات متبقية اليوم' : 'No more trips today',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    // Sort trips: 
    // 1. Active (non-completed) trips first.
    // 2. Morning ('forth') before Afternoon ('back').
    final sortedTrips = List<TripStatus>.from(trips)..sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      
      // If both have the same completion status, 'forth' comes before 'back'
      if (a.type == 'forth' && b.type != 'forth') return -1;
      if (a.type != 'forth' && b.type == 'forth') return 1;
      
      return 0; // maintain original order otherwise
    });

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTrips.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final trip = sortedTrips[index];
        return _TripListItem(
          trip: trip,
          isArabic: isArabic,
          isDark: isDark,
          userRole: userRole,
          onAction: () => onTripAction(trip),
          onConfirm: () => onConfirm(trip),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1, end: 0);
      },
    );
  }
}

class _TripListItem extends StatelessWidget {
  final TripStatus trip;
  final bool isArabic;
  final bool isDark;
  final UserRole userRole;
  final VoidCallback onAction;
  final VoidCallback onConfirm;

  const _TripListItem({
    required this.trip,
    required this.isArabic,
    required this.isDark,
    required this.userRole,
    required this.onAction,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine status text and color
    String statusText = '';
    Color statusColor = Colors.grey;
    bool actionEnabled = false;
    String actionText = '';

    switch (trip.status) {
      case 'pending':
        statusText = isArabic ? 'جاهز للانطلاق' : 'Pending';
        statusColor = const Color(0xFF2563EB); // Blue
        actionEnabled = true;
        actionText = isArabic ? 'بدء الرحلة' : 'Start Trip';
        break;
      case 'awaiting_confirmation':
        final isSupervisor = userRole == UserRole.assistant || userRole == UserRole.fieldSupervisor;
        statusText = isArabic ? 'بانتظار التأكيد' : 'Awaiting Confirmation';
        statusColor = const Color(0xFFF59E0B); // Orange
        actionEnabled = isSupervisor; 
        actionText = isSupervisor 
            ? (isArabic ? 'قبول وبدء التنفيذ' : 'Accept and Start')
            : (isArabic ? 'بانتظار المشرفة' : 'Waiting...');
        break;
      case 'in_progress':
        statusText = isArabic ? 'الرحلة قيد التشغيل' : 'In Progress';
        statusColor = const Color(0xFF10B981); // Emerald Green
        actionEnabled = true;
        actionText = isArabic ? 'مواصلة الرحلة' : 'Resume Trip';
        break;
      case 'finished':
        statusText = isArabic ? 'مكتملة' : 'Finished';
        statusColor = const Color(0xFF6B7280); // Grey
        actionEnabled = false;
        actionText = isArabic ? 'مكتملة' : 'Completed';
        break;
      default:
        statusText = trip.status;
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF1E293B) : Colors.white,
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Side status indicator strip
              Container(
                width: 6,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Status Badge & Type Badge with ID
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatusBadge(
                            statusText: statusText,
                            statusColor: statusColor,
                            isDark: isDark,
                          ),
                          _TypeBadge(
                            trip: trip,
                            isArabic: isArabic,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      if (trip.routeName != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        // Route Name
                        Text(
                          getLocalizedRouteName(trip.routeName, isArabic),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      // Modern clean divider
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Departure Time & Student Info Boxes
                      Row(
                        children: [
                          Expanded(
                            child: _TripDetailBox(
                              label: isArabic ? 'وقت المغادرة' : 'Departure',
                              value: _formatTime(trip.departureTime, isArabic),
                              icon: PhosphorIconsRegular.clock,
                              iconColor: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _TripDetailBox(
                              label: isArabic ? 'الطلاب' : 'Students',
                              value: trip.totalStudents.toString(),
                              icon: PhosphorIconsRegular.users,
                              iconColor: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      if (trip.status != 'finished') ...[
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: actionEnabled 
                                ? (trip.status == 'awaiting_confirmation' ? onConfirm : onAction)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: isDark 
                                  ? Colors.white.withValues(alpha: 0.12) 
                                  : Colors.grey.withValues(alpha: 0.3),
                              disabledForegroundColor: isDark 
                                  ? Colors.white.withValues(alpha: 0.35) 
                                  : Colors.grey.withValues(alpha: 0.6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  actionText,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                if (actionEnabled) ...[
                                  const SizedBox(width: 8),
                                  const DirectionalIcon(Icons.arrow_forward_rounded, size: 20),
                                ]
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String statusText;
  final Color statusColor;
  final bool isDark;

  const _StatusBadge({
    required this.statusText,
    required this.statusColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusText.contains('مكتملة') || statusText.toLowerCase().contains('finish') || statusText.toLowerCase().contains('complete')
                ? PhosphorIconsFill.checkCircle
                : PhosphorIconsFill.clock,
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final TripStatus trip;
  final bool isArabic;
  final bool isDark;

  const _TypeBadge({
    required this.trip,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isGo = trip.type == 'forth' || trip.typeLabel == 'ذهاب' || trip.typeLabel.toLowerCase() == 'go' || trip.typeLabel.toLowerCase() == 'forth';
    final typeColor = isGo ? const Color(0xFF2563EB) : const Color(0xFF8B5CF6);
    final label = getLocalizedType(trip.type, trip.typeLabel, isArabic);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGo ? PhosphorIconsFill.student : PhosphorIconsFill.houseLine,
            size: 14,
            color: typeColor,
          ),
          const SizedBox(width: 6),
          Text(
            '$label #${trip.id}',
            style: TextStyle(
              color: typeColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripDetailBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _TripDetailBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String getLocalizedType(String type, String typeLabel, bool isArabic) {
  if (isArabic) {
    if (type == 'forth' || typeLabel == 'ذهاب' || typeLabel.toLowerCase() == 'go' || typeLabel.toLowerCase() == 'forth') {
      return 'ذهاب';
    } else {
      return 'إياب';
    }
  } else {
    if (type == 'forth' || typeLabel == 'ذهاب' || typeLabel.toLowerCase() == 'go' || typeLabel.toLowerCase() == 'forth') {
      return 'Go';
    } else {
      return 'Return';
    }
  }
}

String getLocalizedRouteName(String? name, bool isArabic) {
  if (name == null) {
    return isArabic ? 'بدون مسار' : 'No Route';
  }
  if (isArabic) {
    return name
        .replaceAll(RegExp(r'Route\s+No\.?\s*', caseSensitive: false), 'المسار رقم ')
        .replaceAll(RegExp(r'Route\s*', caseSensitive: false), 'مسار ')
        .replaceAll(RegExp(r'No\.?\s*', caseSensitive: false), 'رقم ');
  } else {
    return name
        .replaceAll('المسار رقم', 'Route No.')
        .replaceAll('مسار رقم', 'Route No.')
        .replaceAll('مسار', 'Route');
  }
}

String _formatTime(String timeStr, bool isArabic) {
  try {
    DateTime dateTime;
    if (timeStr.contains('T')) {
      dateTime = DateTime.parse(timeStr).toLocal();
    } else {
      final parts = timeStr.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final now = DateTime.now();
      dateTime = DateTime(now.year, now.month, now.day, hours, minutes);
    }
    final timeFormat = DateFormat('hh:mm');
    final timeOnly = timeFormat.format(dateTime);
    final amPm = DateFormat('a').format(dateTime); // "AM" or "PM"
    if (isArabic) {
      final amPmAr = amPm == 'AM' ? 'ص' : 'م';
      return '$timeOnly $amPmAr';
    } else {
      return '$timeOnly $amPm';
    }
  } catch (e) {
    String result = timeStr;
    if (isArabic) {
      result = result.replaceAll('PM', 'م').replaceAll('AM', 'ص');
    }
    return result;
  }
}
