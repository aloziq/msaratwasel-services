import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/core/presentation/widgets/app_drawer.dart'; // Added Import
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/core/presentation/extensions/user_role_extension.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/presentation/widgets/adaptive_sliver_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Added Key
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle error if permissions are denied or other issues
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _showImageSourceActionSheet(BuildContext context, bool isArabic) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(isArabic ? 'تغيير الصورة الشخصية' : 'Change Profile Photo'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: Text(isArabic ? 'التقاط صورة' : 'Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: Text(isArabic ? 'اختر من المعرض' : 'Choose from Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      key: _scaffoldKey, // Assigned Key
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(), // Added Drawer
      body: CustomScrollView(
        slivers: [
          // Navigation Bar
          AdaptiveSliverAppBar(
            title: isArabic ? 'الملف الشخصي' : 'Profile',
            backgroundColor: theme.scaffoldBackgroundColor,
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
            trailing: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.camera_alt_rounded,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () => _showImageSourceActionSheet(context, isArabic),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10), // Extra headers spacing
                // Profile Header Card
                // Profile Header Card
                Builder(
                  builder: (context) {
                    final authState = context.watch<AuthCubit>().state;
                    String displayName = isArabic
                        ? "عبدالله الأحمد"
                        : "Abdullah Al-Ahmad";
                    String displayRole = isArabic
                        ? "مشرف حافلة"
                        : "Bus Supervisor";
                    String avatar = 'https://i.pravatar.cc/300?img=11';

                    if (authState is AuthAuthenticated) {
                      displayName = authState.user.name;
                      displayRole = authState.user.role.getDisplayName(context);
                      // TODO: Use real avatar from user entity when available
                    }

                    return _ProfileHeader(
                      name: displayName,
                      role: displayRole,
                      isArabic: isArabic,
                      isDark: isDark,
                      avatarUrl: avatar,
                      profileImage: _profileImage,
                      onChangePhoto: () =>
                          _showImageSourceActionSheet(context, isArabic),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Personal Information Section
                _SectionTitle(
                  title: isArabic
                      ? "المعلومات الشخصية"
                      : "Personal Information",
                  icon: PhosphorIconsRegular.user,
                  isDark: isDark,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: AppSpacing.md),

                _InfoCard(
                  icon: PhosphorIconsRegular.identificationCard,
                  label: isArabic ? "الرقم المدني" : "Civil ID",
                  value: "1234567890",
                  isDark: isDark,
                  delay: 200.ms,
                ),
                const SizedBox(height: AppSpacing.sm),

                _InfoCard(
                  icon: PhosphorIconsRegular.phone,
                  label: isArabic ? "رقم الهاتف" : "Phone Number",
                  value: "+966 50 123 4567",
                  isDark: isDark,
                  delay: 300.ms,
                ),
                const SizedBox(height: AppSpacing.sm),

                _InfoCard(
                  icon: PhosphorIconsRegular.envelope,
                  label: isArabic ? "البريد الإلكتروني" : "Email",
                  value: "mohammed@wasel.edu.sa",
                  isDark: isDark,
                  delay: 400.ms,
                ),

                const SizedBox(height: AppSpacing.xl),

                const SizedBox(height: AppSpacing.xl),

                // Role Based Information Section
                Builder(
                  builder: (context) {
                    final authState = context.watch<AuthCubit>().state;
                    final userRole = authState is AuthAuthenticated
                        ? authState.user.role
                        : null;

                    if (userRole == UserRole.fieldSupervisor) {
                      return const SizedBox.shrink();
                    }

                    if (userRole == UserRole.teacher) {
                      return Column(
                        children: [
                          _SectionTitle(
                            title: isArabic
                                ? "معلومات المدرسة"
                                : "School Information",
                            icon: PhosphorIconsRegular.graduationCap,
                            isDark: isDark,
                          ).animate().fadeIn(delay: 500.ms),
                          const SizedBox(height: AppSpacing.md),
                          _InfoCard(
                            icon: PhosphorIconsRegular.buildings,
                            label: isArabic ? "اسم المدرسة" : "School Name",
                            value: isArabic ? "مدرسة الأمل" : "Al-Amal School",
                            isDark: isDark,
                            delay: 600.ms,
                          ),
                        ],
                      );
                    }

                    // Default (Driver/Assistant) - Bus Info
                    return Column(
                      children: [
                        _SectionTitle(
                          title: isArabic
                              ? "معلومات الحافلة"
                              : "Bus Information",
                          icon: PhosphorIconsRegular.bus,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 500.ms),
                        const SizedBox(height: AppSpacing.md),
                        _InfoCard(
                          icon: PhosphorIconsRegular.hash,
                          label: isArabic ? "رقم الحافلة" : "Bus Number",
                          value: "15",
                          isDark: isDark,
                          delay: 600.ms,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoCard(
                          icon: PhosphorIconsRegular.columns,
                          label: isArabic ? "رقم اللوحة" : "Plate Number",
                          value: "أ ب ج 1234",
                          isDark: isDark,
                          delay: 700.ms,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoCard(
                          icon: PhosphorIconsRegular.usersThree,
                          label: isArabic ? "السعة" : "Capacity",
                          value: isArabic ? "25 طالب" : "25 Students",
                          isDark: isDark,
                          delay: 800.ms,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Logout Button
                _ProfileActionButton(
                  icon: Icons.logout_rounded,
                  label: isArabic ? "تسجيل الخروج" : "Logout",
                  color: theme.colorScheme.error,
                  isDark: isDark,
                  isHorizontal: true,
                  onTap: () {
                    context.read<AuthCubit>().logout();
                  },
                ).animate().fadeIn(delay: 700.ms),

                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.role,
    required this.isArabic,
    required this.isDark,
    required this.avatarUrl,
    required this.onChangePhoto,
    this.profileImage,
  });

  final String name;
  final String role;
  final bool isArabic;
  final bool isDark;
  final String avatarUrl;
  final VoidCallback onChangePhoto;
  final File? profileImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            AppColors.lightBlue,
          ], // Blue Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: profileImage != null
                      ? FileImage(profileImage!) as ImageProvider
                      : NetworkImage(avatarUrl),
                ),
              ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onChangePhoto,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  final String title;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? Colors.white : theme.colorScheme.primary,
          size: 22,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.delay,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Duration? delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (delay != null) {
      return card.animate().fadeIn(delay: delay).slideX(begin: 0.1, end: 0);
    }
    return card;
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.isHorizontal = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final bool isHorizontal;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: isHorizontal
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isDark ? Colors.white : color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // ... Not used currently
                  ],
                ),
        ),
      ),
    );
  }
}
