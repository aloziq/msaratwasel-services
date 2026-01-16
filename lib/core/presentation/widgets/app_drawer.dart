import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/brand_colors.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isStudentsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;
    final subTextColor = isDark
        ? Colors.white70
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final drawerBg = isDark ? theme.colorScheme.primary : Colors.white;

    final currentLocation = GoRouterState.of(context).matchedLocation;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final role = user?.role ?? UserRole.teacher;

        return Drawer(
          elevation: 10,
          backgroundColor: drawerBg,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.horizontal(
              end: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------- HEADER ----------------
              _buildHeader(
                context,
                user,
                drawerBg,
                textColor,
                subTextColor,
                isDark,
              ),

              // ---------------- MENU ----------------
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xl,
                    horizontal: AppSpacing.md,
                  ),
                  children: _buildMenuItems(
                    context,
                    role,
                    currentLocation,
                    isDark,
                    theme,
                    l10n,
                  ),
                ),
              ),

              // ---------------- LOGOUT ----------------
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SafeArea(
                  top: false,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<AuthCubit>().logout();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    icon: Icon(PhosphorIconsRegular.signOut, size: 22),
                    label: Text(
                      l10n.logout,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMenuItems(
    BuildContext context,
    UserRole role,
    String currentLocation,
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final List<Widget> items = [];

    // ---------------- TEACHER ROLE ----------------
    if (role == UserRole.teacher) {
      items.add(
        _DrawerItem(
          title: l10n.home,
          icon: PhosphorIconsRegular.house,
          isSelected: currentLocation == AppRoutes.teacherHome,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.teacherHome);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.myStudents,
          icon: PhosphorIconsRegular.users,
          isSelected:
              currentLocation == AppRoutes.myClasses ||
              currentLocation == AppRoutes.classDetails,
          isDark: isDark,
          onTap: () {
            setState(() {
              _isStudentsExpanded = !_isStudentsExpanded;
            });
          },
          trailing: AnimatedRotation(
            turns: _isStudentsExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              PhosphorIconsRegular.caretDown,
              size: 18,
              color:
                  (currentLocation == AppRoutes.myClasses ||
                      currentLocation == AppRoutes.classDetails)
                  ? (isDark ? BrandColors.secondary : BrandColors.primary)
                  : (isDark
                        ? Colors.white70
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
        ),
      );

      if (_isStudentsExpanded) {
        items.add(_buildClassroomsList(context, currentLocation, isDark));
      }

      items.add(
        _DrawerItem(
          title: l10n.attendanceHistory,
          icon: PhosphorIconsRegular.clockCounterClockwise,
          isSelected: currentLocation == AppRoutes.attendanceHistory,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.attendanceHistory);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.reports,
          icon: PhosphorIconsRegular.chartBar,
          isSelected: currentLocation == AppRoutes.reports,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.reports);
          },
        ),
      );
    }

    // ---------------- ASSISTANT / DRIVER ROLE ----------------
    if (role == UserRole.busAssistant || role == UserRole.driver) {
      items.add(
        _DrawerItem(
          title: l10n.home,
          icon: PhosphorIconsRegular.house,
          isSelected: currentLocation == AppRoutes.assistantHome,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.assistantHome);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.studentsList,
          icon: PhosphorIconsRegular.users,
          isSelected: currentLocation == AppRoutes.busStudents,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.busStudents);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.dailyChecklist,
          icon: PhosphorIconsRegular.checkCircle,
          isSelected: currentLocation == AppRoutes.dailyChecklist,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.dailyChecklist);
          },
        ),
      );

      // Moved from home screen to drawer as per request
      items.add(
        _DrawerItem(
          title: l10n.incidentReportTitle,
          icon: PhosphorIconsRegular.warningCircle,
          isSelected: currentLocation == AppRoutes.incidentReport,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.push(AppRoutes.incidentReport);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.busTracking,
          icon: PhosphorIconsRegular.mapPin,
          isSelected: currentLocation == AppRoutes.busMap,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.busMap);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.chats,
          icon: PhosphorIconsRegular.chats,
          isSelected: currentLocation == AppRoutes.chats,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.push(AppRoutes.chats);
          },
        ),
      );
    }

    // ---------------- FIELD SUPERVISOR ROLE ----------------
    if (role == UserRole.fieldSupervisor) {
      items.add(
        _DrawerItem(
          title: l10n.home,
          icon: PhosphorIconsRegular.house,
          isSelected: currentLocation == AppRoutes.teacherHome,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.teacherHome);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.reports,
          icon: PhosphorIconsRegular.chartBar,
          isSelected: currentLocation == AppRoutes.reports,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.reports);
          },
        ),
      );
    }

    // ---------------- COMMON ITEMS ----------------
    items.add(
      _DrawerItem(
        title: l10n.settings,
        icon: PhosphorIconsRegular.gearSix,
        isSelected: currentLocation == AppRoutes.settings,
        isDark: isDark,
        onTap: () {
          Navigator.pop(context);
          context.push(AppRoutes.settings);
        },
      ),
    );

    return items;
  }

  Widget _buildClassroomsList(
    BuildContext context,
    String currentLocation,
    bool isDark,
  ) {
    return FutureBuilder<Either<String, List<ClassroomEntity>>>(
      future: context.read<GetTeacherClassroomsUseCase>()(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(start: 32),
            child: SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.white70 : BrandColors.primary,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return snapshot.data!.fold(
            (error) => Padding(
              padding: const EdgeInsetsDirectional.only(start: 32),
              child: _DrawerItem(
                title: 'فصولي',
                icon: PhosphorIconsRegular.chalkboardTeacher,
                isSelected: currentLocation == AppRoutes.myClasses,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.myClasses);
                },
              ),
            ),
            (classrooms) => Column(
              children: classrooms.map((classroom) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(start: 32),
                  child: _DrawerItem(
                    title: classroom.name,
                    icon: PhosphorIconsRegular.door,
                    isSelected: false,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        AppRoutes.classDetails.replaceFirst(
                          ':classId',
                          classroom.id,
                        ),
                        extra: classroom,
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    UserEntity? user,
    Color drawerBg,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    final name = user?.name ?? 'المستخدم';
    final roleName = user?.role.displayName ?? 'زائر';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: drawerBg,
        borderRadius: const BorderRadiusDirectional.only(
          bottomEnd: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
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
                      color: isDark
                          ? Colors.white24
                          : BrandColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 42,
                    backgroundImage: NetworkImage(
                      "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400",
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BrandColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              name,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roleName,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color backgroundColor = isSelected
        ? (isDark
              ? Colors.white.withValues(alpha: 0.1)
              : BrandColors.primary.withValues(alpha: 0.08))
        : Colors.transparent;

    final Color foregroundColor = isSelected
        ? (isDark ? BrandColors.secondary : BrandColors.primary)
        : (isDark
              ? Colors.white70
              : theme.colorScheme.onSurface.withValues(alpha: 0.7));

    final FontWeight fontWeight = isSelected
        ? FontWeight.w700
        : FontWeight.w500;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          minLeadingWidth: 24,
          leading: Icon(icon, color: foregroundColor, size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: fontWeight,
              color: foregroundColor,
              fontSize: 14,
            ),
          ),
          trailing:
              trailing ??
              (isSelected
                  ? Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: foregroundColor,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null),
        ),
      ),
    );
  }
}
