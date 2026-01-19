import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppSliverHeader extends StatelessWidget {
  const AppSliverHeader({
    super.key,
    required this.title,
    this.hasLeading = false,
    this.leading,
    this.trailing,
  });

  final String title;
  final bool hasLeading;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CupertinoSliverNavigationBar(
      largeTitle: Platform.isAndroid
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                title,
                style: TextStyle(
                  height: 1.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            )
          : Text(title, style: TextStyle(color: theme.colorScheme.onSurface)),
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
      border: null,
      stretch: true,
      leading:
          leading ??
          (hasLeading
              ? Material(
                  color: Colors.transparent,
                  child: BackButton(color: theme.colorScheme.primary),
                )
              : null),
      trailing: trailing,
    );
  }
}
