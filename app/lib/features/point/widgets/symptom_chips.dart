import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/theme/app_theme.dart';

/// Підпис симптому та його ідентифікатор.
typedef SymptomChipData = ({String id, String label});

/// Симптоми точки чипами. Спершу показує [collapsedCount], решту — за
/// дотиком до «Ще N».
class SymptomChips extends StatefulWidget {
  const SymptomChips({
    required this.symptoms,
    this.onSymptomTap,
    this.collapsedCount = 8,
    super.key,
  });

  final List<SymptomChipData> symptoms;
  final ValueChanged<String>? onSymptomTap;
  final int collapsedCount;

  @override
  State<SymptomChips> createState() => _SymptomChipsState();
}

class _SymptomChipsState extends State<SymptomChips> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.symptoms;
    // Немає сенсу ховати один-єдиний чип за «Ще 1».
    final collapsible = all.length > widget.collapsedCount + 1;
    final shown = _expanded || !collapsible
        ? all
        : all.sublist(0, widget.collapsedCount);
    final onTap = widget.onSymptomTap;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          for (final symptom in shown)
            if (onTap == null)
              Chip(label: Text(symptom.label))
            else
              ActionChip(
                label: Text(symptom.label),
                onPressed: () => onTap(symptom.id),
              ),
          if (collapsible && !_expanded)
            ActionChip(
              avatar: const Icon(Icons.expand_more, size: 18),
              label: Text(
                context.l10n.showMoreSymptoms(all.length - shown.length),
              ),
              onPressed: () => setState(() => _expanded = true),
            ),
        ],
      ),
    );
  }
}
