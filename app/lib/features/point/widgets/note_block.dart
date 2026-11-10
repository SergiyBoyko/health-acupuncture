import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Блок приміток із заголовком та іконкою: рукописні нотатки (на
/// бурштиновій підкладці) або примітки транскрипції (на нейтральній).
class NoteBlock extends StatelessWidget {
  const NoteBlock({
    required this.icon,
    required this.title,
    required this.notes,
    required this.background,
    required this.foreground,
    super.key,
  });

  final IconData icon;
  final String title;
  final List<String> notes;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: Icon(icon, size: 18, color: foreground)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                note,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ),
        ],
      ),
    );
  }
}
