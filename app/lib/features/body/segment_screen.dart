import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/favorite_toggle.dart';
import '../../core/widgets/filter_field.dart';
import '../../core/widgets/paper_image.dart';
import '../../core/widgets/point_list_tile.dart';
import '../../core/widgets/search_action.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/view_recorder.dart';
import '../../data/models/figure.dart';
import '../../data/models/point.dart';
import '../../data/providers.dart';
import '../../data/text_normalizer.dart';
import '../../data/user/user_models.dart';
import '../../data/user/user_providers.dart';
import '../shell/not_found_screen.dart';

enum PointOrder { book, code }

/// Точки одного сегмента: зведені схеми, фільтр, порядок, список.
class SegmentScreen extends ConsumerStatefulWidget {
  const SegmentScreen({required this.segmentId, super.key});

  final String segmentId;

  @override
  ConsumerState<SegmentScreen> createState() => _SegmentScreenState();
}

class _SegmentScreenState extends ConsumerState<SegmentScreen> {
  final TextEditingController _filter = TextEditingController();
  PointOrder _order = PointOrder.book;

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  List<Point> _visiblePoints(List<Point> points) {
    final query = _filter.text.trim();
    var result = points;
    if (query.isNotEmpty) {
      final asCode = TextNormalizer.code(query);
      final asText = TextNormalizer.text(query);
      result = [
        for (final point in points)
          if (TextNormalizer.code(point.code).startsWith(asCode) ||
              (asText.isNotEmpty &&
                  TextNormalizer.text(point.title).contains(asText)))
            point,
      ];
    }
    if (_order == PointOrder.code) {
      result = [...result]..sort((a, b) => comparePointCodes(a.code, b.code));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(repositoryProvider);
    final segment = repository.segment(widget.segmentId);
    if (segment == null) return const NotFoundScreen();

    final overview = repository.figuresByIds(segment.overviewFigureIds);
    final points = _visiblePoints(repository.pointsOfSegment(segment.id));
    final query = _filter.text.trim();
    final favorites = ref.watch(favoriteCodesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(segment.title),
        actions: const [SearchAction()],
      ),
      body: ViewRecorder(
        type: ViewType.segment,
        id: segment.id,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            if (overview.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionHeader(l10n.segmentSchemas)),
              SliverToBoxAdapter(
                child: _OverviewGallery(
                  figures: overview,
                  onFigureTap: (figure) =>
                      context.openSegmentImage(segment.id, figure.id),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.lg,
                  AppSpacing.screen,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilterField(
                      controller: _filter,
                      hintText: l10n.segmentFilterHint,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      label: l10n.orderLabel,
                      container: true,
                      child: SegmentedButton<PointOrder>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: PointOrder.book,
                            label: Text(l10n.orderBook),
                          ),
                          ButtonSegment(
                            value: PointOrder.code,
                            label: Text(l10n.orderCode),
                          ),
                        ],
                        selected: {_order},
                        onSelectionChanged: (selection) =>
                            setState(() => _order = selection.single),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (points.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off,
                  title: l10n.noMatchesTitle,
                  message: l10n.segmentNoMatchesMessage(query),
                  actionLabel: l10n.clearFilter,
                  onAction: () => setState(_filter.clear),
                ),
              )
            else
              SliverList.separated(
                itemCount: points.length,
                separatorBuilder: (context, index) =>
                    const Divider(indent: AppSpacing.screen),
                itemBuilder: (context, index) {
                  final point = points[index];
                  final figures = repository.figuresOfPoint(point);
                  return PointListTile(
                    point: point,
                    figure: figures.isEmpty ? null : figures.first,
                    isFavorite: favorites.contains(point.code),
                    onTap: () => context.openPoint(point.code),
                    onLongPress: () => toggleFavorite(context, ref, point.code),
                  );
                },
              ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }
}

/// Горизонтальна стрічка зведених схем сегмента.
class _OverviewGallery extends StatelessWidget {
  const _OverviewGallery({required this.figures, required this.onFigureTap});

  static const double height = 168;

  final List<Figure> figures;
  final ValueChanged<Figure> onFigureTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        itemCount: figures.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final figure = figures[index];
          // Ширина за пропорціями малюнка, але в розумних межах.
          final width = (height * figure.aspectRatio).clamp(96.0, 280.0);
          return SizedBox(
            width: width,
            child: Semantics(
              button: true,
              hint: context.l10n.openFullscreen,
              child: GestureDetector(
                onTap: () => onFigureTap(figure),
                child: PaperImage(figure, padding: const EdgeInsets.all(6)),
              ),
            ),
          );
        },
      ),
    );
  }
}
