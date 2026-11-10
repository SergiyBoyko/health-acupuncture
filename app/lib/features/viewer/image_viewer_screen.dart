import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_badge.dart';
import '../../data/models/figure.dart';
import '../../data/providers.dart';
import '../shell/not_found_screen.dart';
import 'zoomable_image.dart';

/// Перегляд малюнків на весь екран: масштабування, гортання, перехід до
/// точок, позначених на малюнку.
class ImageViewerScreen extends ConsumerStatefulWidget {
  /// Малюнки точки [code], відкрито на [figureId].
  const ImageViewerScreen.forPoint({
    required String code,
    required this.figureId,
    super.key,
  }) : pointCode = code,
       segmentId = null;

  /// Зведені схеми сегмента [segmentId], відкрито на [figureId].
  const ImageViewerScreen.forSegment({
    required String this.segmentId,
    required this.figureId,
    super.key,
  }) : pointCode = null;

  final String? pointCode;
  final String? segmentId;
  final String figureId;

  @override
  ConsumerState<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends ConsumerState<ImageViewerScreen> {
  PageController? _pages;
  int _index = 0;
  bool _zoomed = false;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  List<Figure>? _figures() {
    final repository = ref.read(repositoryProvider);
    if (widget.pointCode != null) {
      final point = repository.point(widget.pointCode!);
      return point == null ? null : repository.figuresOfPoint(point);
    }
    final segment = repository.segment(widget.segmentId!);
    return segment == null
        ? null
        : repository.figuresByIds(segment.overviewFigureIds);
  }

  void _openPoint(String code) {
    final router = GoRouter.of(context);
    final tab = context.currentTab;
    router.pop();
    // Точка, з якої відкрили перегляд, уже на екрані під ним.
    if (code == widget.pointCode) return;
    router.push(tab.child('point/${PointCodeUrl.encode(code)}'));
  }

  @override
  Widget build(BuildContext context) {
    final figures = _figures();
    final initial = figures?.indexWhere((f) => f.id == widget.figureId) ?? -1;
    if (figures == null || initial < 0) return const NotFoundScreen();

    if (_pages == null) {
      _index = initial;
      _pages = PageController(initialPage: initial);
    }

    final l10n = context.l10n;
    final figure = figures[_index];
    const foreground = Colors.white;

    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: foreground,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: l10n.close,
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          title: figures.length > 1
              ? Text(l10n.figureCounter(_index + 1, figures.length))
              : null,
          centerTitle: true,
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  // Поки малюнок збільшено, рух пальця пересуває його.
                  physics: _zoomed
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  itemCount: figures.length,
                  onPageChanged: (index) => setState(() {
                    _index = index;
                    _zoomed = false;
                  }),
                  itemBuilder: (context, index) => ZoomableImage(
                    key: ValueKey(figures[index].id),
                    figure: figures[index],
                    onZoomChanged: (zoomed) => setState(() => _zoomed = zoomed),
                  ),
                ),
              ),
              _FigureInfo(figure: figure, onPointTap: _openPoint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Підпис малюнка і точки, позначені на ньому.
class _FigureInfo extends StatelessWidget {
  const _FigureInfo({required this.figure, required this.onPointTap});

  final Figure figure;
  final ValueChanged<String> onPointTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = Colors.white.withValues(alpha: 0.7);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.38;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              figure.caption,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.sourcePage(figure.sourcePage),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            if (figure.pointCodes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.pointsOnFigure,
                style: theme.textTheme.labelMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final code in figure.pointCodes)
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
          ],
        ),
      ),
    );
  }
}
