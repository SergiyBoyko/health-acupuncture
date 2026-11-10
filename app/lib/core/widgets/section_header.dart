import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Заголовок блоку з необов'язковою дією праворуч («Усі», «Очистити»).
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.xs,
    ),
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel і onAction задаються разом',
       );

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!))
            else
              const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
