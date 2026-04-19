import 'package:flutter/widgets.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

extension UserRoleX on UserRole {
  String getDisplayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case UserRole.driver:
        return l10n.roleDriver;
      case UserRole.assistant:
        return l10n.roleBusAssistant;
      case UserRole.fieldSupervisor:
        return l10n.roleFieldSupervisor;
      case UserRole.teacher:
        return l10n.roleTeacher;
    }
  }
}
