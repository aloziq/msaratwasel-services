import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';

/// Navigation helper for Supervisor Drawer interactions
void handleSupervisorNavigation(
  BuildContext context,
  int targetIndex,
  int currentIndex, {
  bool closeDrawer = true,
}) {
  if (closeDrawer) {
    Navigator.pop(context); // Close Drawer
  }

  if (targetIndex == currentIndex) return;

  switch (targetIndex) {
    case 0:
      context.go(AppRoutes.supervisorHome);
      break;
    case 1:
      context.go('${AppRoutes.supervisorHome}/buses');
      break;
    case 2:
      context.go('${AppRoutes.supervisorHome}/drivers');
      break;
    case 4:
      context.go('${AppRoutes.supervisorHome}/alerts');
      break;
    case 5:
      context.go('${AppRoutes.supervisorHome}/inspection');
      break;
    case 6:
      context.go('${AppRoutes.supervisorHome}/delays');
      break;
    case 7:
      context.go('${AppRoutes.supervisorHome}/trips');
      break;
    case 8:
      context.go('${AppRoutes.supervisorHome}/reports');
      break;
    case 9:
      context.push(AppRoutes.settings);
      break;
    case 10: // Logout handled in drawer directly, but just in case
      break;
    default:
      context.go(AppRoutes.supervisorHome);
  }
}
