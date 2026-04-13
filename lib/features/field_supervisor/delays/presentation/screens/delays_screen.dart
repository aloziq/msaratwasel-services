import 'package:flutter/material.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/data/field_supervisor_remote_datasource.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/time_formatter.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

/// Screen for registering student and bus delays.
class DelaysScreen extends StatefulWidget {
  const DelaysScreen({super.key});

  @override
  State<DelaysScreen> createState() => _DelaysScreenState();
}

class _DelaysScreenState extends State<DelaysScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _studentDelays = [];
  List<Map<String, dynamic>> _busDelays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      FieldSupervisorRemoteDataSource.getDelays(type: 'student'),
      FieldSupervisorRemoteDataSource.getDelays(type: 'bus'),
    ]);

    if (mounted) {
      setState(() {
        _studentDelays = results[0];
        _busDelays = results[1];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: SupervisorDrawer(
        currentIndex: 6,
        onSelect: (index) => handleSupervisorNavigation(context, index, 6),
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
                      title: l10n.registerDelays,
                      showMenu: true,
                      trailing: IconButton(
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        onPressed: () => _showNewDelaySheet(context, l10n, isDark),
                      ),
                    ),

                    // Tab Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            tabs: [
                              Tab(text: l10n.studentDelays),
                              Tab(text: l10n.busDelays),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tab Views
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _DelaysList(
                            delays: _studentDelays,
                            isStudent: true,
                            l10n: l10n,
                            isDark: isDark,
                          ),
                          _DelaysList(
                            delays: _busDelays,
                            isStudent: false,
                            l10n: l10n,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showNewDelaySheet(
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
      builder: (context) => _NewDelaySheet(
        l10n: l10n,
        isDark: isDark,
        onSubmitted: _loadData,
      ),
    );
  }
}

// ─── Delays List ──────────────────────────────────────────────
class _DelaysList extends StatelessWidget {
  const _DelaysList({
    required this.delays,
    required this.isStudent,
    required this.l10n,
    required this.isDark,
  });

  final List<Map<String, dynamic>> delays;
  final bool isStudent;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (delays.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isStudent ? Icons.person_off : Icons.no_transfer,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد تأخيرات مسجلة',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: delays.length,
      itemBuilder: (context, index) {
        final delay = delays[index];
        return _DelayCard(
          name: isStudent
              ? (delay['student_name'] ?? 'N/A')
              : (delay['bus_code'] ?? 'حافلة'),
          duration: '${delay['duration_minutes']} ${l10n.minutes}',
          subtitle: isStudent
              ? (delay['bus_code'] ?? '')
              : (delay['reason'] ?? ''),
          time: DateTime.tryParse(delay['created_at'] ?? '') ?? DateTime.now(),
          isStudent: isStudent,
          reason: delay['reason'] ?? '',
          l10n: l10n,
          isDark: isDark,
        );
      },
    );
  }
}

// ─── Delay Card ──────────────────────────────────────────────
class _DelayCard extends StatelessWidget {
  const _DelayCard({
    required this.name,
    required this.duration,
    required this.subtitle,
    required this.time,
    required this.isStudent,
    required this.reason,
    required this.l10n,
    required this.isDark,
  });

  final String name;
  final String duration;
  final String subtitle;
  final DateTime time;
  final bool isStudent;
  final String reason;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
              color: const Color(0xFFEC4899).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isStudent ? Icons.person : Icons.directions_bus,
              color: const Color(0xFFEC4899),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
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
                      Icons.timer,
                      size: 12,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(
                        isStudent ? Icons.directions_bus : Icons.info,
                        size: 12,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formatRelativeTime(time),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (reason.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                reason,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── New Delay Sheet ──────────────────────────────────────────────
class _NewDelaySheet extends StatefulWidget {
  const _NewDelaySheet({
    required this.l10n,
    required this.isDark,
    required this.onSubmitted,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback onSubmitted;

  @override
  State<_NewDelaySheet> createState() => _NewDelaySheetState();
}

class _NewDelaySheetState extends State<_NewDelaySheet> {
  String _delayType = 'student';
  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic>? _selectedBus;
  String? _selectedReason;
  final _durationController = TextEditingController();
  bool _isSubmitting = false;

  // These will be loaded from API
  List<Map<String, dynamic>> _buses = [];

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    final buses = await FieldSupervisorRemoteDataSource.getBuses();
    if (mounted) setState(() => _buses = buses);
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  void _openSearchSheet() async {
    final isStudent = _delayType == 'student';

    if (isStudent) {
      // Open student search
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _StudentSearchSheet(
          isDark: widget.isDark,
          l10n: widget.l10n,
        ),
      );
      if (result != null && mounted) {
        setState(() => _selectedStudent = result);
      }
    } else {
      // Open bus search
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _BusSearchSheet(
          isDark: widget.isDark,
          l10n: widget.l10n,
          buses: _buses,
        ),
      );
      if (result != null && mounted) {
        setState(() => _selectedBus = result);
      }
    }
  }

  String get _selectionLabel {
    if (_delayType == 'student') {
      return _selectedStudent?['name'] ?? '';
    } else {
      return _selectedBus != null
          ? (_selectedBus!['bus_code'] ?? 'حافلة ${_selectedBus!['id']}')
          : '';
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
            widget.l10n.registerNewDelay,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'student', label: Text(widget.l10n.student)),
              ButtonSegment(value: 'bus', label: Text(widget.l10n.bus)),
            ],
            selected: {_delayType},
            onSelectionChanged: (value) {
              setState(() {
                _delayType = value.first;
                _selectedStudent = null;
                _selectedBus = null;
              });
            },
          ),
          const SizedBox(height: 16),

          // Searchable selection field
          InkWell(
            onTap: _openSearchSheet,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: _delayType == 'student'
                    ? widget.l10n.selectStudent
                    : widget.l10n.selectBus,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.search_rounded),
              ),
              child: Text(
                _selectionLabel,
                style: TextStyle(
                  fontSize: 16,
                  color: _selectionLabel.isNotEmpty
                      ? (widget.isDark ? Colors.white : AppColors.textPrimary)
                      : Colors.grey,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _durationController,
            decoration: InputDecoration(
              labelText: widget.l10n.delayDuration,
              suffixText: widget.l10n.minutes,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedReason,
            decoration: InputDecoration(
              labelText: widget.l10n.delayReason,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items:
                [
                      widget.l10n.trafficJam,
                      widget.l10n.technicalIssue,
                      widget.l10n.studentLate,
                      widget.l10n.other,
                    ]
                    .map(
                      (reason) =>
                          DropdownMenuItem(value: reason, child: Text(reason)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _selectedReason = value),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(widget.l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(widget.l10n.saveAndSend),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مدة التأخير')),
      );
      return;
    }

    if (_delayType == 'student' && _selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الطالب')),
      );
      return;
    }

    if (_delayType == 'bus' && _selectedBus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الحافلة')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final int? busId = _delayType == 'bus' ? (_selectedBus?['id'] as int?) : null;

    final result = await FieldSupervisorRemoteDataSource.storeDelay(
      type: _delayType,
      studentId: _selectedStudent?['id'] as int?,
      busId: busId,
      durationMinutes: duration,
      reason: _selectedReason,
    );

    if (mounted) {
      Navigator.pop(context);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.delaySavedAndReported)),
        );
        widget.onSubmitted();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في حفظ التأخير')),
        );
      }
    }
  }
}

// ─── Student Search Sheet ──────────────────────────────────────────────
class _StudentSearchSheet extends StatefulWidget {
  const _StudentSearchSheet({
    required this.isDark,
    required this.l10n,
  });

  final bool isDark;
  final AppLocalizations l10n;

  @override
  State<_StudentSearchSheet> createState() => _StudentSearchSheetState();
}

class _StudentSearchSheetState extends State<_StudentSearchSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents([String? search]) async {
    setState(() => _isLoading = true);
    final data = await FieldSupervisorRemoteDataSource.getStudents(search: search);
    if (mounted) {
      setState(() {
        _students = data;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _loadStudents(query.isEmpty ? null : query);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.l10n.selectStudent,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.l10n.searchPlaceholder,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (_, value, __) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    );
                  },
                ),
                filled: true,
                fillColor: widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                color: widget.isDark
                                    ? Colors.white54
                                    : AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _students.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              student['name'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: widget.isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${widget.l10n.civilId}: ${student['national_id'] ?? student['code'] ?? ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: widget.isDark
                                    ? Colors.white54
                                    : AppColors.textSecondary,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () => Navigator.pop(context, student),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Bus Search Sheet ──────────────────────────────────────────────
class _BusSearchSheet extends StatefulWidget {
  const _BusSearchSheet({
    required this.isDark,
    required this.l10n,
    required this.buses,
  });

  final bool isDark;
  final AppLocalizations l10n;
  final List<Map<String, dynamic>> buses;

  @override
  State<_BusSearchSheet> createState() => _BusSearchSheetState();
}

class _BusSearchSheetState extends State<_BusSearchSheet> {
  final _searchController = TextEditingController();
  late List<Map<String, dynamic>> _filteredBuses;

  @override
  void initState() {
    super.initState();
    _filteredBuses = widget.buses;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBuses = widget.buses;
      } else {
        final q = query.toLowerCase();
        _filteredBuses = widget.buses
            .where((bus) {
              final code = (bus['bus_code'] ?? '').toString().toLowerCase();
              final plate = (bus['plate_number'] ?? '').toString().toLowerCase();
              return code.contains(q) || plate.contains(q);
            })
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.l10n.selectBus,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.l10n.searchPlaceholder,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (_, value, __) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    );
                  },
                ),
                filled: true,
                fillColor: widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _filteredBuses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            color: widget.isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _filteredBuses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bus = _filteredBuses[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            Icons.directions_bus_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          bus['bus_code'] ?? 'حافلة ${bus['id']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${widget.l10n.bus}: ${bus['bus_code'] ?? ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => Navigator.pop(context, bus),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
