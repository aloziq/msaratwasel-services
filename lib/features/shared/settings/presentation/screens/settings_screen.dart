import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/brand_colors.dart';
import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';

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
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeController = ThemeProvider.of(context);
    final settingsController = SettingsProvider.of(context);
    final l10n = AppLocalizations.of(context)!;
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            leading: BackButton(
              style: ButtonStyle(
                iconSize: WidgetStateProperty.all(24),
                shadowColor: WidgetStateProperty.all(Colors.black),
              ),
            ),
            largeTitle: Text(
              l10n.settings,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 24,
              ),
            ),
            backgroundColor: theme.scaffoldBackgroundColor.withValues(
              alpha: 0.9,
            ),
            border: null,
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
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.users(PhosphorIconsStyle.duotone),
                        title: l10n.myStudents,
                        subtitle: l10n.manageKids,
                        onTap: () {
                          // Navigation to manage students/classes if available or keep generic
                          // Original used AppRoutes.myClasses
                          context.push(AppRoutes.myClasses);
                        },
                      ),
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
                        subtitle: isDark ? l10n.darkModeOn : l10n.darkModeOff,
                        trailing: _SegmentedToggle(
                          value: isDark,
                          onChanged: (v) {
                            themeController.setMode(
                              v ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                          leftLabel: l10n.light,
                          rightLabel: l10n.dark,
                          leftIcon: PhosphorIcons.sun(PhosphorIconsStyle.bold),
                          rightIcon: PhosphorIcons.moonStars(
                            PhosphorIconsStyle.bold,
                          ),
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.translate(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: l10n.languageTitle,
                        subtitle: isArabic ? 'العربية' : 'English',
                        trailing: _SegmentedToggle(
                          value:
                              !isArabic, // False (Left) = Arabic, True (Right) = English
                          onChanged: (targetIsEnglish) {
                            if (targetIsEnglish != !isArabic) {
                              settingsController.setLocale(
                                targetIsEnglish
                                    ? const Locale('en')
                                    : const Locale('ar'),
                              );
                            }
                          },
                          leftLabel: 'العربية',
                          rightLabel: 'English',
                          leftIcon: PhosphorIcons.translate(
                            PhosphorIconsStyle.bold,
                          ),
                          rightIcon: PhosphorIcons.textAa(
                            PhosphorIconsStyle.bold,
                          ),
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIcons.bellSimple(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: l10n.notifications,
                        subtitle: l10n.activitiesSubtitle,
                        trailing: Switch.adaptive(
                          value: notificationsEnabled,
                          activeTrackColor: BrandColors.primary,
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
                          // Placeholder
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
                        backgroundColor: BrandColors.error.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: BrandColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        l10n.logout,
                        style: GoogleFonts.cairo(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : BrandColors.primary,
          letterSpacing: 0.5,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : BrandColors.border,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : BrandColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : BrandColors.primary,
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
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : BrandColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white60
                              : BrandColors.textSecondary,
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
                Icon(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : BrandColors.border.withValues(alpha: 0.5),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.value,
    required this.onChanged,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftIcon,
    required this.rightIcon,
  });

  final bool value; // false = left, true = right
  final ValueChanged<bool> onChanged;
  final String leftLabel;
  final String rightLabel;
  final IconData leftIcon;
  final IconData rightIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : const Color(0xFFF1F5F9), // Lighter, cleaner grey
        borderRadius: BorderRadius.circular(16), // Softer corners
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegment(
            context: context,
            isSelected: !value,
            label: leftLabel,
            icon: leftIcon,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 4),
          _buildSegment(
            context: context,
            isSelected: value,
            label: rightLabel,
            icon: rightIcon,
            onTap: () => onChanged(true),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn, // More responsive feel
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ), // More horizontal padding
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
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
        child: Row(
          children: [
            Icon(
              icon,
              size: 18, // Slightly larger
              color: isSelected
                  ? (isDark ? Colors.white : BrandColors.primary)
                  : (isDark ? Colors.white38 : Colors.grey),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : BrandColors.textPrimary)
                    : (isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
