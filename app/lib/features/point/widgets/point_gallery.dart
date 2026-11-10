import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paper_image.dart';
import '../../../data/models/figure.dart';

/// Гортальна галерея малюнків точки з підписом і лічильником.
class PointGallery extends StatefulWidget {
  const PointGallery({required this.figures, this.onFigureTap, super.key});

  static const double imageHeight = 260;

  final List<Figure> figures;

  /// Дотик до малюнка (повноекранний перегляд).
  final ValueChanged<int>? onFigureTap;

  @override
  State<PointGallery> createState() => _PointGalleryState();
}

class _PointGalleryState extends State<PointGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final figures = widget.figures;
    final current = figures[_index.clamp(0, figures.length - 1)];
    final kind = current.kind == FigureKind.overview
        ? l10n.figureOverview
        : l10n.figureDetail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: PointGallery.imageHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: figures.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Semantics(
                // Назва малюнка — на самій кнопці, щоб екранний читач
                // озвучував, що саме відкриється.
                image: true,
                label: figures[index].caption,
                button: widget.onFigureTap != null,
                hint: widget.onFigureTap == null ? null : l10n.openFullscreen,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: widget.onFigureTap == null
                      ? null
                      : () => widget.onFigureTap!(index),
                  child: PaperImage(
                    figures[index],
                    padding: const EdgeInsets.all(AppSpacing.sm),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${current.caption} · $kind, '
                  '${l10n.sourcePage(current.sourcePage)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (figures.length > 1) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  l10n.figureCounter(_index + 1, figures.length),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
