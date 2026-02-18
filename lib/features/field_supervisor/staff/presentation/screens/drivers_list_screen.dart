import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/presentation/widgets/supervisor_drawer.dart';
import 'package:msaratwasel_services/features/field_supervisor/home/utils/supervisor_navigation.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

/// Screen showing list of all drivers and supervisors.
class DriversListScreen extends StatefulWidget {
  const DriversListScreen({super.key});

  @override
  State<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends State<DriversListScreen>
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

    final drivers = [
      _StaffData('أحمد محمد', 'سائق', true, 'B001'),
      _StaffData('خالد علي', 'سائق', true, 'B002'),
      _StaffData('سعيد أحمد', 'سائق', false, 'B003'),
      _StaffData('محمود خالد', 'سائق', true, 'B004'),
    ];

    final supervisors = [
      _StaffData('فاطمة أحمد', 'مشرفة', true, 'B001'),
      _StaffData('نور الهدى', 'مشرفة', true, 'B002'),
      _StaffData('سارة محمد', 'مشرفة', false, 'B003'),
    ];

    return Scaffold(
      key: GlobalKey<ScaffoldState>(),
      drawer: SupervisorDrawer(
        currentIndex: 2,
        onSelect: (index) => handleSupervisorNavigation(context, index, 2),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            AppSliverHeader(title: l10n.driversAndSupervisors, showMenu: true),

            // Tab Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: isDark ? AppColors.primary : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark
                        ? Colors.white60
                        : Colors.grey[600],
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(text: l10n.drivers),
                      Tab(text: l10n.supervisors),
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
                  _StaffList(staff: drivers, l10n: l10n, isDark: isDark),
                  _StaffList(staff: supervisors, l10n: l10n, isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffData {
  final String name;
  final String role;
  final bool isActive;
  final String busId;

  _StaffData(this.name, this.role, this.isActive, this.busId);
}

class _StaffList extends StatelessWidget {
  const _StaffList({
    required this.staff,
    required this.l10n,
    required this.isDark,
  });

  final List<_StaffData> staff;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: staff.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final person = staff[index];
        return _StaffCard(person: person, l10n: l10n, isDark: isDark);
      },
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.person,
    required this.l10n,
    required this.isDark,
  });

  final _StaffData person;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.steeringWheel(PhosphorIconsStyle.duotone),
              color: isDark ? Colors.white70 : AppColors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: person.isActive
                            ? const Color(0xFF22C55E)
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      person.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.bus(PhosphorIconsStyle.duotone),
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.bus} ${person.busId}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: PhosphorIcons.chatCircleDots(PhosphorIconsStyle.fill),
                color: const Color(0xFF0F172A),
                isDark: isDark,
                onTap: () async {
                  final Uri url = Uri.parse('sms:99999999');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: PhosphorIcons.phoneCall(PhosphorIconsStyle.fill),
                color: const Color(0xFF22C55E),
                isDark: isDark,
                onTap: () async {
                  final Uri url = Uri.parse('tel:99999999');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? color.withValues(alpha: 0.8) : color,
          ),
        ),
      ),
    );
  }
}
