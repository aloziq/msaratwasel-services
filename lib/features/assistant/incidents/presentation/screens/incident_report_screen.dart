import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

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
          CupertinoSliverNavigationBar(
            leading: const BackButton(),
            largeTitle: Text(
              l10n.incidentReportTitle,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontFamily: theme.textTheme.titleLarge?.fontFamily,
              ),
            ),
            backgroundColor: Colors.transparent,
            border: null,
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
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: l10n.reportDetailsPlaceholder,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(PhosphorIconsRegular.camera),
                    label: Text(l10n.attachPhotoOptional),
                    onPressed: () {}, // Mock image picker
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
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
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.reportSentSuccessfully)),
            );
            Navigator.pop(context);
          },
          child: Text(l10n.sendUrgentReport),
        ),
      ),
    );
  }
}
