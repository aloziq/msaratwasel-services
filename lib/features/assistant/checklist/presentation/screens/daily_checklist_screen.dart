import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class DailyChecklistScreen extends StatefulWidget {
  const DailyChecklistScreen({super.key});

  @override
  State<DailyChecklistScreen> createState() => _DailyChecklistScreenState();
}

class _DailyChecklistScreenState extends State<DailyChecklistScreen> {
  Map<String, bool>? _itemStates;

  Map<String, bool> _getItems(AppLocalizations l10n) {
    final items = {
      l10n.checklistTask1: false,
      l10n.checklistTask2: false,
      l10n.checklistTask3: false,
      l10n.checklistTask4: false,
      l10n.checklistTask5: false,
    };
    if (_itemStates == null) {
      _itemStates = items;
    } else {
      // Preserve states but update keys if locale changed
      final newStates = <String, bool>{};
      final oldKeys = _itemStates!.keys.toList();
      final newKeys = items.keys.toList();
      for (int i = 0; i < newKeys.length; i++) {
        newStates[newKeys[i]] = _itemStates![oldKeys[i]] ?? false;
      }
      _itemStates = newStates;
    }
    return _itemStates!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final items = _getItems(l10n);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            leading: const BackButton(),
            largeTitle: Text(
              l10n.dailyChecklistTitle,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontFamily: theme.textTheme.titleLarge?.fontFamily,
              ),
            ),
            backgroundColor: Colors.transparent,
            border: null,
            stretch: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                items.keys.map((item) {
                  return CheckboxListTile(
                    title: Text(item),
                    value: items[item],
                    onChanged: (val) {
                      setState(() {
                        items[item] = val ?? false;
                      });
                    },
                  );
                }).toList(),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.tasksSavedSuccessfully)),
            );
            Navigator.pop(context);
          },
          child: Text(l10n.confirmAndSendReport),
        ),
      ),
    );
  }
}
