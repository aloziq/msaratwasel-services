import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/app_theme.dart';
import 'package:msaratwasel_services/config/theme/brand_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _ShrinkingProfileHeaderDelegate(
              maxExtent: 380,
              minExtent: MediaQuery.of(context).padding.top + 80,
              theme: theme,
              isDark: isDark,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'الإحصائيات', // Statistics
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : BrandColors.textPrimary,
                  ),
                ).animate().fadeIn().slideX(begin: 0.2, end: 0),
                const SizedBox(height: AppSpacing.md),
                _buildStatsRow(
                  context,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'المعلومات الشخصية', // Personal Information
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : BrandColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, end: 0),
                const SizedBox(height: AppSpacing.md),
                _buildInfoTile(
                  context,
                  icon: PhosphorIconsDuotone.identificationCard,
                  label: 'الرقم المدني', // Civil ID
                  value: '1234567890',
                  delay: 300.ms,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildInfoTile(
                  context,
                  icon: PhosphorIconsDuotone.phone,
                  label: 'رقم الهاتف', // Phone Number
                  value: '+966 50 123 4567',
                  delay: 400.ms,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildInfoTile(
                  context,
                  icon: PhosphorIconsDuotone.envelope,
                  label: 'البريد الإلكتروني', // Email
                  value: 'mohammed@wasel.edu.sa',
                  delay: 500.ms,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            label: 'الفصول', // Classes
            value: '4',
            icon: PhosphorIconsDuotone.chalkboardTeacher,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            context,
            label: 'الطلاب', // Students
            value: '128',
            icon: PhosphorIconsDuotone.student,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : BrandColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : BrandColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white60 : BrandColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Duration delay,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : BrandColors.border.withValues(alpha: 0.5),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : BrandColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white70 : BrandColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : BrandColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : BrandColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: 0.2, end: 0);
  }
}

class _ShrinkingProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxExtent;
  final double minExtent;
  final ThemeData theme;
  final bool isDark;

  _ShrinkingProfileHeaderDelegate({
    required this.maxExtent,
    required this.minExtent,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;

    // Animation values
    final avatarScale = 1.0 - (progress * 0.45); // Scales to ~0.55

    // Horizontal positions
    // Avatar: Start centered, end at left: 16
    final initialAvatarLeft = (screenWidth / 2) - 60;
    final finalAvatarLeft = 16.0;
    final currentAvatarLeft =
        initialAvatarLeft + (progress * (finalAvatarLeft - initialAvatarLeft));

    // Vertical positions
    final initialAvatarTop = 110.0;
    final finalAvatarTop = topPadding + 6; // Center better in 80h bar
    final currentAvatarTop =
        initialAvatarTop + (progress * (finalAvatarTop - initialAvatarTop));

    // Name position: Start centered below avatar, end at right: 72
    final initialNameTop = initialAvatarTop + 120 + 16;
    final finalNameTop = topPadding + 26; // Center better in 80h bar
    final currentNameTop =
        initialNameTop + (progress * (finalNameTop - initialNameTop));

    final nameScale = 1.0 - (progress * 0.25);
    final nameShadowAlpha = (1.0 - progress).clamp(0.0, 1.0);

    final roleOpacity = (1.0 - progress * 4.0).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Gradient
        ClipPath(
          clipper: _HeaderClipper(progress: progress),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient(context),
            ),
          ),
        ),

        // Back Button
        Positioned(
          top: topPadding + 10,
          right: 16,
          child: const BackButton(color: Colors.white),
        ),

        // Avatar
        Positioned(
          top: currentAvatarTop,
          left: currentAvatarLeft,
          child: Transform.scale(
            scale: avatarScale,
            alignment: Alignment.topLeft,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2 * (1 - progress)),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/300?img=11',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Name
        Positioned(
          top: currentNameTop,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Transform.scale(
              scale: nameScale,
              alignment: Alignment.lerp(
                Alignment.center,
                Alignment.centerRight,
                progress,
              )!,
              child: Container(
                padding: EdgeInsets.only(
                  right: progress * 64,
                ), // Avoid overlapping back button
                alignment: Alignment.lerp(
                  Alignment.center,
                  Alignment.centerRight,
                  progress,
                )!,
                child: Text(
                  'عبدالله الأحمد',
                  textAlign: progress > 0.5
                      ? TextAlign.right
                      : TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(
                          alpha: 0.26 * nameShadowAlpha,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Role Badge
        Positioned(
          top: initialNameTop + 40,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: roleOpacity,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'معلم صف',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(_ShrinkingProfileHeaderDelegate oldDelegate) {
    return oldDelegate.maxExtent != maxExtent ||
        oldDelegate.minExtent != minExtent ||
        oldDelegate.theme != theme ||
        oldDelegate.isDark != isDark;
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  final double progress;

  _HeaderClipper({this.progress = 0.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final curveHeight = 60.0 * (1.0 - progress);

    path.lineTo(0, size.height - curveHeight);
    if (curveHeight > 0) {
      path.quadraticBezierTo(
        size.width / 2,
        size.height,
        size.width,
        size.height - curveHeight,
      );
    } else {
      path.lineTo(size.width, size.height);
    }
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_HeaderClipper oldClipper) =>
      oldClipper.progress != progress;
}
