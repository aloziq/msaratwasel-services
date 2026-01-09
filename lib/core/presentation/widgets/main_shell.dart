import 'package:flutter/material.dart';
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

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundWidget(),
        Scaffold(
          key: scaffoldKey,
          backgroundColor: Colors.transparent,
          drawer: const AppDrawer(),
          body: widget.child,
        ),
      ],
    );
  }
}
