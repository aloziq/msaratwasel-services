import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_sliver_header.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          AppSliverHeader(title: l10n.helpCenter),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Bar Placeholder
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isArabic ? 'ابحث عن مساعدة...' : 'Search for help...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    isArabic ? 'الأسئلة الشائعة' : 'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: AppSpacing.md),

                  // FAQ Items
                  _FAQItem(
                    question: isArabic
                        ? 'كيف يمكنني تغيير كلمة المرور؟'
                        : 'How do I change my password?',
                    answer: isArabic
                        ? 'يمكنك تغيير كلمة المرور من خلال الذهاب إلى الإعدادات > تغيير كلمة المرور.'
                        : 'You can change your password by going to Settings > Change Password.',
                    delay: 200,
                    isDark: isDark,
                  ),
                  _FAQItem(
                    question: isArabic
                        ? 'كيف أبلغ عن مشكلة في الحافلة؟'
                        : 'How do I report a bus issue?',
                    answer: isArabic
                        ? 'يمكنك الإبلاغ عن مشكلة من خلال خيار "طلب صيانة" في الصفحة الرئيسية للسائق.'
                        : 'You can report an issue through the "Maintenance Request" option on the driver home page.',
                    delay: 300,
                    isDark: isDark,
                  ),
                  _FAQItem(
                    question: isArabic
                        ? 'كيف أتواصل مع الدعم الفني؟'
                        : 'How do I contact support?',
                    answer: isArabic
                        ? 'يمكنك التواصل معنا عبر الهاتف أو البريد الإلكتروني الموضحين أدناه.'
                        : 'You can contact us via phone or email listed below.',
                    delay: 400,
                    isDark: isDark,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    isArabic ? 'تواصل معنا' : 'Contact Us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: AppSpacing.md),

                  // Contact Options
                  Row(
                    children: [
                      Expanded(
                        child: _ContactCard(
                          icon: FontAwesomeIcons.whatsapp,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () async {
                            final uri = Uri.parse('https://wa.me/966500000000');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          isDark: isDark,
                          delay: 600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _ContactCard(
                          icon: FontAwesomeIcons.envelope,
                          label: 'Email',
                          color: Colors.blue,
                          onTap: () async {
                            final uri = Uri.parse('mailto:support@wasel.com');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          isDark: isDark,
                          delay: 700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  const _FAQItem({
    required this.question,
    required this.answer,
    required this.delay,
    required this.isDark,
  });

  final String question;
  final String answer;
  final int delay;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
    required this.delay,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).scale();
  }
}
