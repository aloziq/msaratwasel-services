import 'package:flutter/material.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import 'adaptive_sliver_app_bar.dart';

class AppSliverHeader extends StatelessWidget {
  const AppSliverHeader({
    super.key,
    required this.title,
    this.hasLeading = false,
    this.showMenu = false,
    this.leading,
    this.trailing,
  });

  final String title;
  final bool hasLeading;
  final bool showMenu;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AdaptiveSliverAppBar(
      title: title,
      leading:
          leading ??
          (showMenu
              ? Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                )
              : (hasLeading
                    ? Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark ? Colors.white : AppColors.primary,
                            size: 22,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      )
                    : null)),
      trailing: trailing,
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
      stretch: true,
    );
  }
}
