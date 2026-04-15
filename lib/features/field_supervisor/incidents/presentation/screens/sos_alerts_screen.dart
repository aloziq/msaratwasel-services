import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/data/field_supervisor_remote_datasource.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/time_formatter.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

/// Screen for SOS alerts and incidents management.
/// Supports 5 types: SOS, behavioral, health, technical, traffic
/// With role-based notification routing.
class SosAlertsScreen extends StatefulWidget {
  const SosAlertsScreen({super.key});

  @override
  State<SosAlertsScreen> createState() => _SosAlertsScreenState();
}

class _SosAlertsScreenState extends State<SosAlertsScreen> {
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await FieldSupervisorRemoteDataSource.getIncidents();
    if (mounted)
      setState(() {
        _incidents = data;
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: SupervisorDrawer(
        currentIndex: 4,
        onSelect: (index) => handleSupervisorNavigation(context, index, 4),
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
                      title: l10n.incidentsAndEmergencies,
                      showMenu: true,
                      trailing: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFDC2626,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notification_add_rounded,
                            color: Color(0xFFDC2626),
                            size: 22,
                          ),
                        ),
                        onPressed: () =>
                            _showNewIncidentSheet(context, l10n, isDark),
                      ),
                    ),

                    // Active emergency banner
                    if (_hasActiveEmergency())
                      SliverToBoxAdapter(
                        child: _ActiveEmergencyBanner(
                          incident: _getActiveEmergency()!,
                          l10n: l10n,
                          isDark: isDark,
                          onRespond: () {},
                        ),
                      ),

                    // Section title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          l10n.allIncidents,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),

                    // Incidents list
                    _incidents.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.green.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'لا توجد حوادث مسجلة',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.textSecondary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _IncidentCard(
                                incident: _incidents[index],
                                l10n: l10n,
                                isDark: isDark,
                              ),
                              childCount: _incidents.length,
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  bool _hasActiveEmergency() {
    return _incidents.any(
      (i) =>
          i['status'] == 'pending' &&
          (i['type'] == 'sos' || i['severity'] == 'critical'),
    );
  }

  Map<String, dynamic>? _getActiveEmergency() {
    try {
      return _incidents.firstWhere(
        (i) =>
            i['status'] == 'pending' &&
            (i['type'] == 'sos' || i['severity'] == 'critical'),
      );
    } catch (_) {
      return null;
    }
  }

  void _showNewIncidentSheet(
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
      builder: (context) =>
          _NewIncidentSheet(l10n: l10n, isDark: isDark, onSubmitted: _loadData),
    );
  }
}

// ─── Active Emergency Banner ──────────────────────────────────────
class _ActiveEmergencyBanner extends StatelessWidget {
  const _ActiveEmergencyBanner({
    required this.incident,
    required this.l10n,
    required this.isDark,
    required this.onRespond,
  });

  final Map<String, dynamic> incident;
  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback onRespond;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEE2E2), Color(0xFFFEF2F2)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sos_rounded,
              color: Color(0xFFDC2626),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.activeEmergency}',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_typeLabel(incident['type'])} - ${incident['bus_code'] ?? ''}',
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onRespond,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.respond, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'sos':
        return 'طوارئ';
      case 'behavioral':
        return 'سلوكي';
      case 'health':
        return 'صحي';
      case 'technical':
        return 'تقني';
      case 'traffic':
        return 'مروري';
      default:
        return 'بلاغ';
    }
  }
}

// ─── Incident Card ────────────────────────────────────────────────
class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.l10n,
    required this.isDark,
  });

  final Map<String, dynamic> incident;
  final AppLocalizations l10n;
  final bool isDark;

  Color get _typeColor {
    switch (incident['type']) {
      case 'sos':
        return const Color(0xFFDC2626);
      case 'behavioral':
        return const Color(0xFF7C3AED);
      case 'health':
        return const Color(0xFF059669);
      case 'technical':
        return const Color(0xFFF59E0B);
      case 'traffic':
        return const Color(0xFFEA580C);
      default:
        return Colors.grey;
    }
  }

  IconData get _typeIcon {
    switch (incident['type']) {
      case 'sos':
        return Icons.sos_rounded;
      case 'behavioral':
        return Icons.psychology_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      case 'technical':
        return Icons.build_rounded;
      case 'traffic':
        return Icons.traffic_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  String get _typeLabel {
    switch (incident['type']) {
      case 'sos':
        return 'SOS';
      case 'behavioral':
        return 'سلوكي';
      case 'health':
        return 'صحي';
      case 'technical':
        return 'تقني';
      case 'traffic':
        return 'مروري';
      default:
        return 'بلاغ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = incident['status'] == 'pending';
    final time =
        DateTime.tryParse(incident['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? _typeColor.withValues(alpha: 0.3)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.border),
        ),
        boxShadow: isPending
            ? [
                BoxShadow(
                  color: _typeColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 24),
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
                        color: _typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _typeLabel,
                        style: TextStyle(
                          color: _typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatRelativeTime(time),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  incident['description'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (incident['photos'] != null &&
                    (incident['photos'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InteractiveViewer(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    incident['photos'][0],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                incident['photos'][0],
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 8,
                            right: 12,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'عرض المرفق',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (incident['bus_code'] != null)
                  Row(
                    children: [
                      Icon(
                        Icons.directions_bus,
                        size: 13,
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        incident['bus_code'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                // Display students if it's a behavioral incident or has students attached
                if (incident['student_names'] != null &&
                    (incident['student_names'] as List).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('الطلاب المعنيين بالبلاغ'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: (incident['student_names'] as List)
                                  .map(
                                    (name) => ListTile(
                                      leading: const Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                      ),
                                      title: Text(name.toString()),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إغلاق'),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _typeColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 16,
                            color: _typeColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'عرض الطلاب المعنيين (${(incident['student_names'] as List).length})',
                            style: TextStyle(
                              fontSize: 12,
                              color: _typeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_right_alt_rounded,
                            size: 16,
                            color: _typeColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                  : const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPending ? l10n.pending : l10n.resolved,
              style: TextStyle(
                color: isPending
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── New Incident Sheet (Matches Design) ─────────────────────────
class _NewIncidentSheet extends StatefulWidget {
  const _NewIncidentSheet({
    required this.l10n,
    required this.isDark,
    required this.onSubmitted,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback onSubmitted;

  @override
  State<_NewIncidentSheet> createState() => _NewIncidentSheetState();
}

class _NewIncidentSheetState extends State<_NewIncidentSheet> {
  String _selectedType = 'sos';
  final _descriptionController = TextEditingController();
  File? _attachedPhoto;
  bool _isSubmitting = false;
  bool _isLoadingData = true;

  int? _selectedBusId;
  List<int> _selectedStudentIds = [];
  List<Map<String, dynamic>> _buses = [];
  List<Map<String, dynamic>> _students = [];

  final _types = [
    {'key': 'sos', 'label': 'SOS'},
    {'key': 'behavioral', 'label': 'سلوكي'},
    {'key': 'health', 'label': 'صحي'},
    {'key': 'technical', 'label': 'تقني'},
    {'key': 'traffic', 'label': 'مروري'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final buses = await FieldSupervisorRemoteDataSource.getBuses();
    final students = await FieldSupervisorRemoteDataSource.getStudents();
    if (mounted) {
      setState(() {
        _buses = buses;
        _students = students;
        if (_buses.isNotEmpty) _selectedBusId = _buses.first['id'];
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (image != null && mounted) {
      setState(() => _attachedPhoto = File(image.path));
    }
  }

  String get _severity {
    switch (_selectedType) {
      case 'sos':
        return 'critical';
      case 'traffic':
        return 'high';
      case 'behavioral':
        return 'medium';
      default:
        return 'medium';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
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

            // Title
            Center(
              child: Text(
                widget.l10n.newIncident,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Type label
            Text(
              widget.l10n.incidentType,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Type chips - 2 rows like the design
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _types.map((type) {
                  final isSelected = _selectedType == type['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type['key']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (widget.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (widget.isDark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            type['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (widget.isDark
                                        ? Colors.white
                                        : AppColors.textPrimary),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoadingData)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                'اختر الحافلة (المركبة)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? Colors.white70
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.border,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedBusId,
                    isExpanded: true,
                    dropdownColor: widget.isDark
                        ? AppColors.darkSurface
                        : Colors.white,
                    hint: const Text('-- اختر الحافلة --'),
                    items: _buses
                        .map(
                          (bus) => DropdownMenuItem<int>(
                            value: bus['id'],
                            child: Text(
                              bus['bus_code'] ?? 'حافلة ${bus['id']}',
                              style: TextStyle(
                                color: widget.isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedBusId = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Students Selector (only for Behavioral)
              if (_selectedType == 'behavioral') ...[
                Text(
                  'الطلاب المعنيين بالمخالفة السلوكية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? Colors.white70
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showStudentsSelector,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedStudentIds.isEmpty
                                ? 'اختر الطلاب المعنيين بالبلاغ...'
                                : 'تم اختيار ${_selectedStudentIds.length} طالب(ة)',
                            style: TextStyle(
                              color: _selectedStudentIds.isEmpty
                                  ? (widget.isDark
                                        ? Colors.white38
                                        : Colors.grey)
                                  : (widget.isDark
                                        ? Colors.white
                                        : AppColors.textPrimary),
                              fontWeight: _selectedStudentIds.isEmpty
                                  ? null
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: widget.l10n.incidentDescription,
                hintStyle: TextStyle(
                  color: widget.isDark ? Colors.white38 : Colors.grey,
                ),
                filled: true,
                fillColor: widget.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.border,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Photo attachment
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: Icon(
                _attachedPhoto != null
                    ? Icons.check_circle
                    : Icons.camera_alt_rounded,
                color: _attachedPhoto != null
                    ? Colors.green
                    : AppColors.primary,
              ),
              label: Text(
                _attachedPhoto != null
                    ? widget.l10n.photoAttached
                    : widget.l10n.attachPhoto,
                style: TextStyle(
                  color: _attachedPhoto != null
                      ? Colors.green
                      : AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: _attachedPhoto != null
                      ? Colors.green.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button - Red urgent style
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                disabledBackgroundColor: const Color(
                  0xFFDC2626,
                ).withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.l10n.sendUrgentReport,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.l10n.pleaseDescribeIncident)),
      );
      return;
    }

    if (_selectedBusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الحافلة أولاً')),
      );
      return;
    }

    if (_selectedType == 'behavioral' && _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الطلاب المعنيين بالمخالفة السلوكية'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await FieldSupervisorRemoteDataSource.reportIncident(
      busId: _selectedBusId,
      type: _selectedType,
      severity: _severity,
      description: _descriptionController.text.trim(),
      studentIds: _selectedType == 'behavioral' ? _selectedStudentIds : null,
      photos: _attachedPhoto != null ? [_attachedPhoto!] : null,
    );

    if (mounted) {
      Navigator.pop(context);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.incidentReportedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSubmitted();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في إرسال البلاغ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStudentsSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: widget.isDark
                  ? AppColors.darkSurface
                  : Colors.white,
              title: Text(
                'اختر الطلاب',
                style: TextStyle(
                  color: widget.isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _students.isEmpty
                    ? const Text('لا يوجد طلاب مسجلين')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final id = student['id'] as int;
                          final isSelected = _selectedStudentIds.contains(id);
                          return CheckboxListTile(
                            title: Text(
                              student['name'] ?? '',
                              style: TextStyle(
                                color: widget.isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              student['uuid'] ?? '',
                              style: TextStyle(
                                color: widget.isDark
                                    ? Colors.white54
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            value: isSelected,
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  _selectedStudentIds.add(id);
                                } else {
                                  _selectedStudentIds.remove(id);
                                }
                              });
                              setState(() {}); // Update parent UI
                            },
                            activeColor: AppColors.primary,
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(widget.l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('تأكيد'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
