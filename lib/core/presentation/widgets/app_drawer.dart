import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/utils/gps_security_helper.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:msaratwasel_services/core/presentation/widgets/directional_icon.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart';
import 'package:msaratwasel_services/core/presentation/extensions/user_role_extension.dart';
import 'package:msaratwasel_services/core/network/api_config.dart';

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
    final drawerBg = isDark ? AppColors.darkSurface : Colors.white;

    String currentLocation = '/';
    try {
      currentLocation = GoRouterState.of(context).uri.path;
    } catch (e) {
      // Fallback if GoRouterState is not available (e.g., when used in local Scaffold)
      debugPrint('AppDrawer: Could not get GoRouterState: $e');
    }

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
                          color: isDark
                              ? AppColors.errorDark
                              : theme.colorScheme.error.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.transparent,
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
                  ? (isDark ? AppColors.secondary : AppColors.primary)
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
            if (currentLocation != AppRoutes.attendanceHistory) {
              context.push(AppRoutes.attendanceHistory);
            }
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
            if (currentLocation != AppRoutes.reports) {
              context.push(AppRoutes.reports);
            }
          },
        ),
      );
    }

    // ---------------- ASSISTANT ROLE ----------------
    if (role == UserRole.assistant) {
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
            if (currentLocation != AppRoutes.busStudents) {
              context.push(AppRoutes.busStudents);
            }
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
            if (currentLocation != AppRoutes.dailyChecklist) {
              context.push(AppRoutes.dailyChecklist);
            }
          },
        ),
      );

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
            if (currentLocation != AppRoutes.busMap) {
              context.push(AppRoutes.busMap);
            }
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

    // ---------------- DRIVER ROLE ----------------
    if (role == UserRole.driver) {
      items.add(
        _DrawerItem(
          title: l10n.home,
          icon: PhosphorIconsRegular.house,
          isSelected: currentLocation == AppRoutes.driverHome,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.driverHome);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.navigation,
          icon: PhosphorIconsRegular.mapTrifold,
          isSelected: currentLocation == AppRoutes.driverRoute,
          isDark: isDark,
          onTap: () async {
            final hasGps = await GpsSecurityHelper.checkLocationServices(context);
            if (!hasGps) return;
            if (context.mounted) {
              Navigator.pop(context);
              context.push(AppRoutes.driverRoute);
            }
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.trips,
          icon: PhosphorIconsRegular.path,
          isSelected: currentLocation == AppRoutes.driverTrips,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.driverTrips);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.myStudents,

          icon: PhosphorIconsRegular.users,
          isSelected: currentLocation == AppRoutes.driverStudents,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.driverStudents);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.maintenance,
          icon: PhosphorIconsRegular.wrench,
          isSelected: currentLocation == AppRoutes.driverMaintenance,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.driverMaintenance);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.endTrip,
          icon: PhosphorIconsRegular.checkCircle,
          isSelected: currentLocation == AppRoutes.driverEndTrip,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.driverEndTrip);
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
          isSelected: currentLocation == AppRoutes.supervisorHome,
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.supervisorHome);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.busTracking,
          icon: PhosphorIconsRegular.mapPin,
          isSelected: currentLocation.startsWith(AppRoutes.supervisorBuses),
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.supervisorBuses);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.driversAndSupervisors,
          icon: PhosphorIconsRegular.usersThree,
          isSelected: currentLocation.startsWith(AppRoutes.supervisorDrivers),
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.supervisorDrivers);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.incidentsAndEmergencies,
          icon: PhosphorIconsRegular.warningCircle,
          isSelected: currentLocation.startsWith(AppRoutes.supervisorAlerts),
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.supervisorAlerts);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.fieldInspection,
          icon: PhosphorIconsRegular.clipboardText,
          isSelected: currentLocation.startsWith(
            AppRoutes.supervisorInspection,
          ),
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.supervisorInspection);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.registerDelays,
          icon: PhosphorIconsRegular.timer,
          isSelected: currentLocation.startsWith(AppRoutes.supervisorDelays),
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.supervisorDelays);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.fieldTrips,
          icon: PhosphorIconsRegular.compass,
          isSelected: currentLocation.startsWith(AppRoutes.supervisorTrips),
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.supervisorTrips);
          },
        ),
      );

      items.add(
        _DrawerItem(
          title: l10n.reports,
          icon: PhosphorIconsRegular.chartBar,
          isSelected: currentLocation.startsWith(AppRoutes.supervisorReports),
          isDark: isDark,
          onTap: () {
            Navigator.pop(context);
            context.go(AppRoutes.supervisorReports);
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
      future: getIt<GetTeacherClassroomsUseCase>()(),
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
                    color: isDark ? Colors.white70 : AppColors.primary,
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
                title: AppLocalizations.of(context)!.myStudents,
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
                  child: Builder(
                    builder: (itemContext) {
                      return _DrawerItem(
                        title: classroom.name,
                        icon: PhosphorIconsRegular.door,
                        isSelected: false,
                        isDark: isDark,
                        onTap: () async {
                          // Capture router before closing drawer
                          final router = GoRouter.of(context);
                          Navigator.pop(context);
                          await router.push(
                            AppRoutes.classDetails.replaceFirst(
                              ':classId',
                              classroom.id,
                            ),
                            extra: classroom,
                          );
                          // We might not have the right build context to read Cubits here.
                          // But we can try utilizing a widely available context if possible.
                        },
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
    final l10n = AppLocalizations.of(context)!;
    final name = (user?.role == UserRole.teacher)
        ? (user?.getLocalizedName('en') ?? l10n.home)
        : (user?.name ?? l10n.home);
    final roleName = user?.role.getDisplayName(context) ?? '';

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
              alignment: AlignmentDirectional.centerStart,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white24
                          : AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: Image.network(
                        ApiConfig.getImageUrl(user?.avatar),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: isDark
                                ? Colors.white12
                                : AppColors.primary.withValues(alpha: 0.08),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.primary,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          final initial = (user?.name.isNotEmpty == true)
                              ? user!.name[0].toUpperCase()
                              : '؟';
                          return Container(
                            color: isDark
                                ? Colors.white12
                                : AppColors.primary.withValues(alpha: 0.1),
                            child: Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.profile);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
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
              : AppColors.primary.withValues(alpha: 0.08))
        : Colors.transparent;

    final Color foregroundColor = isSelected
        ? (isDark ? AppColors.secondary : AppColors.primary)
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
          leading: DirectionalIcon(icon, color: foregroundColor, size: 22),
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
