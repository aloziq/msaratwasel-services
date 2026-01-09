import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/routes/app_router.dart';
import 'config/settings/settings_controller.dart';
import 'config/theme/app_theme.dart';
import 'config/theme/theme_controller.dart';
import 'features/shared/auth/data/datasources/auth_local_data_source.dart';
import 'features/shared/auth/data/datasources/auth_remote_data_source.dart';
import 'features/shared/auth/data/repositories/auth_repository_impl.dart';
import 'features/shared/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/shared/auth/domain/usecases/login_usecase.dart';
import 'features/shared/auth/domain/usecases/logout_usecase.dart';
import 'features/shared/auth/domain/usecases/reset_password_usecase.dart';
import 'features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'features/teacher/teacher/data/datasources/teacher_local_datasource.dart';
import 'features/teacher/teacher/data/repositories/teacher_repository_impl.dart';
import 'features/teacher/teacher/domain/usecases/get_teacher_classroom_usecase.dart';
import 'features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart';
import 'features/teacher/students/domain/usecases/get_students_usecase.dart';
import 'features/teacher/students/domain/usecases/mark_attendance_usecase.dart';
import 'features/teacher/students/data/repositories/students_repository_impl.dart';
import 'features/teacher/students/presentation/cubit/class_details_cubit.dart';
import 'features/teacher/teacher/presentation/cubit/teacher_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize ThemeController
  final themeController = ThemeController();
  await themeController.load();

  // Initialize SettingsController
  final settingsController = SettingsController();
  await settingsController.load();

  runApp(
    MainApp(
      sharedPreferences: sharedPreferences,
      themeController: themeController,
      settingsController: settingsController,
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
    required this.sharedPreferences,
    required this.themeController,
    required this.settingsController,
  });

  final SharedPreferences sharedPreferences;
  final ThemeController themeController;
  final SettingsController settingsController;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AuthCubit _authCubit;

  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
  }

  void _initializeDependencies() {
    // Initialize data sources
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final localDataSource = AuthLocalDataSourceImpl(widget.sharedPreferences);

    // Initialize repository
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    // Initialize use cases
    final loginUseCase = LoginUseCase(authRepository);
    final logoutUseCase = LogoutUseCase(authRepository);
    final getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);
    final resetPasswordUseCase = ResetPasswordUseCase(authRepository);

    // Initialize AuthCubit
    _authCubit = AuthCubit(
      loginUseCase: loginUseCase,
      logoutUseCase: logoutUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
      resetPasswordUseCase: resetPasswordUseCase,
    )..checkAuthStatus();

    // Initialize AppRouter with AuthCubit for redirects
    _appRouter = AppRouter(authCubit: _authCubit);
  }

  @override
  Widget build(BuildContext context) {
    // Initialize Teacher dependencies
    final teacherDataSource = TeacherLocalDataSourceImpl();
    final teacherRepository = TeacherRepositoryImpl(teacherDataSource);
    final getTeacherClassroomUseCase = GetTeacherClassroomUseCase(
      teacherRepository,
    );
    final getTeacherClassroomsUseCase = GetTeacherClassroomsUseCase(
      teacherRepository,
    );
    final studentsRepository = StudentsRepositoryImpl();
    final getStudentsUseCase = GetStudentsUseCase(studentsRepository);
    final markAttendanceUseCase = MarkAttendanceUseCase(studentsRepository);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: getTeacherClassroomUseCase),
        RepositoryProvider.value(value: getTeacherClassroomsUseCase),
        RepositoryProvider.value(value: getStudentsUseCase),
        RepositoryProvider.value(value: markAttendanceUseCase),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authCubit),
          BlocProvider(
            create: (context) => TeacherCubit(
              getTeacherClassroomUseCase: getTeacherClassroomUseCase,
            ),
          ),
          BlocProvider(
            create: (context) => ClassDetailsCubit(
              getStudentsUseCase: getStudentsUseCase,
              markAttendanceUseCase: markAttendanceUseCase,
            ),
          ),
        ],
        child: SettingsProvider(
          controller: widget.settingsController,
          child: ThemeProvider(
            controller: widget.themeController,
            child: Builder(
              builder: (context) {
                final themeController = ThemeProvider.of(context);
                final settingsController = SettingsProvider.of(context);
                return MaterialApp.router(
                  title: 'Msarat Wasel Services',
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: themeController.mode,
                  locale: settingsController.locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  debugShowCheckedModeBanner: false,
                  routerConfig: _appRouter.router,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
