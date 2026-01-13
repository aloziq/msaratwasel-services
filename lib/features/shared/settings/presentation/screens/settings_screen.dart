import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/brand_colors.dart';
import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

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
      backgroundColor: Colors.transparent,
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
            backgroundColor: Colors.transparent,
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
                  _SectionHeader(title: isArabic ? 'الحساب' : 'Account'),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: PhosphorIconsDuotone.userCircle,
                        title: isArabic ? 'الملف الشخصي' : 'Profile',
                        subtitle: isArabic
                            ? 'تعديل البيانات الشخصية'
                            : 'Edit personal info',
                        onTap: () => context.push(AppRoutes.profile),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIconsDuotone.users,
                        title: isArabic ? 'فصولي' : 'My Classes',
                        subtitle: isArabic
                            ? 'إدارة الفصول والطلاب'
                            : 'Manage classes and students',
                        onTap: () => context.push(AppRoutes.myClasses),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // App Settings Section
                  _SectionHeader(title: isArabic ? 'التطبيق' : 'Application'),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: isDark
                            ? PhosphorIconsDuotone.moonStars
                            : PhosphorIconsDuotone.sun,
                        title: isArabic ? 'المظهر' : 'Appearance',
                        subtitle: isDark
                            ? (isArabic ? 'داكن' : 'Dark')
                            : (isArabic ? 'فاتح' : 'Light'),
                        trailing: CupertinoSwitch(
                          value: isDark,
                          activeTrackColor: isDark
                              ? Colors.white
                              : BrandColors.primary,
                          thumbColor: isDark
                              ? BrandColors.primary
                              : Colors.white,
                          onChanged: (v) => themeController.setMode(
                            v ? ThemeMode.dark : ThemeMode.light,
                          ),
                        ),
                        onTap: () => themeController.setMode(
                          isDark ? ThemeMode.light : ThemeMode.dark,
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIconsDuotone.translate,
                        title: isArabic ? 'اللغة' : 'Language',
                        subtitle: isArabic ? 'العربية' : 'English',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: theme.scaffoldBackgroundColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Text(
                                      '🇺🇸',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                    title: Text(
                                      'English',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    trailing: !isArabic
                                        ? Icon(
                                            Icons.check,
                                            color: theme.colorScheme.primary,
                                          )
                                        : null,
                                    onTap: () {
                                      settingsController.setLocale(
                                        const Locale('en'),
                                      );
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Text(
                                      '🇸🇦',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                    title: Text(
                                      'العربية',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    trailing: isArabic
                                        ? Icon(
                                            Icons.check,
                                            color: theme.colorScheme.primary,
                                          )
                                        : null,
                                    onTap: () {
                                      settingsController.setLocale(
                                        const Locale('ar'),
                                      );
                                      Navigator.pop(context);
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIconsDuotone.bellSimple,
                        title: isArabic ? 'الإشعارات' : 'Notifications',
                        subtitle: isArabic
                            ? 'تنبيهات الرحلات والحضور'
                            : 'Trip and attendance alerts',
                        trailing: CupertinoSwitch(
                          value: notificationsEnabled,
                          activeTrackColor: isDark
                              ? Colors.white
                              : BrandColors.primary,
                          thumbColor: isDark
                              ? BrandColors.primary
                              : Colors.white,
                          onChanged: (v) =>
                              setState(() => notificationsEnabled = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Support Section
                  const SizedBox(height: AppSpacing.md),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: PhosphorIconsDuotone.question,
                        title: isArabic ? 'مركز المساعدة' : 'Help Center',
                        onTap: () {},
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIconsDuotone.phoneCall,
                        title: isArabic ? 'تواصل معنا' : 'Contact Us',
                        onTap: () {},
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: PhosphorIconsDuotone.info,
                        title: isArabic ? 'عن التطبيق' : 'About App',
                        subtitle: 'v1.0.0',
                        onTap: () {},
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
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        isArabic ? 'تسجيل الخروج' : 'Logout',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
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
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? theme.colorScheme.primary : theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
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
                        style: theme.textTheme.bodyMedium?.copyWith(
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
