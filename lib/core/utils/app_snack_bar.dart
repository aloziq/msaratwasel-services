import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum AppSnackBarType { error, warning, success, info }

/// Unified Glassmorphic SnackBar / Toast System
class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    Color primaryColor;
    Color glowColor;
    IconData icon;

    switch (type) {
      case AppSnackBarType.error:
        primaryColor = const Color(0xFFEF4444);
        glowColor = const Color(0xFFDC2626);
        icon = PhosphorIconsFill.warningCircle;
        break;
      case AppSnackBarType.warning:
        primaryColor = const Color(0xFFF59E0B);
        glowColor = const Color(0xFFD97706);
        icon = PhosphorIconsFill.warning;
        break;
      case AppSnackBarType.success:
        primaryColor = const Color(0xFF10B981);
        glowColor = const Color(0xFF059669);
        icon = PhosphorIconsFill.checkCircle;
        break;
      case AppSnackBarType.info:
        primaryColor = const Color(0xFF3B82F6);
        glowColor = const Color(0xFF2563EB);
        icon = PhosphorIconsFill.info;
        break;
    }

    final screenHeight = MediaQuery.of(context).size.height;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(
          bottom: screenHeight * 0.40,
          left: 20,
          right: 20,
        ),
        content: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null && title.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void showError(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: AppSnackBarType.error);
  }

  static void showWarning(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: AppSnackBarType.warning);
  }

  static void showSuccess(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: AppSnackBarType.success);
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: AppSnackBarType.info);
  }
}
