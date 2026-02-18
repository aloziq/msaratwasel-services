import 'package:flutter/material.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

enum InspectionResult { excellent, good, needsReview }

/// Screen for field inspection of buses.
class FieldInspectionScreen extends StatelessWidget {
  const FieldInspectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inspections = [
      _InspectionData(
        'B001',
        'حافلة 1',
        DateTime.now().subtract(const Duration(days: 2)),
        true,
        InspectionResult.excellent,
      ),
      _InspectionData(
        'B002',
        'حافلة 2',
        DateTime.now().subtract(const Duration(days: 5)),
        true,
        InspectionResult.good,
      ),
      _InspectionData(
        'B003',
        'حافلة 3',
        DateTime.now().subtract(const Duration(days: 10)),
        false,
        InspectionResult.needsReview,
      ),
      _InspectionData(
        'B004',
        'حافلة 4',
        DateTime.now().subtract(const Duration(days: 1)),
        true,
        InspectionResult.excellent,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: SupervisorDrawer(
        currentIndex: 5,
        onSelect: (index) => handleSupervisorNavigation(context, index, 5),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            AppSliverHeader(
              title: l10n.fieldInspection,
              showMenu: true,
              trailing: IconButton(
                icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: () => _showNewInspection(context, l10n, isDark),
              ),
            ),

            // Pending Inspections Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pending_actions,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.pendingInspections,
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${inspections.where((i) => !i.passed).length} ${l10n.busesNeedInspection}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Inspections List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.recentInspections,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final inspection = inspections[index];
                  return _InspectionCard(
                    inspection: inspection,
                    l10n: l10n,
                    isDark: isDark,
                  );
                }, childCount: inspections.length),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  void _showNewInspection(
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
      builder: (context) => _NewInspectionSheet(l10n: l10n, isDark: isDark),
    );
  }
}

class _InspectionData {
  final String busId;
  final String busName;
  final DateTime date;
  final bool passed;
  final InspectionResult result;

  _InspectionData(
    this.busId,
    this.busName,
    this.date,
    this.passed,
    this.result,
  );

  String get resultLabel => switch (result) {
    InspectionResult.excellent => 'ممتاز',
    InspectionResult.good => 'جيد',
    InspectionResult.needsReview => 'يحتاج مراجعة',
  };
}

class _InspectionCard extends StatelessWidget {
  const _InspectionCard({
    required this.inspection,
    required this.l10n,
    required this.isDark,
  });

  final _InspectionData inspection;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final resultColor = switch (inspection.result) {
      InspectionResult.excellent => const Color(0xFF16A34A),
      InspectionResult.good => AppColors.primary,
      InspectionResult.needsReview => const Color(0xFFF59E0B),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              inspection.passed ? Icons.check_circle : Icons.warning,
              color: resultColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inspection.busName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(inspection.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              inspection.resultLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: resultColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NewInspectionSheet extends StatefulWidget {
  const _NewInspectionSheet({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  State<_NewInspectionSheet> createState() => _NewInspectionSheetState();
}

class _NewInspectionSheetState extends State<_NewInspectionSheet> {
  String? _selectedBus;
  final Map<String, bool> _checklistItems = {
    'نظافة الحافلة': false,
    'حالة المكيف': false,
    'حالة الإطارات': false,
    'أحزمة الأمان': false,
    'الإسعافات الأولية': false,
    'طفاية الحريق': false,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            widget.l10n.newInspection,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedBus,
            decoration: InputDecoration(
              labelText: widget.l10n.selectBus,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ['حافلة 1', 'حافلة 2', 'حافلة 3', 'حافلة 4']
                .map((bus) => DropdownMenuItem(value: bus, child: Text(bus)))
                .toList(),
            onChanged: (value) => setState(() => _selectedBus = value),
          ),
          const SizedBox(height: 20),
          Text(
            widget.l10n.inspectionChecklist,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ..._checklistItems.entries.map((entry) {
            return CheckboxListTile(
              value: entry.value,
              onChanged: (value) {
                setState(() => _checklistItems[entry.key] = value ?? false);
              },
              title: Text(entry.key),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt),
            label: Text(widget.l10n.takePhotos),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(widget.l10n.inspectionSaved)),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(widget.l10n.saveInspection),
          ),
        ],
      ),
    );
  }
}
