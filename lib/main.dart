import 'package:flutter/material.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/routes/app_router.dart';
import 'config/settings/settings_controller.dart';
import 'config/theme/app_theme.dart';

import 'config/theme/theme_controller.dart';
import 'features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'features/teacher/students/presentation/cubit/class_details_cubit.dart';
import 'features/teacher/teacher/presentation/cubit/teacher_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ThemeController
  final themeController = ThemeController();
  await themeController.load();

  // Initialize SettingsController
  final settingsController = SettingsController();
  await settingsController.load();

  await configureDependencies();

  runApp(
    MainApp(
      themeController: themeController,
      settingsController: settingsController,
    ),
  );
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
