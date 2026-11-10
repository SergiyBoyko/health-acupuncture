import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_badge.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/favorite_toggle.dart';
import '../../core/widgets/point_list_tile.dart';
import '../../core/widgets/search_action.dart';
import '../../core/widgets/section_header.dart';
import '../../data/content_repository.dart';
import '../../data/providers.dart';
import '../../data/user/user_models.dart';
import '../../data/user/user_providers.dart';

enum SavedTab { favorites, history }

/// Вкладка «Збережене»: обрані точки та історія переглядів.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({this.initialTab = SavedTab.favorites, super.key});

  final SavedTab initialTab;

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  late SavedTab _tab = widget.initialTab;

  Future<void> _confirmClearHistory() async {
    final l10n = context.l10n;
    final confirmed = await confirmAction(
      context,
      title: l10n.clearHistoryTitle,
      message: l10n.clearHistoryMessage,
    );
    if (confirmed) ref.read(viewHistoryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(repositoryProvider);
    final hasHistory = ref.watch(viewHistoryProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabSaved),
        actions: [
          if (_tab == SavedTab.history && hasHistory)
            IconButton(
              tooltip: l10n.clearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmClearHistory,
            ),
          const SearchAction(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.sm,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<SavedTab>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: SavedTab.favorites,
                    label: Text(l10n.favorites),
                  ),
                  ButtonSegment(
                    value: SavedTab.history,
                    label: Text(l10n.history),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (selection) =>
                    setState(() => _tab = selection.single),
              ),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              SavedTab.favorites => _FavoritesList(repository: repository),
              SavedTab.history => _HistoryList(repository: repository),
            },
          ),
        ],
      ),
    );
  }
}

class _FavoritesList extends ConsumerWidget {
  const _FavoritesList({required this.repository});

  final ContentRepository repository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Новіші зверху; коди, яких уже немає у вмісті, пропускаємо.
    final points = [
      for (final entry in ref.watch(favoritesProvider))
        ?repository.point(entry.code),
    ];
    if (points.isEmpty) {
      return EmptyState(
        icon: Icons.star_outline,
        title: l10n.favoritesEmptyTitle,
        message: l10n.favoritesEmptyMessage,
        actionLabel: l10n.openBody,
        onAction: () => context.go(AppTab.body.root),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: points.length,
      separatorBuilder: (context, index) =>
          const Divider(indent: AppSpacing.screen),
      itemBuilder: (context, index) {
        final point = points[index];
        final figures = repository.figuresOfPoint(point);
        return PointListTile(
          point: point,
          figure: figures.isEmpty ? null : figures.first,
          trailing: FavoriteButton(code: point.code),
          onTap: () => context.openPoint(point.code),
        );
      },
    );
  }
}

/// Запис історії, готовий до показу.
typedef _HistoryItem = ({
  ViewEntry entry,
  String title,
  String? subtitle,
  String? code,
});

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.repository});

  final ContentRepository repository;

  /// Перетворює запис на рядок; `null`, якщо вмісту вже немає.
  _HistoryItem? _resolve(AppLocalizations l10n, ViewEntry entry) {
    switch (entry.type) {
      case ViewType.point:
        final point = repository.point(entry.id);
        if (point == null) return null;
        return (
          entry: entry,
          title: point.title,
          subtitle: repository.segment(point.segmentId)?.title,
          code: point.code,
        );
      case ViewType.segment:
        final segment = repository.segment(entry.id);
        if (segment == null) return null;
        return (
          entry: entry,
          title: segment.title,
          subtitle: l10n.historyTypeSegment,
          code: null,
        );
      case ViewType.symptom:
        final symptom = repository.symptom(entry.id);
        if (symptom == null) return null;
        final group = symptom.groupId == null
            ? null
            : repository.symptomGroup(symptom.groupId!)?.title;
        return (
          entry: entry,
          title: group == null ? symptom.term : '$group: ${symptom.term}',
          subtitle: l10n.historyTypeSymptom,
          code: null,
        );
      case ViewType.term:
        if (!repository.glossary.any((t) => t.term == entry.id)) return null;
        return (
          entry: entry,
          title: entry.id,
          subtitle: l10n.historyTypeTerm,
          code: null,
        );
    }
  }

  static void _open(BuildContext context, ViewEntry entry) {
    switch (entry.type) {
      case ViewType.point:
        context.openPoint(entry.id);
      case ViewType.segment:
        context.openSegment(entry.id);
      case ViewType.symptom:
        context.openSymptom(entry.id);
      case ViewType.term:
        context.openGlossary(term: entry.id);
    }
  }

  static IconData _icon(ViewType type) => switch (type) {
    ViewType.point => Icons.place_outlined,
    ViewType.segment => Icons.accessibility_new_outlined,
    ViewType.symptom => Icons.manage_search_outlined,
    ViewType.term => Icons.menu_book_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final items = [
      for (final entry in ref.watch(viewHistoryProvider))
        ?_resolve(l10n, entry),
    ];
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.history,
        title: l10n.historyEmptyTitle,
        message: l10n.historyEmptyMessage,
      );
    }

    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final time = DateFormat.Hm('uk');
    final date = DateFormat.MMMd('uk');

    String dayOf(DateTime at) {
      final day = DateTime(at.year, at.month, at.day);
      if (!day.isBefore(today)) return l10n.today;
      if (!day.isBefore(yesterday)) return l10n.yesterday;
      return l10n.earlier;
    }

    final children = <Widget>[];
    String? currentDay;
    for (final item in items) {
      final at = item.entry.at;
      final day = dayOf(at);
      if (day != currentDay) {
        currentDay = day;
        children.add(SectionHeader(day));
      }
      final when = day == l10n.earlier ? date.format(at) : time.format(at);
      children.add(
        ListTile(
          minTileHeight: 56,
          leading: item.code != null
              ? CodeBadge(item.code!)
              : SizedBox(
                  width: 44,
                  child: Icon(
                    _icon(item.entry.type),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
          title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text([item.subtitle, when].nonNulls.join(' · ')),
          onTap: () => _open(context, item.entry),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: children,
    );
  }
}
