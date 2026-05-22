import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';

import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:msaratwasel_services/config/routes/app_router.dart';
import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/config/theme/app_theme.dart';
import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/class_details_cubit.dart';
import 'package:msaratwasel_services/features/teacher/teacher/presentation/cubit/teacher_cubit.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:msaratwasel_services/core/services/fcm_service.dart';

import 'dart:developer' as developer;

class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    developer.log(
      'Bloc Error in ${bloc.runtimeType}: $error',
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    developer.log('Bloc Change in ${bloc.runtimeType}: $change');
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide system UI (back/home/recents) after the app starts
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 1. Initialize Firebase first (Ensure notification services initialize AFTER Firebase)
  try {
    debugPrint('🚀 [Main] Initializing Firebase...');
    await Firebase.initializeApp();
    debugPrint('✅ [Main] Firebase Initialized');
  } catch (e, stack) {
    developer.log('Firebase Initialization Error: $e', stackTrace: stack);
    debugPrint('❌ [Main] Firebase Initialization Error: $e');
  }

  // 2. Set up global Flutter error logging
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      'Flutter Error: ${details.exception}',
      stackTrace: details.stack,
    );
  };

  // 3. Set up Platform Dispatcher async error handling (Async Zone Protection)
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('Unhandled Async Error: $error', stackTrace: stack);
    return true; // Prevent app from crashing
  };

  Bloc.observer = AppBlocObserver();

  // Initialize Controllers and dependencies
  late final ThemeController themeController;
  late final SettingsController settingsController;
  try {
    // Initialize Controllers without blocking main
    themeController = ThemeController();
    settingsController = SettingsController();

    debugPrint('🚀 [Main] Configuring Dependencies...');
    await configureDependencies();
    debugPrint('✅ [Main] Dependencies Configured');
  } catch (e, stack) {
    developer.log('Dependency Configuration Error: $e', stackTrace: stack);
    debugPrint('❌ [Main] Dependency Configuration Error: $e');
  }

  // Helper function to run the application
  void runApplication() {
    runApp(
      MainApp(
        themeController: themeController,
        settingsController: settingsController,
      ),
    );

    // ─── Post-startup Sequence ───
    _runPostStartupTasks();
  }

  // 4. Run the app
  debugPrint('🚀 [Main] Calling runApp...');
  runApplication();
}

void main() async {
  await bootstrap();
}

void _runPostStartupTasks() async {
  // Wait for the app to stabilize
  await Future.delayed(const Duration(seconds: 1));
  
  try {
    debugPrint('🚀 [Main] Step 1: Initializing FCM...');
    await getIt<FcmService>().init();
    debugPrint('✅ [Main] FCM Initialized');

    // Location Service will now be initialized ON DEMAND when a trip starts
    // to comply with Android 12+ Foreground Service restrictions.
  } catch (e) {
    debugPrint('❌ [Main] Post-startup Task Error: $e');
  }
}

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
    required this.themeController,
    required this.settingsController,
  });

  final ThemeController themeController;
  final SettingsController settingsController;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(authCubit: getIt<AuthCubit>());
    getIt<FcmService>().setRouter(_appRouter.router);

    // Load controllers in background without blocking the first frame
    widget.themeController.load();
    widget.settingsController.load();

    // Hide system UI (back/home/recents) after the app starts
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()..checkAuthStatus()),
        BlocProvider(create: (_) => getIt<TeacherCubit>()),
        BlocProvider(create: (_) => getIt<ClassDetailsCubit>()),
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
                key: ValueKey(settingsController.locale?.languageCode ?? 'system'),
                title: 'Msarat Wasel Services',
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
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
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(
                        settingsController.fontScale,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
