import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/injection.dart';
import '../../core/presentation/widgets/main_shell.dart';
import '../../features/shared/auth/presentation/cubit/auth_cubit.dart';
import '../../features/shared/auth/presentation/cubit/auth_state.dart';
import '../../features/shared/auth/presentation/screens/login_screen.dart';
import '../../features/shared/auth/presentation/screens/reset_password_screen.dart';
import '../../features/shared/auth/domain/entities/user_entity.dart';
import '../../features/teacher/teacher/domain/entities/classroom_entity.dart';
import '../../features/shared/settings/presentation/screens/settings_screen.dart';
import '../../features/shared/settings/presentation/screens/help_center_screen.dart';
import '../../features/teacher/attendance_history/presentation/screens/attendance_history_screen.dart';
import '../../features/teacher/attendance_history/presentation/cubit/attendance_history_cubit.dart';
import '../../features/teacher/attendance_history/domain/usecases/get_attendance_history_usecase.dart';

import '../../features/teacher/students/presentation/screens/class_details_screen.dart';
import '../../features/teacher/students/presentation/screens/my_classes_screen.dart';
import '../../features/teacher/students/presentation/cubit/my_classes_cubit.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart';
import '../../features/teacher/teacher/domain/usecases/get_teacher_classroom_usecase.dart';
import '../../features/teacher/teacher/presentation/cubit/teacher_cubit.dart';
import '../../features/teacher/teacher/presentation/screens/teacher_home_screen.dart';
import '../../features/shared/qr_scan/presentation/screens/qr_scan_screen.dart';
import '../../features/teacher/reports/presentation/screens/reports_screen.dart';
import '../../features/teacher/reports/presentation/cubit/reports_cubit.dart';
import '../../features/teacher/reports/domain/usecases/get_attendance_stats_usecase.dart';
import '../../features/teacher/reports/data/repositories/reports_repository_impl.dart';
import '../../features/teacher/reports/data/datasources/reports_remote_datasource.dart';
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
import '../../features/field_supervisor/home/presentation/screens/supervisor_home_screen.dart';
import '../../features/field_supervisor/reports/presentation/screens/reports_screen.dart'
    as supervisor_reports;
import '../../features/driver/home/presentation/screens/driver_home_screen.dart';
import '../../features/driver/route/presentation/screens/route_navigation_screen.dart';
import '../../features/driver/maintenance/presentation/screens/maintenance_entry_screen.dart';
import '../../features/driver/maintenance/presentation/screens/fuel_refill_screen.dart';
import '../../features/driver/maintenance/presentation/screens/maintenance_request_screen.dart';
import '../../features/driver/maintenance/presentation/screens/maintenance_logs_screen.dart';
import '../../features/driver/trip/presentation/screens/end_trip_screen.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/screens/trip_history_page.dart';
import 'app_routes.dart';

import '../../features/field_supervisor/buses/presentation/screens/buses_list_screen.dart';
import '../../features/field_supervisor/staff/presentation/screens/drivers_list_screen.dart';
import '../../features/field_supervisor/incidents/presentation/screens/sos_alerts_screen.dart';
import '../../features/field_supervisor/inspection/presentation/screens/field_inspection_screen.dart';
import '../../features/field_supervisor/delays/presentation/screens/delays_screen.dart';
import '../../features/field_supervisor/field_trips/presentation/screens/field_trips_screen.dart';
import '../../features/field_supervisor/buses/presentation/screens/supervisor_tracking_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
    navigatorKey: rootNavigatorKey,
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
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => TeacherCubit(
                    getTeacherClassroomUseCase:
                        getIt<GetTeacherClassroomUseCase>(),
                  )..loadClassroom(),
                ),
                BlocProvider(
                  create: (context) => ReportsCubit(
                    getAttendanceStatsUseCase: GetAttendanceStatsUseCase(
                      ReportsRepositoryImpl(ReportsRemoteDataSourceImpl()),
                    ),
                  )..loadReports(),
                ),
              ],
              child: const TeacherHomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.classDetails,
            name: 'classDetails',
            builder: (context, state) {
              final extra = state.extra;
              ClassroomEntity classroom;
              if (extra is ClassroomEntity) {
                classroom = extra;
              } else if (extra is Map<String, dynamic>) {
                classroom = ClassroomEntity(
                  id: extra['id']?.toString() ?? '',
                  name: extra['name']?.toString() ?? '',
                  grade: extra['grade']?.toString() ?? '',
                  studentCount: (extra['studentCount'] as int?) ?? 0,
                );
              } else {
                // Fallback: navigate back
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pop();
                });
                return const SizedBox.shrink();
              }
              return ClassDetailsScreen(classroom: classroom);
            },
          ),
          GoRoute(
            path: AppRoutes.myClasses,
            name: 'myClasses',
            builder: (context, state) => BlocProvider(
              create: (context) => MyClassesCubit(
                getTeacherClassroomsUseCase:
                    getIt<GetTeacherClassroomsUseCase>(),
              ),
              child: const MyClassesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.attendanceHistory,
            name: 'attendanceHistory',
            builder: (context, state) => BlocProvider(
              create: (context) => AttendanceHistoryCubit(
                getAttendanceHistoryUseCase:
                    getIt<GetAttendanceHistoryUseCase>(),
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
            path: AppRoutes.helpCenter,
            name: 'helpCenter',
            builder: (context, state) => const HelpCenterScreen(),
          ),
          GoRoute(
            path: AppRoutes.qrScan,
            name: 'qrScan',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                return QRScanScreen(
                  classId: extra['classId'] as String?,
                  isTripMode: extra['isTripMode'] as bool? ?? false,
                );
              }
              return QRScanScreen(classId: extra as String?);
            },
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            builder: (context, state) => BlocProvider(
              create: (context) => ReportsCubit(
                getAttendanceStatsUseCase: GetAttendanceStatsUseCase(
                  ReportsRepositoryImpl(ReportsRemoteDataSourceImpl()),
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
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  BusTripCubit(repository: AssistantRepositoryImpl())
                    ..loadTrip(),
              child: const BusMapScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.messages,
            name: 'messages',
            builder: (context, state) {
              final Map<String, dynamic>? extra = (state.extra as Map?)?.cast<String, dynamic>();
              return MessagesScreen(
                conversationId: extra?['id']?.toString(),
                recipientName: extra?['name']?.toString(),
                recipientAvatarUrl: extra?['avatarUrl']?.toString(),
                receiverId: extra?['receiverId']?.toString(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.chats,
            name: 'chats',
            builder: (context, state) => const ChatsListScreen(),
          ),

          // Driver Routes
          GoRoute(
            path: AppRoutes.driverHome,
            name: 'driverHome',
            builder: (context, state) => const DriverHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.driverRoute,
            name: 'driverRoute',
            builder: (context, state) => const RouteNavigationScreen(),
          ),
          GoRoute(
            path: AppRoutes.driverMaintenance,
            name: 'driverMaintenance',
            builder: (context, state) => const MaintenanceEntryScreen(),
          ),
          GoRoute(
            path: AppRoutes.driverFuel,
            name: 'driverFuel',
            builder: (context, state) => const FuelRefillScreen(),
          ),
          GoRoute(
            path: AppRoutes.driverMaintenanceRequest,
            name: 'driverMaintenanceRequest',
            builder: (context, state) => const MaintenanceRequestScreen(),
          ),
          GoRoute(
            path: AppRoutes.driverMaintenanceLogs,
            name: 'driverMaintenanceLogs',
            builder: (context, state) => const MaintenanceLogsScreen(),
          ),
          GoRoute(
            path: AppRoutes.driverEndTrip,
            name: 'driverEndTrip',
            builder: (context, state) => const EndTripScreen(),
          ),
          GoRoute(
            path: AppRoutes.driverStudents,
            name: 'driverStudents',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  BusTripCubit(repository: AssistantRepositoryImpl())
                    ..loadTrip(),
              child: const BusStudentsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.driverTrips,
            name: 'driverTrips',
            builder: (context, state) => const TripHistoryPage(),
          ),
        ],
      ),

      // Field Supervisor Routes
      GoRoute(
        path: AppRoutes.supervisorHome,
        name: 'supervisorHome',
        builder: (context, state) => const SupervisorHomeScreen(),
        routes: [
          GoRoute(
            path: 'buses',
            name: 'supervisorBuses',
            builder: (context, state) => const BusesListScreen(),
          ),
          GoRoute(
            path: 'drivers',
            name: 'supervisorDrivers',
            builder: (context, state) => const DriversListScreen(),
          ),
          GoRoute(
            path: 'alerts',
            name: 'supervisorAlerts',
            builder: (context, state) => const SosAlertsScreen(),
          ),
          GoRoute(
            path: 'inspection',
            name: 'supervisorInspection',
            builder: (context, state) => const FieldInspectionScreen(),
          ),
          GoRoute(
            path: 'delays',
            name: 'supervisorDelays',
            builder: (context, state) => const DelaysScreen(),
          ),
          GoRoute(
            path: 'trips',
            name: 'supervisorTrips',
            builder: (context, state) => const FieldTripsScreen(),
          ),
          GoRoute(
            path: 'reports',
            name: 'supervisorReports',
            builder: (context, state) =>
                const supervisor_reports.ReportsScreen(),
          ),
          GoRoute(
            path: 'tracking/:busId',
            name: 'supervisorTracking',
            builder: (context, state) {
              final busId =
                  int.tryParse(state.pathParameters['busId'] ?? '0') ?? 0;
              return SupervisorTrackingScreen(busId: busId);
            },
          ),
        ],
      ),
    ],
  );

  /// Redirect logic based on authentication state.
  String? _guardRoute(BuildContext context, GoRouterState state) {
    final authState = authCubit.state;
    debugPrint('🚦 [Router] Guard checking route: ${state.matchedLocation} | State: $authState');
    
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
      String target = AppRoutes.teacherHome;
      if (authState.user.role == UserRole.assistant) {
        target = AppRoutes.assistantHome;
      } else if (authState.user.role == UserRole.driver) {
        target = AppRoutes.driverHome;
      } else if (authState.user.role == UserRole.fieldSupervisor) {
        target = AppRoutes.supervisorHome;
      }
      debugPrint('🚀 [Router] Authenticated! Redirecting from login to: $target');
      return target;
    }

    // Role-based route protection
    if (isAuthenticated) {
      // Prevent Field Supervisors from accessing Teacher Home
      if (authState.user.role == UserRole.fieldSupervisor &&
          (state.matchedLocation == AppRoutes.teacherHome ||
              state.matchedLocation == '/')) {
        return AppRoutes.supervisorHome;
      }
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
