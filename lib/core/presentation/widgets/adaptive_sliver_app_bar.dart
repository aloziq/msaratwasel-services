import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Unified sliver app bar that always uses [CupertinoSliverNavigationBar]
/// across all platforms for a consistent large-title header experience.
class AdaptiveSliverAppBar extends StatelessWidget {
  const AdaptiveSliverAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.stretch = true,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CupertinoSliverNavigationBar(
      largeTitle: Text(
        title,
        style: TextStyle(
          color:
              theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
          fontFamily: theme.textTheme.titleLarge?.fontFamily,
        ),
      ),
      leading: leading,
      trailing: trailing,
      backgroundColor: backgroundColor ?? Colors.transparent,
      border: null,
      stretch: stretch,
    );
  }
}
