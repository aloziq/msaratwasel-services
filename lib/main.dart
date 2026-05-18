import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:msaratwasel_services/core/services/fcm_service.dart';
import 'package:msaratwasel_services/core/services/location_service.dart';

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://8adfbcae8fb55fae2f47c92b23a9d4a8@o4507028168212480.ingest.us.sentry.io/4507038161747968';
      options.tracesSampleRate = 1.0;
      options.attachScreenshot = true;
      options.attachThreads = true;
    },
    appRunner: () async {
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        developer.log(
          'Flutter Error: ${details.exception}',
          stackTrace: details.stack,
        );
        // Send report to Firebase Crashlytics & Sentry
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        Sentry.captureException(details.exception, stackTrace: details.stack);
      };

      // Handle platform/asynchronous errors
      PlatformDispatcher.instance.onError = (error, stack) {
        developer.log('Unhandled Async Error: $error', stackTrace: stack);
        // Send report to Firebase Crashlytics & Sentry
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        Sentry.captureException(error, stackTrace: stack);
        return true; // Prevent app from crashing
      };

      Bloc.observer = AppBlocObserver();

      try {
        debugPrint('🚀 [Main] Initializing Firebase...');
        await Firebase.initializeApp();
        debugPrint('✅ [Main] Firebase Initialized');

        // Initialize Controllers without blocking main
        final themeController = ThemeController();
        final settingsController = SettingsController();

        debugPrint('🚀 [Main] Configuring Dependencies...');
        await configureDependencies();
        debugPrint('✅ [Main] Dependencies Configured');

        runApp(
          MainApp(
            themeController: themeController,
            settingsController: settingsController,
          ),
        );

        // ─── Post-startup Sequence ───
        // We use a progressive sequence to avoid overwhelming the CPU/Memory
        _runPostStartupTasks();
        
      } catch (e, stack) {
        developer.log('Initialization Error: $e', stackTrace: stack);
        debugPrint('❌ [Main] Critical Initialization Error: $e');
        Sentry.captureException(e, stackTrace: stack);
      }
    },
  );
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
