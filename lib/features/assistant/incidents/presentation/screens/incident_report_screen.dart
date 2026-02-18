import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/hold_to_confirm_button.dart';
import '../../../../../core/presentation/widgets/adaptive_sliver_app_bar.dart';
import '../../../../../core/presentation/widgets/premium_text_field.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  String? _selectedTypeKey;
  final TextEditingController _descriptionController = TextEditingController();

  Map<String, String> _getTypes(AppLocalizations l10n) {
    return {
      'behavioral': l10n.incidentTypeBehavioral,
      'health': l10n.incidentTypeHealth,
      'technical': l10n.incidentTypeTechnical,
      'traffic': l10n.incidentTypeTraffic,
      'other': l10n.incidentTypeOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final typesMap = _getTypes(l10n);
    _selectedTypeKey ??= 'behavioral';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          AdaptiveSliverAppBar(
            title: l10n.incidentReportTitle,
            leading: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => MainShell.of(context)?.openDrawer(),
              ),
            ),
            backgroundColor: Colors.transparent,
            stretch: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.incidentType, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: typesMap.entries.map((entry) {
                      final isSelected = _selectedTypeKey == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedTypeKey = entry.key);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.problemDescription,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  PremiumTextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    label: l10n.reportDetailsPlaceholder,
                    keyboardType: TextInputType.multiline,
                    alignLabelWithHint: true,
                    icon: PhosphorIconsRegular.pencilSimple,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(PhosphorIconsRegular.camera),
                    label: Text(l10n.attachPhotoOptional),
                    onPressed: () {}, // Mock image picker
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      foregroundColor: theme.brightness == Brightness.dark
                          ? Colors.white
                          : theme.colorScheme.primary,
                      side: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.2)
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: HoldToConfirmButton(
          label: l10n.sendUrgentReport,
          color: Colors.red,
          icon: PhosphorIconsFill.warningCircle,
          onConfirmed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.reportSentSuccessfully)),
            );
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
