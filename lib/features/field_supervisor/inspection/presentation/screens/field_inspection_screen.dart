import 'package:flutter/material.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/data/field_supervisor_remote_datasource.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

enum InspectionResult { excellent, good, needsReview }

/// Screen for field inspection of buses.
class FieldInspectionScreen extends StatefulWidget {
  const FieldInspectionScreen({super.key});

  @override
  State<FieldInspectionScreen> createState() => _FieldInspectionScreenState();
}

class _FieldInspectionScreenState extends State<FieldInspectionScreen> {
  List<_InspectionData> _inspections = [];
  List<Map<String, dynamic>> _buses = [];
  List<Map<String, dynamic>> _inspectionItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      FieldSupervisorRemoteDataSource.getInspections(),
      FieldSupervisorRemoteDataSource.getBuses(),
      FieldSupervisorRemoteDataSource.getInspectionItems(),
    ]);

    final inspectionsData = results[0];
    final busesData = results[1];
    final itemsData = results[2];

    if (mounted) {
      setState(() {
        _inspections = inspectionsData.map<_InspectionData>((d) {
          return _InspectionData(
            d['bus_id']?.toString() ?? '',
            d['bus_code'] ?? 'N/A',
            DateTime.tryParse(d['created_at'] ?? '') ?? DateTime.now(),
            d['overall_status'] == 'pass',
            _mapResult(d['overall_status']),
            totalItems: d['total_items'] ?? 0,
            passedItems: d['passed_items'] ?? 0,
          );
        }).toList();
        _buses = busesData;
        _inspectionItems = itemsData;
        _isLoading = false;
      });
    }
  }

  InspectionResult _mapResult(String? status) {
    switch (status) {
      case 'pass': return InspectionResult.excellent;
      case 'warning': return InspectionResult.good;
      case 'fail': return InspectionResult.needsReview;
      default: return InspectionResult.good;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: SupervisorDrawer(
        currentIndex: 5,
        onSelect: (index) => handleSupervisorNavigation(context, index, 5),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
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
                                    '${_inspections.where((i) => !i.passed).length} ${l10n.busesNeedInspection}',
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

                    if (_inspections.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                Text('لا توجد تفتيشات مسجلة', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final inspection = _inspections[index];
                          return _InspectionCard(
                            inspection: inspection,
                            l10n: l10n,
                            isDark: isDark,
                          );
                        }, childCount: _inspections.length),
                      ),
                    ),

                    const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                  ],
                ),
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
      builder: (context) => _NewInspectionSheet(
        l10n: l10n,
        isDark: isDark,
        buses: _buses,
        inspectionItems: _inspectionItems,
        onSubmitted: _loadData,
      ),
    );
  }
}

class _InspectionData {
  final String busId;
  final String busName;
  final DateTime date;
  final bool passed;
  final InspectionResult result;
  final int totalItems;
  final int passedItems;

  _InspectionData(
    this.busId,
    this.busName,
    this.date,
    this.passed,
    this.result, {
    this.totalItems = 0,
    this.passedItems = 0,
  });

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
                      '${inspection.date.day}/${inspection.date.month}/${inspection.date.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (inspection.totalItems > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${inspection.passedItems}/${inspection.totalItems}',
                        style: TextStyle(fontSize: 12, color: resultColor, fontWeight: FontWeight.w600),
                      ),
                    ],
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
}

class _NewInspectionSheet extends StatefulWidget {
  const _NewInspectionSheet({
    required this.l10n,
    required this.isDark,
    required this.buses,
    required this.inspectionItems,
    required this.onSubmitted,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final List<Map<String, dynamic>> buses;
  final List<Map<String, dynamic>> inspectionItems;
  final VoidCallback onSubmitted;

  @override
  State<_NewInspectionSheet> createState() => _NewInspectionSheetState();
}

class _NewInspectionSheetState extends State<_NewInspectionSheet> {
  int? _selectedBusId;
  final Map<int, bool> _checklistResults = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize checklist from API items
    for (final item in widget.inspectionItems) {
      final id = int.tryParse(item['id']?.toString() ?? '') ?? 0;
      if (id != 0) {
        _checklistResults[id] = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
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
            DropdownButtonFormField<int>(
              value: _selectedBusId,
              decoration: InputDecoration(
                labelText: widget.l10n.selectBus,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: widget.buses
                  .map((bus) {
                    final busId = int.tryParse(bus['id']?.toString() ?? '') ?? 0;
                    return DropdownMenuItem<int>(
                      value: busId,
                      child: Text((bus['bus_code'] ?? bus['bus_number'] ?? 'حافلة $busId').toString()),
                    );
                  })
                  .toList(),
              onChanged: (value) => setState(() => _selectedBusId = value),
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
            if (widget.inspectionItems.isEmpty)
              Text('لا توجد بنود فحص', style: TextStyle(color: AppColors.textSecondary))
            else
              ...widget.inspectionItems.map((item) {
                final itemId = int.tryParse(item['id']?.toString() ?? '') ?? 0;
                return CheckboxListTile(
                  value: _checklistResults[itemId] ?? false,
                  onChanged: (value) {
                    setState(() => _checklistResults[itemId] = value ?? false);
                  },
                  title: Text((item['name'] ?? '').toString()),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.l10n.saveInspection),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedBusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الحافلة')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final passedCount = _checklistResults.values.where((v) => v).length;
    final totalCount = _checklistResults.length;
    String overallStatus = 'pass';
    if (passedCount < totalCount * 0.5) {
      overallStatus = 'fail';
    } else if (passedCount < totalCount) {
      overallStatus = 'warning';
    }

    final results = _checklistResults.entries
        .map((e) => {'item_id': e.key, 'is_passed': e.value})
        .toList();

    final result = await FieldSupervisorRemoteDataSource.submitInspection(
      busId: _selectedBusId!,
      overallStatus: overallStatus,
      results: results,
    );

    if (mounted) {
      Navigator.pop(context);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.inspectionSaved)),
        );
        widget.onSubmitted();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في حفظ التفتيش')),
        );
      }
    }
  }
}
