import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import 'symptom_index.dart';

/// Рядок покажчика: назва, кількість точок (або підтем), перехід.
class SymptomEntryTile extends StatelessWidget {
  const SymptomEntryTile(this.entry, {super.key});

  final SymptomEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final symptom = entry.symptom;
    final count = entry.isGroup
        ? l10n.subtermsCount(entry.subtermCount)
        : l10n.pointsCount(symptom!.pointCodes.length);

    return ListTile(
      minTileHeight: 56,
      leading: symptom != null && symptom.handwritten
          ? Icon(
              Icons.edit_note,
              color: theme.colorScheme.onSurfaceVariant,
              semanticLabel: l10n.handwrittenEntry,
            )
          : null,
      title: Text(entry.title),
      subtitle: Text(count),
      trailing: Icon(
        entry.isGroup ? Icons.folder_open : Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => entry.isGroup
          ? context.openSymptomGroup(entry.group!.id)
          : context.openSymptom(symptom!.id),
    );
  }
}
