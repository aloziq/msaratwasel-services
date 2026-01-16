import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/presentation/widgets/main_shell.dart';

import '../../features/shared/auth/presentation/cubit/auth_cubit.dart';
import '../../features/shared/auth/presentation/cubit/auth_state.dart';
import '../../features/shared/auth/presentation/screens/login_screen.dart';
import '../../features/shared/auth/presentation/screens/reset_password_screen.dart';
import '../../features/shared/auth/domain/entities/user_entity.dart';
import '../../features/teacher/teacher/domain/entities/classroom_entity.dart';
import '../../features/shared/settings/presentation/screens/settings_screen.dart';
import '../../features/teacher/attendance_history/presentation/screens/attendance_history_screen.dart';
import '../../features/teacher/attendance_history/presentation/cubit/attendance_history_cubit.dart';
import '../../features/teacher/attendance_history/domain/usecases/get_attendance_history_usecase.dart';
import '../../features/teacher/attendance_history/data/repositories/attendance_history_repository_impl.dart';
import '../../features/teacher/students/presentation/screens/class_details_screen.dart';
import '../../features/teacher/students/presentation/screens/my_classes_screen.dart';
import '../../features/teacher/students/presentation/cubit/my_classes_cubit.dart';
import '../../features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart';
import '../../features/teacher/teacher/presentation/screens/teacher_home_screen.dart';
import '../../features/shared/qr_scan/presentation/screens/qr_scan_screen.dart';
import '../../features/teacher/reports/presentation/screens/reports_screen.dart';
import '../../features/teacher/reports/presentation/cubit/reports_cubit.dart';
import '../../features/teacher/reports/domain/usecases/get_attendance_stats_usecase.dart';
import '../../features/teacher/reports/data/repositories/reports_repository_impl.dart';
import '../../features/shared/profile/presentation/screens/profile_screen.dart';
import '../../features/assistant/home/presentation/screens/assistant_home_screen.dart';
import '../../features/assistant/students/presentation/screens/bus_students_screen.dart';
import '../../features/assistant/checklist/presentation/screens/daily_checklist_screen.dart';
import '../../features/assistant/incidents/presentation/screens/incident_report_screen.dart';
import '../../features/assistant/tracking/presentation/screens/bus_map_screen.dart';
import '../../features/assistant/core/presentation/cubit/bus_trip_cubit.dart';
import '../../features/assistant/core/data/repositories/assistant_repository_impl.dart';
import '../../features/shared/messages/presentation/screens/messages_screen.dart';
import '../../features/shared/messages/presentation/screens/chats_list_screen.dart';
import 'app_routes.dart';

/// Application router configuration using GoRouter.
///
/// Features:
/// - Declarative route definitions
/// - Authentication-based redirects
/// - Type-safe navigation with path parameters
class AppRouter {
  final AuthCubit authCubit;

  AppRouter({required this.authCubit});

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: _guardRoute,
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Teacher routes wrapped in MainShell
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.teacherHome,
            name: 'teacherHome',
            builder: (context, state) => const TeacherHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.classDetails,
            name: 'classDetails',
            builder: (context, state) {
              final classroom = state.extra as ClassroomEntity;
              return ClassDetailsScreen(classroom: classroom);
            },
          ),
          GoRoute(
            path: AppRoutes.myClasses,
            name: 'myClasses',
            builder: (context, state) => BlocProvider(
              create: (context) => MyClassesCubit(
                getTeacherClassroomsUseCase: context
                    .read<GetTeacherClassroomsUseCase>(),
              ),
              child: const MyClassesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.attendanceHistory,
            name: 'attendanceHistory',
            builder: (context, state) => BlocProvider(
              create: (context) => AttendanceHistoryCubit(
                getAttendanceHistoryUseCase: GetAttendanceHistoryUseCase(
                  AttendanceHistoryRepositoryImpl(),
                ),
              )..loadHistory(),
              child: const AttendanceHistoryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.qrScan,
            name: 'qrScan',
            builder: (context, state) => const QRScanScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            builder: (context, state) => BlocProvider(
              create: (context) => ReportsCubit(
                getAttendanceStatsUseCase: GetAttendanceStatsUseCase(
                  ReportsRepositoryImpl(),
                ),
              ),
              child: const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.assistantHome,
            name: 'assistantHome',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  BusTripCubit(repository: AssistantRepositoryImpl())
                    ..loadTrip(),
              child: const AssistantHomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.busStudents,
            name: 'busStudents',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  BusTripCubit(repository: AssistantRepositoryImpl())
                    ..loadTrip(),
              child: const BusStudentsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.dailyChecklist,
            name: 'dailyChecklist',
            builder: (context, state) => const DailyChecklistScreen(),
          ),
          GoRoute(
            path: AppRoutes.incidentReport,
            name: 'incidentReport',
            builder: (context, state) => const IncidentReportScreen(),
          ),
          GoRoute(
            path: AppRoutes.busMap,
            name: 'busMap',
            builder: (context, state) => const BusMapScreen(),
          ),
          GoRoute(
            path: AppRoutes.messages,
            name: 'messages',
            builder: (context, state) {
              final recipientName = state.extra as String?;
              return MessagesScreen(recipientName: recipientName);
            },
          ),
          GoRoute(
            path: AppRoutes.chats,
            name: 'chats',
            builder: (context, state) => const ChatsListScreen(),
          ),
        ],
      ),
    ],
  );

  /// Redirect logic based on authentication state.
  String? _guardRoute(BuildContext context, GoRouterState state) {
    final authState = authCubit.state;
    final isAuthenticated = authState is AuthAuthenticated;
    final isOnAuthRoute =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.resetPassword;

    // If not authenticated and trying to access protected route, redirect to login
    if (!isAuthenticated && !isOnAuthRoute) {
      return AppRoutes.login;
    }

    // If authenticated and on login page, redirect to home
    if (isAuthenticated && state.matchedLocation == AppRoutes.login) {
      if (authState.user.role == UserRole.busAssistant) {
        return AppRoutes.assistantHome;
      }
      return AppRoutes.teacherHome;
    }

    return null; // No redirect needed
  }
}

/// Converts a Stream into a Listenable for GoRouter refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
