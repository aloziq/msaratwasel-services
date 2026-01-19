import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/brand_colors.dart';
import 'package:msaratwasel_services/features/shared/presentation/widgets/app_sliver_header.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(title: l10n.privacyPolicy, hasLeading: true),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle(title: l10n.privacyIntroTitle, isDark: isDark),
                _BulletPoint(text: l10n.privacyIntroBody1, isDark: isDark),
                _BulletPoint(text: l10n.privacyIntroBody2, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: l10n.privacyDataCollectionTitle,
                  isDark: isDark,
                ),
                _SubTitle(title: l10n.privacyStudentDataTitle, isDark: isDark),
                _BulletPoint(text: l10n.privacyStudentData1, isDark: isDark),
                _BulletPoint(text: l10n.privacyStudentData2, isDark: isDark),
                _BulletPoint(text: l10n.privacyStudentData3, isDark: isDark),
                _BulletPoint(text: l10n.privacyStudentData4, isDark: isDark),
                _BulletPoint(text: l10n.privacyStudentData5, isDark: isDark),
                _BulletPoint(text: l10n.privacyStudentData6, isDark: isDark),
                _BulletPoint(text: l10n.privacyStudentData7, isDark: isDark),
                const SizedBox(height: AppSpacing.md),
                _SubTitle(title: l10n.privacyOtherDataTitle, isDark: isDark),
                _BulletPoint(text: l10n.privacyOtherData1, isDark: isDark),
                _BulletPoint(text: l10n.privacyOtherData2, isDark: isDark),
                _BulletPoint(text: l10n.privacyOtherData3, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: l10n.privacyDataUsageTitle,
                  isDark: isDark,
                ),
                _BulletPoint(text: l10n.privacyDataUsage1, isDark: isDark),
                _BulletPoint(text: l10n.privacyDataUsage2, isDark: isDark),
                _BulletPoint(text: l10n.privacyDataUsage3, isDark: isDark),
                _BulletPoint(text: l10n.privacyDataUsage4, isDark: isDark),
                _BulletPoint(text: l10n.privacyDataUsage5, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: l10n.privacyDataProtectionTitle,
                  isDark: isDark,
                ),
                _BulletPoint(text: l10n.privacyDataProtection1, isDark: isDark),
                _BulletPoint(text: l10n.privacyDataProtection2, isDark: isDark),
                _BulletPoint(text: l10n.privacyDataProtection3, isDark: isDark),
                _BulletPoint(text: l10n.privacyDataProtection4, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: l10n.privacyUserRightsTitle,
                  isDark: isDark,
                ),
                _BulletPoint(text: l10n.privacyUserRights1, isDark: isDark),
                _BulletPoint(text: l10n.privacyUserRights2, isDark: isDark),
                _BulletPoint(text: l10n.privacyUserRights3, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: l10n.privacyUserObligationsTitle,
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: l10n.privacyUserObligations1,
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: l10n.privacyUserObligations2,
                  isDark: isDark,
                ),
                _BulletPoint(
                  text: l10n.privacyUserObligations3,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: l10n.privacyLegalLiabilityTitle,
                  isDark: isDark,
                ),
                _BulletPoint(text: l10n.privacyLegalLiability1, isDark: isDark),
                _BulletPoint(text: l10n.privacyLegalLiability2, isDark: isDark),
                _BulletPoint(text: l10n.privacyLegalLiability3, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(
                  title: l10n.privacyAmendmentsTitle,
                  isDark: isDark,
                ),
                _BulletPoint(text: l10n.privacyAmendments1, isDark: isDark),
                _BulletPoint(text: l10n.privacyAmendments2, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),

                _SectionTitle(title: l10n.privacyConsentTitle, isDark: isDark),
                _BulletPoint(text: l10n.privacyConsentBody, isDark: isDark),
                const SizedBox(height: AppSpacing.xxl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                _SectionTitle(
                  title: l10n.privacySimplifiedTitle,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),
                _QuestionAnswer(
                  question: l10n.privacyQ1,
                  answer: l10n.privacyA1,
                  isDark: isDark,
                ),
                _QuestionAnswer(
                  question: l10n.privacyQ2,
                  answer: l10n.privacyA2,
                  isDark: isDark,
                ),
                _QuestionAnswer(
                  question: l10n.privacyQ3,
                  answer: l10n.privacyA3,
                  isDark: isDark,
                ),
                _QuestionAnswer(
                  question: l10n.privacyQ4,
                  answer: l10n.privacyA4,
                  isDark: isDark,
                ),
                _QuestionAnswer(
                  question: l10n.privacyQ5,
                  answer: l10n.privacyA5,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
        height: 1.6,
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, right: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Icon(
              Icons.circle,
              size: 6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionAnswer extends StatelessWidget {
  const _QuestionAnswer({
    required this.question,
    required this.answer,
    required this.isDark,
  });
  final String question;
  final String answer;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? BrandColors.secondary : BrandColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
