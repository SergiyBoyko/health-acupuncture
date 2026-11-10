import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_badge.dart';
import '../../data/content_repository.dart';

/// Легенда позначень покажчика і список соматичних точок.
Future<void> showLegendSheet(
  BuildContext context, {
  required ContentRepository repository,
  required ValueChanged<String> onPointTap,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        child: _LegendContent(
          repository: repository,
          onPointTap: (code) {
            Navigator.of(sheetContext).pop();
            onPointTap(code);
          },
        ),
      ),
    ),
  ),
);

class _LegendContent extends StatelessWidget {
  const _LegendContent({required this.repository, required this.onPointTap});

  final ContentRepository repository;
  final ValueChanged<String> onPointTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.legendTitle, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final entry in repository.meta.legend)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    entry.code,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(entry.meaning, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.legendSuffixes, style: muted),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(l10n.somaticPoints, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.somaticPointsMessage, style: muted),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final code in repository.meta.somaticCodes)
              InkWell(
                onTap: () => onPointTap(code),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Center(widthFactor: 1, child: CodeBadge(code)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
