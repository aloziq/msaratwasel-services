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
import 'package:msaratwasel_services/core/services/fcm_service.dart';
import 'package:msaratwasel_services/core/services/location_service.dart';

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

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

  // إخفاء أزرار التنقل الخاصة بنظام أندرويد (الرجوع / الرئيسية / المهام الأخيرة)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      'Flutter Error: ${details.exception}',
      stackTrace: details.stack,
    );
  };

  // Handle platform/asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('Unhandled Async Error: $error', stackTrace: stack);
    return true; // Prevent app from crashing
  };

  Bloc.observer = AppBlocObserver();

  try {
    await Firebase.initializeApp();

    // Initialize ThemeController
    final themeController = ThemeController();
    await themeController.load();

    // Initialize SettingsController
    final settingsController = SettingsController();
    await settingsController.load();

    await configureDependencies();

    // Initialize FCM
    await getIt<FcmService>().init();

    runApp(
      MainApp(
        themeController: themeController,
        settingsController: settingsController,
      ),
    );

    // Initialize Background Location Service asynchronously after UI starts
    // to prevent blocking the main thread and causing ANR.
    Future.delayed(const Duration(seconds: 1), () async {
      await LocationService.initialize();
      debugPrint('📡 [Main] Background Location Service Initialized (Delayed)');
    });
  } catch (e, stack) {
    developer.log('Initialization Error: $e', stackTrace: stack);
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
