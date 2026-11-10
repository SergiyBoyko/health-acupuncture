import 'package:flutter/material.dart';

import '../../data/models/figure.dart';
import '../../data/models/point.dart';
import '../l10n.dart';
import '../theme/app_theme.dart';
import 'code_badge.dart';
import 'paper_image.dart';
import 'somatic_tag.dart';

/// Рядок точки в списках: мініатюра, код, заголовок, позначки.
class PointListTile extends StatelessWidget {
  const PointListTile({
    required this.point,
    this.figure,
    this.subtitle,
    this.isFavorite = false,
    this.trailing,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  static const double thumbnailSize = 56;

  final Point point;

  /// Мініатюра; без неї рядок показує лише код і текст.
  final Figure? figure;

  /// Додатковий рядок під заголовком (сторона тіла, фрагмент пошуку).
  final String? subtitle;
  final bool isFavorite;

  /// Дія праворуч (наприклад, кнопка «прибрати з обраного»).
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screen,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (figure != null) ...[
                SizedBox.square(
                  dimension: thumbnailSize,
                  child: ExcludeSemantics(
                    child: PaperImage(
                      figure!,
                      fit: BoxFit.cover,
                      borderRadius: AppRadius.chip,
                      cacheWidth: (thumbnailSize * pixelRatio).round(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              CodeBadge(point.code),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      point.title,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (point.somatic)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xs),
                        child: SomaticTag(),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (isFavorite) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.star,
                  size: 20,
                  color: scheme.primary,
                  semanticLabel: l10n.inFavorites,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
