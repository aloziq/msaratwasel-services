import 'package:flutter/material.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_drawer.dart'; // Added Import
import 'package:msaratwasel_services/core/presentation/widgets/directional_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import '../../../../../core/presentation/widgets/adaptive_sliver_app_bar.dart';

import 'about_app_page.dart';
import 'change_password_page.dart';
import 'contact_us_page.dart';
import 'privacy_policy_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Added Key
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeController = ThemeProvider.of(context);
    final settingsController = SettingsProvider.of(context);
    final l10n = AppLocalizations.of(context)!;
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final authState = context.watch<AuthCubit>().state;

    return Scaffold(
      key: _scaffoldKey, // Assigned Key
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(), // Added Drawer
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          AdaptiveSliverAppBar(
            title: l10n.settings,
            leading: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () =>
                    _scaffoldKey.currentState?.openDrawer(), // Updated Logic
              ),
            ),
            backgroundColor: theme.scaffoldBackgroundColor.withValues(
              alpha: 0.9,
            ),
            stretch: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Section
                  _SectionHeader(title: l10n.accountTitle),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: PhosphorIcons.userCircle(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: l10n.profile,
                        subtitle: l10n.editProfile,
                        onTap: () => context.push(AppRoutes.profile),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.lockKey(PhosphorIconsStyle.duotone),
                        title: l10n.changePassword,
                        subtitle: '********',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        ),
                      ),
                      if (authState is AuthAuthenticated &&
                          authState.user.role != UserRole.teacher) ...[
                        _Divider(),
                        _SettingsTile(
                          icon: PhosphorIcons.users(PhosphorIconsStyle.duotone),
                          title: l10n.myStudents,
                          subtitle: l10n.manageKids,
                          onTap: () {
                            if (authState.user.role == UserRole.driver ||
                                authState.user.role == UserRole.assistant) {
                              context.push(AppRoutes.driverStudents);
                            } else {
                              context.push(AppRoutes.myClasses);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // App Settings Section
                  _SectionHeader(title: l10n.application),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: isDark
                            ? PhosphorIcons.moonStars(
                                PhosphorIconsStyle.duotone,
                              )
                            : PhosphorIcons.sun(PhosphorIconsStyle.duotone),
                        title: l10n.appearance,
                        subtitle: themeController.mode == ThemeMode.system
                            ? l10n.systemDefault
                            : isDark
                            ? l10n.darkModeOn
                            : l10n.darkModeOff,
                        trailing: _ThreeWayToggle(
                          selectedIndex:
                              themeController.mode == ThemeMode.system
                              ? 0
                              : themeController.mode == ThemeMode.light
                              ? 1
                              : 2,
                          labels: [l10n.systemDefault, l10n.light, l10n.dark],
                          icons: [
                            PhosphorIcons.deviceMobile(PhosphorIconsStyle.bold),
                            PhosphorIcons.sun(PhosphorIconsStyle.bold),
                            PhosphorIcons.moonStars(PhosphorIconsStyle.bold),
                          ],
                          onChanged: (index) {
                            final mode = [
                              ThemeMode.system,
                              ThemeMode.light,
                              ThemeMode.dark,
                            ][index];
                            themeController.setMode(mode);
                          },
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.translate(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: l10n.languageTitle,
                        subtitle: settingsController.isSystemLocale
                            ? l10n.systemDefault
                            : isArabic
                            ? 'العربية'
                            : 'English',
                        trailing: PopupMenuButton<int>(
                          initialValue: settingsController.isSystemLocale
                              ? 0
                              : isArabic
                              ? 1
                              : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: isDark ? AppColors.cardDark : Colors.white,
                          onSelected: (index) {
                            final locale = [
                              null,
                              const Locale('ar'),
                              const Locale('en'),
                            ][index];
                            settingsController.setLocale(locale);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 0,
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIcons.deviceMobile(
                                      PhosphorIconsStyle.bold,
                                    ),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(l10n.systemDefault),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 1,
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIcons.translate(
                                      PhosphorIconsStyle.bold,
                                    ),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('العربية'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 2,
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIcons.textAa(
                                      PhosphorIconsStyle.bold,
                                    ),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('English'),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : AppColors.cardLightGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  settingsController.isSystemLocale
                                      ? l10n.systemDefault
                                      : isArabic
                                      ? 'العربية'
                                      : 'English',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white70
                                      : theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _Divider(),
                      _FontSizeTile(settingsController: settingsController),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.bellSimple(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: l10n.notifications,
                        subtitle: l10n.activitiesSubtitle,
                        trailing: Switch.adaptive(
                          value: notificationsEnabled,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => notificationsEnabled = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Support Section
                  _SectionHeader(title: l10n.support),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: PhosphorIcons.question(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: l10n.helpCenter,
                        onTap: () {
                          context.push(AppRoutes.helpCenter);
                        },
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.phoneCall(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: l10n.contactUs,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ContactUsPage(),
                          ),
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.info(PhosphorIconsStyle.duotone),
                        title: l10n.aboutApp,
                        subtitle: 'v2.0.0',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutAppPage(),
                          ),
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.shieldCheck(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: l10n.privacyPolicy,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.read<AuthCubit>().logout(),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: theme.colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const DirectionalIcon(Icons.logout_rounded),
                      label: Text(
                        l10n.logout,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.brightness == Brightness.dark
              ? Colors.white70
              : theme.colorScheme.primary,
          height: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                DirectionalIcon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 0,
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}

class _ThreeWayToggle extends StatelessWidget {
  const _ThreeWayToggle({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.onChanged,
  });

  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : AppColors.cardLightGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final isSelected = selectedIndex == index;
          return _buildSegment(
            context: context,
            isSelected: isSelected,
            label: labels[index],
            icon: icons[index],
            onTap: () => onChanged(index),
          );
        }),
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cardBorderDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? (isDark ? Colors.white : theme.colorScheme.primary)
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? (isDark ? Colors.white : theme.colorScheme.onSurface)
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontSizeTile extends StatelessWidget {
  const _FontSizeTile({required this.settingsController});

  final SettingsController settingsController;

  // Map scale values to indices: 0=small, 1=medium, 2=large
  int _scaleToIndex(double scale) {
    if (scale <= 0.9) return 0;
    if (scale <= 1.1) return 1;
    return 2;
  }

  double _indexToScale(int index) {
    switch (index) {
      case 0:
        return 0.85;
      case 2:
        return 1.15;
      default:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final selectedIndex = _scaleToIndex(settingsController.fontScale);

    final labels = [
      l10n.fontSizeSmall,
      l10n.fontSizeMedium,
      l10n.fontSizeLarge,
    ];
    final fontSizes = [11.0, 13.0, 15.0];

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                PhosphorIcons.textAa(PhosphorIconsStyle.duotone),
                color: isDark ? Colors.white : theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n.fontSize,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : AppColors.cardLightGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () =>
                        settingsController.setFontScale(_indexToScale(index)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.fastOutSlowIn,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.cardBorderDark : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected && !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: fontSizes[index],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? (isDark
                                    ? Colors.white
                                    : theme.colorScheme.primary)
                              : theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
