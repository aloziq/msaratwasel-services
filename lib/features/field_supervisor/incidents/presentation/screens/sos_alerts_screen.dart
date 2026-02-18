import 'package:flutter/material.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/time_formatter.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

enum IncidentType { sos, technical, behavioral, health, traffic }

enum IncidentStatus { inProgress, resolved }

/// Screen for SOS alerts and incidents management.
class SosAlertsScreen extends StatelessWidget {
  const SosAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final incidents = [
      _IncidentData(
        'I001',
        IncidentType.sos,
        'طوارئ - حافلة B001',
        DateTime.now().subtract(const Duration(minutes: 5)),
        true,
        IncidentStatus.inProgress,
      ),
      _IncidentData(
        'I002',
        IncidentType.technical,
        'عطل في التكييف',
        DateTime.now().subtract(const Duration(hours: 2)),
        false,
        IncidentStatus.resolved,
      ),
      _IncidentData(
        'I003',
        IncidentType.behavioral,
        'مشاجرة بين طلاب',
        DateTime.now().subtract(const Duration(hours: 5)),
        false,
        IncidentStatus.resolved,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: SupervisorDrawer(
        currentIndex: 4,
        onSelect: (index) => handleSupervisorNavigation(context, index, 4),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            AppSliverHeader(
              title: l10n.incidentsAndEmergencies,
              showMenu: true,
              trailing: IconButton(
                icon: const Icon(Icons.add_alert, color: AppColors.error),
                onPressed: () {
                  _showNewIncidentDialog(context, l10n, isDark);
                },
              ),
            ),

            // Active SOS Alert Banner
            if (incidents.any((i) => i.isUrgent))
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.sos,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.activeEmergency,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              incidents.firstWhere((i) => i.isUrgent).title,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(l10n.respond),
                      ),
                    ],
                  ),
                ),
              ),

            // Section Title
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.allIncidents,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // Incidents List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final incident = incidents[index];
                  return _IncidentCard(
                    incident: incident,
                    l10n: l10n,
                    isDark: isDark,
                  );
                }, childCount: incidents.length),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  void _showNewIncidentDialog(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _NewIncidentSheet(l10n: l10n, isDark: isDark),
      ),
    );
  }
}

class _IncidentData {
  final String id;
  final IncidentType type;
  final String title;
  final DateTime time;
  final bool isUrgent;
  final IncidentStatus status;

  _IncidentData(
    this.id,
    this.type,
    this.title,
    this.time,
    this.isUrgent,
    this.status,
  );

  String get typeLabel => switch (type) {
    IncidentType.sos => 'SOS',
    IncidentType.technical => 'تقني',
    IncidentType.behavioral => 'سلوكي',
    IncidentType.health => 'صحي',
    IncidentType.traffic => 'مروري',
  };

  String get statusLabel => switch (status) {
    IncidentStatus.inProgress => 'قيد المعالجة',
    IncidentStatus.resolved => 'تم الحل',
  };
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.l10n,
    required this.isDark,
  });

  final _IncidentData incident;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final typeColor = switch (incident.type) {
      IncidentType.sos => AppColors.error,
      IncidentType.technical => const Color(0xFFF59E0B),
      IncidentType.behavioral => const Color(0xFF7C3AED),
      _ => AppColors.primary,
    };

    final statusColor = incident.status == IncidentStatus.resolved
        ? const Color(0xFF16A34A)
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: incident.isUrgent
              ? AppColors.error.withValues(alpha: 0.3)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              incident.type == IncidentType.sos
                  ? Icons.sos
                  : incident.type == IncidentType.technical
                  ? Icons.build
                  : Icons.warning,
              color: typeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        incident.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        incident.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  incident.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(incident.time),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return formatRelativeTime(incident.time);
  }
}

class _NewIncidentSheet extends StatefulWidget {
  const _NewIncidentSheet({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  State<_NewIncidentSheet> createState() => _NewIncidentSheetState();
}

class _NewIncidentSheetState extends State<_NewIncidentSheet> {
  String _selectedType = 'سلوكي';
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.l10n.newIncident,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.l10n.incidentType,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['SOS', 'سلوكي', 'صحي', 'تقني', 'مروري'].map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedType = type);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: widget.l10n.incidentDescription,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt),
            label: Text(widget.l10n.attachPhoto),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(widget.l10n.incidentReported)),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(widget.l10n.sendUrgentReport),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
