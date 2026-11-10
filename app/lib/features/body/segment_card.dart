import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/paper_image.dart';
import '../../data/models/figure.dart';
import '../../data/models/segment.dart';

/// Картка частини тіла: ілюстрація, назва, кількість точок.
class SegmentCard extends StatelessWidget {
  const SegmentCard({
    required this.segment,
    required this.onTap,
    this.cover,
    super.key,
  });

  static const double imageSize = 88;

  final Segment segment;
  final Figure? cover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (cover != null) ...[
                SizedBox.square(
                  dimension: imageSize,
                  child: ExcludeSemantics(
                    child: PaperImage(
                      cover!,
                      fit: BoxFit.cover,
                      borderRadius: AppRadius.chip,
                      cacheWidth: (imageSize * pixelRatio).round(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(segment.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${l10n.pointsCount(segment.pointCodes.length)} · '
                      '${l10n.sourcePages(segment.sourcePages)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ExcludeSemantics(
                child: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
