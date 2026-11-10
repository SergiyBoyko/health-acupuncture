import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme/app_theme.dart';

enum CodeBadgeSize { regular, large }

/// Код точки. Єдиний вигляд на весь застосунок, щоб око вчилось його шукати.
///
/// [enabled] = false — код із покажчика, для якого немає описаної точки.
class CodeBadge extends StatelessWidget {
  const CodeBadge(
    this.code, {
    this.enabled = true,
    this.size = CodeBadgeSize.regular,
    super.key,
  });

  final String code;
  final bool enabled;
  final CodeBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final large = size == CodeBadgeSize.large;
    final style =
        (large ? theme.textTheme.titleLarge : theme.textTheme.labelLarge)
            ?.copyWith(
              color: enabled
                  ? scheme.onSecondaryContainer
                  : scheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            );

    return Semantics(
      label: enabled
          ? context.l10n.pointSemantics(code)
          : context.l10n.unknownPointSemantics(code),
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minWidth: large ? 56 : 44),
        padding: EdgeInsets.symmetric(
          horizontal: large ? AppSpacing.md : AppSpacing.sm,
          vertical: large ? 6 : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          code,
          style: style,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}
