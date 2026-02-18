import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _complaintController = TextEditingController();

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      debugPrint('Could not launch $launchUri');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(launchUri)) {
      debugPrint('Could not launch $launchUri');
    }
  }

  void _submitComplaint() {
    if (_complaintController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.complaintSent),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    _complaintController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom Header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (Start/Right in RTL)
                    // Only show if we can pop
                    if (Navigator.of(context).canPop())
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons
                                  .arrow_back_rounded, // Auto-mirrored: Points Left in LTR, Right in RTL (correct for Back)
                              color: isDark ? Colors.white : AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(
                        width: 44,
                      ), // Placeholder if no back button to keep title centered?
                    // Spacer/Title
                    Expanded(
                      child: Text(
                        l10n.contactUs,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.primary,
                          fontSize:
                              24, // Slightly smaller for better fit? Or keep 28.
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Google Sans',
                        ),
                      ),
                    ),

                    // Spacer to balance Back Button
                    const SizedBox(width: 44),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Contact Methods Section ---
                    _SectionHeader(title: l10n.contactMethods),
                    const SizedBox(height: 12),

                    // Phone
                    _ContactCard(
                      icon: PhosphorIconsRegular.phoneCall,
                      title: l10n.phoneNumber,
                      value: '920000000',
                      onTap: () => _makePhoneCall('920000000'),
                      isDark: isDark,
                      isRtl: isRtl,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _ContactCard(
                      icon: PhosphorIconsRegular.envelopeSimple,
                      title: l10n.email,
                      value: 'info@msarat.sa',
                      onTap: () => _sendEmail('info@msarat.sa'),
                      isDark: isDark,
                      isRtl: isRtl,
                    ),
                    const SizedBox(height: 16),

                    // Website
                    _ContactCard(
                      icon: PhosphorIconsRegular.globe,
                      title: l10n.website,
                      value: 'www.msarat.sa',
                      onTap: () => _launchUrl('https://www.msarat.sa'),
                      isDark: isDark,
                      isRtl: isRtl,
                    ),
                    const SizedBox(height: 32),

                    // --- Social Media Section ---
                    _SectionHeader(title: l10n.socialMedia),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SocialButton(
                          icon: FontAwesomeIcons.whatsapp,
                          color: AppColors.whatsapp,
                          onTap: () => _launchUrl('https://wa.me/966500000000'),
                          isDark: isDark,
                        ),
                        _SocialButton(
                          icon: FontAwesomeIcons.facebook,
                          color: AppColors.facebook,
                          onTap: () =>
                              _launchUrl('https://facebook.com/msarat'),
                          isDark: isDark,
                        ),
                        _SocialButton(
                          icon: FontAwesomeIcons.instagram,
                          color: AppColors.instagram,
                          onTap: () =>
                              _launchUrl('https://instagram.com/msarat'),
                          isDark: isDark,
                        ),
                        _SocialButton(
                          icon: FontAwesomeIcons.xTwitter,
                          color: isDark ? Colors.white : Colors.black,
                          onTap: () => _launchUrl('https://twitter.com/msarat'),
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // --- Complaints Box Section ---
                    _SectionHeader(title: l10n.complaintsBox),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.cardBorderDark
                              : const Color(0xFFE5E7EB),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _complaintController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: l10n.complaintMessageHint,
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: isDark
                                  ? Colors.black12
                                  : const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.all(16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _submitComplaint,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: Transform(
                                alignment: Alignment.center,
                                transform: isRtl
                                    ? Matrix4.rotationY(math.pi)
                                    : Matrix4.identity(),
                                child: const Icon(Icons.send_rounded, size: 20),
                              ),
                              label: Text(
                                l10n.submit,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.start,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.primary,
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    required this.isDark,
    required this.isRtl,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool isDark;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon (Start/Right in RTL)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),

            // Text Content (Right Aligned implicit by Row/Column default in RTL)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Trailing Chevron (End/Left in RTL)
            Icon(
              isRtl
                  ? Icons
                        .keyboard_arrow_left_rounded // Left in RTL (Forward)
                  : Icons
                        .keyboard_arrow_right_rounded, // Right in LTR (Forward)
              size: 20,
              color: const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: Icon(icon, color: color, size: 32)),
      ),
    );
  }
}
