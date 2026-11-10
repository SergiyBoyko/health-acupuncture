import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme/app_theme.dart';

/// Позначка соматичної точки (діє на весь організм).
class SomaticTag extends StatelessWidget {
  const SomaticTag({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip / 2),
      ),
      child: Text(
        context.l10n.somatic,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}
