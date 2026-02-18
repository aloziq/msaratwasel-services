import 'package:flutter/material.dart';

import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';

class CustomMenuButton extends StatelessWidget {
  final Color? color;

  const CustomMenuButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.menu_rounded,
        size: 28,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () {
        final mainShell = MainShell.of(context);
        if (mainShell != null) {
          mainShell.openDrawer();
        } else {
          Scaffold.of(context).openDrawer();
        }
      },
    );
  }
}
