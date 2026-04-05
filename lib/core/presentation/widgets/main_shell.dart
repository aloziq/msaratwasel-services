import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'app_drawer.dart';
import 'background_widget.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static MainShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastPressedAt;

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. إغلاق القائمة الجانبية إذا كانت مفتوحة
        if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
          scaffoldKey.currentState?.closeDrawer();
          return;
        }

        // 2. إذا كان هنالك شاشة سابقة في الـ Stack يمكنا الرجوع لها بشكل طبيعي
        if (GoRouter.of(context).canPop()) {
          context.pop();
          return;
        }

        // 3. التحقق هل نحن في الصفحة الرئيسية الخاصة بدور المستخدم
        // Get the real URI of the app from GoRouter directly, not the shell state
        final String currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.path;
        
        final authState = context.read<AuthCubit>().state;
        final role = authState is AuthAuthenticated ? authState.user.role : UserRole.teacher;

        String homeRoute = AppRoutes.teacherHome;
        if (role == UserRole.busAssistant) homeRoute = AppRoutes.assistantHome;
        else if (role == UserRole.driver) homeRoute = AppRoutes.driverHome;
        else if (role == UserRole.fieldSupervisor) homeRoute = AppRoutes.supervisorHome;

        // إذا لم نكن في الرئيسية، ارجع إليها بدلاً من الخروج
        if (currentRoute != homeRoute && currentRoute != '/') {
          context.go(homeRoute);
          return;
        }

        // 4. التعامل مع الخروج مرتين متتاليتين من الصفحة الرئيسية
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('اضغط مرة أخرى للخروج من التطبيق', textAlign: TextAlign.center),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // الخروج من التطبيق نهائياً
        SystemNavigator.pop();
      },
      child: Stack(
        children: [
          const BackgroundWidget(),
          Scaffold(
            key: scaffoldKey,
            backgroundColor: Colors.transparent,
            drawer: const AppDrawer(),
            body: widget.child,
          ),
        ],
      ),
    );
  }
}
