import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/paper_image.dart';
import '../../core/widgets/section_header.dart';
import '../../data/content_repository.dart';
import '../../data/models/figure.dart';
import '../../data/providers.dart';
import '../../data/user/user_models.dart';
import '../../data/user/user_providers.dart';
import 'recent_strip.dart';

/// Головна: пошук, останні запити, нещодавно відкрите, частини тіла.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Скільки останніх запитів і переглядів показувати.
  static const int maxSearches = 5;
  static const int maxRecent = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repository = ref.watch(repositoryProvider);
    final searches = ref
        .watch(searchHistoryProvider)
        .take(maxSearches)
        .toList();
    final recent = _recentItems(
      context,
      repository,
      ref.watch(viewHistoryProvider),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.sm,
            ),
            child: _SearchField(),
          ),
          // Порожні блоки історії не показуються взагалі.
          if (searches.isNotEmpty) ...[
            SectionHeader(
              l10n.recentSearches,
              actionLabel: l10n.clear,
              onAction: () => _clearSearches(context, ref),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final entry in searches)
                    ActionChip(
                      avatar: const Icon(Icons.history, size: 18),
                      label: Text(entry.query),
                      onPressed: () => context.openSearch(query: entry.query),
                    ),
                ],
              ),
            ),
          ],
          if (recent.isNotEmpty) ...[
            SectionHeader(
              l10n.recentViews,
              actionLabel: l10n.showAll,
              onAction: () => context.go('${AppTab.saved.root}?tab=history'),
            ),
            RecentStrip(items: recent),
          ],
          SectionHeader(l10n.bodyTitle),
          _SegmentGrid(repository: repository),
        ],
      ),
    );
  }

  static Future<void> _clearSearches(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final confirmed = await confirmAction(
      context,
      title: l10n.clearSearchesTitle,
      message: l10n.clearSearchesMessage,
    );
    if (confirmed) ref.read(searchHistoryProvider.notifier).clear();
  }

  /// Останні перегляди як картки; записи без вмісту пропускаються.
  static List<RecentItem> _recentItems(
    BuildContext context,
    ContentRepository repository,
    List<ViewEntry> views,
  ) {
    final items = <RecentItem>[];
    for (final entry in views) {
      if (items.length == maxRecent) break;
      switch (entry.type) {
        case ViewType.point:
          final point = repository.point(entry.id);
          if (point == null) continue;
          final figures = repository.figuresOfPoint(point);
          items.add(
            RecentItem(
              title: point.title,
              code: point.code,
              figure: figures.isEmpty ? null : figures.first,
              icon: Icons.place_outlined,
              onTap: () => context.openPoint(point.code),
            ),
          );
        case ViewType.segment:
          final segment = repository.segment(entry.id);
          if (segment == null) continue;
          items.add(
            RecentItem(
              title: segment.title,
              figure: repository.coverFigure(segment),
              icon: Icons.accessibility_new_outlined,
              onTap: () => context.openSegment(segment.id),
            ),
          );
        case ViewType.symptom:
          final symptom = repository.symptom(entry.id);
          if (symptom == null) continue;
          items.add(
            RecentItem(
              title: symptom.term,
              icon: Icons.manage_search_outlined,
              onTap: () => context.openSymptom(symptom.id),
            ),
          );
        case ViewType.term:
          if (!repository.glossary.any((t) => t.term == entry.id)) continue;
          items.add(
            RecentItem(
              title: entry.id,
              icon: Icons.menu_book_outlined,
              onTap: () => context.openGlossary(term: entry.id),
            ),
          );
      }
    }
    return items;
  }
}

/// Поле-кнопка: дотик відкриває екран пошуку з клавіатурою.
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: l10n.search,
      hint: l10n.searchHint,
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.search),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.openSearch(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.searchHint,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Сітка у дві колонки: п'ять частин тіла і вхід у словник.
class _SegmentGrid extends StatelessWidget {
  const _SegmentGrid({required this.repository});

  final ContentRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cells = <Widget>[
      for (final segment in repository.segments)
        _GridCard(
          title: segment.title,
          subtitle: l10n.pointsCount(segment.pointCodes.length),
          figure: repository.coverFigure(segment),
          onTap: () => context.openSegment(segment.id),
        ),
      _GridCard(
        title: l10n.glossary,
        subtitle: l10n.termsCount(repository.glossary.length),
        icon: Icons.menu_book_outlined,
        onTap: () => context.openGlossary(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        children: [
          for (var i = 0; i < cells.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              // Рядок, а не GridView: висота картки підлаштовується під
              // текст при великому системному шрифті.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cells[i]),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: i + 1 < cells.length
                          ? cells[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.figure,
    this.icon,
  });

  static const double imageHeight = 72;

  final String title;
  final String subtitle;
  final Figure? figure;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: imageHeight,
              child: ExcludeSemantics(
                child: figure != null
                    ? PaperImage(
                        figure!,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                        cacheWidth: 400,
                      )
                    : ColoredBox(
                        color: scheme.secondaryContainer,
                        child: Icon(icon, color: scheme.onSecondaryContainer),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
