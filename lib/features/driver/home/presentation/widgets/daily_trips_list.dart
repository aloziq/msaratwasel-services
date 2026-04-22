import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/features/driver/home/domain/entities/trip_status.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DailyTripsList extends StatelessWidget {
  final List<TripStatus> trips;
  final bool isArabic;
  final bool isDark;
  final Function(TripStatus) onTripAction;

  const DailyTripsList({
    super.key,
    required this.trips,
    required this.isArabic,
    required this.isDark,
    required this.onTripAction,
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _TripListItem(
          trip: trip,
          isArabic: isArabic,
          isDark: isDark,
          onAction: () => onTripAction(trip),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1, end: 0);
      },
    );
  }
}

class _TripListItem extends StatelessWidget {
  final TripStatus trip;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onAction;

  const _TripListItem({
    required this.trip,
    required this.isArabic,
    required this.isDark,
    required this.onAction,
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
        statusColor = theme.colorScheme.primary;
        actionEnabled = true;
        actionText = isArabic ? 'بدء الرحلة' : 'Start Trip';
        break;
      case 'awaiting_confirmation':
        statusText = isArabic ? 'بانتظار التأكيد' : 'Awaiting Confirmation';
        statusColor = Colors.orange;
        actionEnabled = false; // Cannot start until confirmed by supervisor
        actionText = isArabic ? 'بانتظار المشرفة' : 'Waiting...';
        break;
      case 'in_progress':
        statusText = isArabic ? 'الرحلة قيد التشغيل' : 'In Progress';
        statusColor = Colors.green;
        actionEnabled = true;
        actionText = isArabic ? 'مواصلة الرحلة' : 'Resume Trip';
        break;
      case 'finished':
        statusText = isArabic ? 'مكتملة' : 'Finished';
        statusColor = Colors.grey;
        actionEnabled = false;
        actionText = isArabic ? 'مكتملة' : 'Completed';
        break;
      default:
        statusText = trip.status;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF1E293B) : Colors.white,
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? statusColor.withOpacity(0.2) : statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${trip.typeLabel} #${trip.id}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    trip.type == 'back' ? PhosphorIconsFill.houseLine : PhosphorIconsFill.student,
                    color: isDark ? Colors.white : theme.colorScheme.primary,
                    size: 28,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _TripInfoItem(
                  label: isArabic ? 'وقت المغادرة' : 'Departure',
                  value: trip.departureTime,
                  icon: PhosphorIconsRegular.clock,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TripInfoItem(
                  label: isArabic ? 'الطلاب' : 'Students',
                  value: trip.totalStudents.toString(),
                  icon: PhosphorIconsRegular.users,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
            ],
          ),
          if (trip.routeName != null) ...[
             const SizedBox(height: AppSpacing.md),
             Row(
                children: [
                  Icon(PhosphorIconsRegular.mapPin, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    trip.routeName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
             ),
          ],
          if (trip.status != 'finished') ...[
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: actionEnabled ? onAction : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
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
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TripInfoItem extends StatelessWidget {
  const _TripInfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.isArabic,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white54
                      : theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
