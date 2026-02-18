import 'package:flutter/material.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  _StudentDelaysList(l10n: l10n, isDark: isDark),
                  _BusDelaysList(l10n: l10n, isDark: isDark),
                ],
              ),
            ),
          ],
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
      builder: (context) => _NewDelaySheet(l10n: l10n, isDark: isDark),
    );
  }
}

class _StudentDelaysList extends StatelessWidget {
  const _StudentDelaysList({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final delays = [
      _DelayData('أحمد محمد', '10 ${l10n.minutes}', 'B001', DateTime.now()),
      _DelayData(
        'سارة علي',
        '15 ${l10n.minutes}',
        'B002',
        DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: delays.length,
      itemBuilder: (context, index) {
        final delay = delays[index];
        return _DelayCard(
          name: delay.name,
          duration: delay.duration,
          busId: delay.busId,
          time: delay.time,
          isStudent: true,
          l10n: l10n,
          isDark: isDark,
        );
      },
    );
  }
}

class _BusDelaysList extends StatelessWidget {
  const _BusDelaysList({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final delays = [
      _DelayData(
        'حافلة 1',
        '20 ${l10n.minutes}',
        l10n.technicalIssue,
        DateTime.now(),
      ),
      _DelayData(
        'حافلة 3',
        '30 ${l10n.minutes}',
        l10n.trafficJam,
        DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: delays.length,
      itemBuilder: (context, index) {
        final delay = delays[index];
        return _DelayCard(
          name: delay.name,
          duration: delay.duration,
          busId: delay.busId,
          time: delay.time,
          isStudent: false,
          l10n: l10n,
          isDark: isDark,
        );
      },
    );
  }
}

class _DelayData {
  final String name;
  final String duration;
  final String busId;
  final DateTime time;

  _DelayData(this.name, this.duration, this.busId, this.time);
}

class _DelayCard extends StatelessWidget {
  const _DelayCard({
    required this.name,
    required this.duration,
    required this.busId,
    required this.time,
    required this.isStudent,
    required this.l10n,
    required this.isDark,
  });

  final String name;
  final String duration;
  final String busId;
  final DateTime time;
  final bool isStudent;
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEC4899),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      isStudent ? Icons.directions_bus : Icons.info,
                      size: 12,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      busId,
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
          IconButton(
            icon: Icon(Icons.send_rounded, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.reportSent)));
            },
          ),
        ],
      ),
    );
  }
}

class _NewDelaySheet extends StatefulWidget {
  const _NewDelaySheet({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  State<_NewDelaySheet> createState() => _NewDelaySheetState();
}

class _NewDelaySheetState extends State<_NewDelaySheet> {
  String _delayType = 'student';
  String? _selectedItem;
  String? _selectedReason;
  final _durationController = TextEditingController();

  // Mock data — students with civil IDs, buses with numbers
  static const _students = [
    _SearchableItem(name: 'أحمد محمد', subtitle: '12345678'),
    _SearchableItem(name: 'سارة علي', subtitle: '23456789'),
    _SearchableItem(name: 'خالد أحمد', subtitle: '34567890'),
    _SearchableItem(name: 'فاطمة سالم', subtitle: '45678901'),
    _SearchableItem(name: 'عبدالله يوسف', subtitle: '56789012'),
    _SearchableItem(name: 'مريم ناصر', subtitle: '67890123'),
  ];

  static const _buses = [
    _SearchableItem(name: 'حافلة 1', subtitle: 'B001'),
    _SearchableItem(name: 'حافلة 2', subtitle: 'B002'),
    _SearchableItem(name: 'حافلة 3', subtitle: 'B003'),
    _SearchableItem(name: 'حافلة 4', subtitle: 'B004'),
    _SearchableItem(name: 'حافلة 5', subtitle: 'B005'),
  ];

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  void _openSearchSheet() async {
    final isStudent = _delayType == 'student';
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchableSelectionSheet(
        title: isStudent ? widget.l10n.selectStudent : widget.l10n.selectBus,
        hint: widget.l10n.searchPlaceholder,
        items: isStudent ? _students : _buses,
        subtitleLabel: isStudent ? widget.l10n.civilId : widget.l10n.bus,
        isDark: widget.isDark,
      ),
    );
    if (result != null) {
      setState(() => _selectedItem = result);
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
                _selectedItem = null;
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
                _selectedItem ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedItem != null
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
            initialValue: _selectedReason,
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
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.l10n.delaySavedAndReported),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save, size: 18),
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
}

/// Data model for searchable items (student or bus).
class _SearchableItem {
  final String name;
  final String subtitle; // Civil ID for students, bus number for buses

  const _SearchableItem({required this.name, required this.subtitle});

  bool matches(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) || subtitle.toLowerCase().contains(q);
  }
}

/// A bottom sheet with a search bar to pick a student or bus.
class _SearchableSelectionSheet extends StatefulWidget {
  const _SearchableSelectionSheet({
    required this.title,
    required this.hint,
    required this.items,
    required this.subtitleLabel,
    required this.isDark,
  });

  final String title;
  final String hint;
  final List<_SearchableItem> items;
  final String subtitleLabel;
  final bool isDark;

  @override
  State<_SearchableSelectionSheet> createState() =>
      _SearchableSelectionSheetState();
}

class _SearchableSelectionSheetState extends State<_SearchableSelectionSheet> {
  final _searchController = TextEditingController();
  late List<_SearchableItem> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.matches(query))
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
              widget.title,
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
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (_, value, _) {
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
            child: _filteredItems.isEmpty
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
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            widget.subtitleLabel.contains('ID')
                                ? Icons.person_rounded
                                : Icons.directions_bus_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${widget.subtitleLabel}: ${item.subtitle}',
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
                        onTap: () => Navigator.pop(context, item.name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
