import 'package:flutter/material.dart';
import 'package:msaratwasel_services/core/presentation/widgets/directional_icon.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TripStatusCard extends StatelessWidget {
  final bool isArabic;
  final bool isDark;
  final String departureTime;
  final String studentCount;
  final bool isStarted;
  final String tripId;
  final VoidCallback onStartTrip;

  const TripStatusCard({
    super.key,
    required this.isArabic,
    required this.isDark,
    required this.departureTime,
    required this.studentCount,
    required this.tripId,
    required this.isStarted,
    required this.onStartTrip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isStarted
                      ? (isArabic ? 'الرحلة قيد التشغيل' : 'Trip in Progress')
                      : (isArabic ? 'جاهز للانطلاق' : 'Ready to Start'),
                  style: TextStyle(
                    color: isDark ? Colors.white : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$tripId',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    PhosphorIconsFill.steeringWheel,
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
                  value: departureTime,
                  icon: PhosphorIconsRegular.clock,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TripInfoItem(
                  label: isArabic ? 'الطلاب' : 'Students',
                  value: studentCount,
                  icon: PhosphorIconsRegular.student,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStartTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
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
                    isStarted
                        ? (isArabic ? 'مواصلة الرحلة' : 'Resume Trip')
                        : (isArabic ? 'بدء الرحلة' : 'Start Trip'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const DirectionalIcon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
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
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
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
