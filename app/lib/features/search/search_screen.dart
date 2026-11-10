import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_badge.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/highlighted_text.dart';
import '../../core/widgets/section_header.dart';
import '../../data/providers.dart';
import '../../data/search_index.dart';
import '../../data/user/user_models.dart';
import '../../data/user/user_providers.dart';

/// Пошук по всьому довіднику. Результати з'являються під час введення,
/// згруповані: точки, симптоми, словник.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.initialQuery = '', super.key});

  /// Затримка після останнього символу перед пошуком.
  static const Duration debounce = Duration(milliseconds: 80);

  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );
  Timer? _debounce;
  String _query = '';
  SearchResults _results = SearchResults.empty;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) {
      _query = widget.initialQuery.trim();
      _results = ref.read(searchIndexProvider).search(_query);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {}); // оновити кнопку очищення одразу
    _debounce = Timer(SearchScreen.debounce, () => _run(value));
  }

  void _run(String value) {
    final query = value.trim();
    if (!mounted || query == _query) return;
    setState(() {
      _query = query;
      _results = query.isEmpty
          ? SearchResults.empty
          : ref.read(searchIndexProvider).search(query);
    });
  }

  /// Зберігає поточний запит в історії: коли його підтвердили або коли
  /// відкрили результат.
  void _remember() {
    if (_query.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(_query);
    }
  }

  /// Повторює запит з історії.
  void _useRecent(String query) {
    _debounce?.cancel();
    _controller
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    _run(query);
    _remember();
  }

  Future<void> _confirmClearRecent() async {
    final l10n = context.l10n;
    final confirmed = await confirmAction(
      context,
      title: l10n.clearSearchesTitle,
      message: l10n.clearSearchesMessage,
    );
    if (confirmed) ref.read(searchHistoryProvider.notifier).clear();
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _query = '';
      _results = SearchResults.empty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          onSubmitted: (value) {
            _run(value);
            _remember();
          },
          textInputAction: TextInputAction.search,
          style: theme.textTheme.titleMedium,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: l10n.clearSearch,
              icon: const Icon(Icons.close),
              onPressed: _clear,
            ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    if (_query.isEmpty) {
      final recent = ref.watch(searchHistoryProvider);
      if (recent.isEmpty) {
        return EmptyState(
          icon: Icons.search,
          title: l10n.searchPromptTitle,
          message: l10n.searchPromptMessage,
        );
      }
      return _RecentSearches(
        entries: recent,
        onSelect: _useRecent,
        onRemove: (query) =>
            ref.read(searchHistoryProvider.notifier).remove(query),
        onClear: _confirmClearRecent,
      );
    }
    if (_results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.noMatchesTitle,
        message: l10n.searchNoResultsMessage(_query),
        actionLabel: l10n.openSymptoms,
        onAction: () => context.go(AppTab.symptoms.root),
      );
    }

    final results = _results;
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        if (results.points.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(l10n.resultsPoints(results.points.length)),
          ),
          SliverList.builder(
            itemCount: results.points.length,
            itemBuilder: (context, index) => _PointResult(
              hit: results.points[index],
              tokens: results.tokens,
              onOpen: _remember,
            ),
          ),
        ],
        if (results.symptoms.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(l10n.resultsSymptoms(results.symptoms.length)),
          ),
          SliverList.builder(
            itemCount: results.symptoms.length,
            itemBuilder: (context, index) => _SymptomResult(
              hit: results.symptoms[index],
              tokens: results.tokens,
              onOpen: _remember,
            ),
          ),
        ],
        if (results.glossary.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(l10n.resultsGlossary(results.glossary.length)),
          ),
          SliverList.builder(
            itemCount: results.glossary.length,
            itemBuilder: (context, index) => _GlossaryResult(
              hit: results.glossary[index],
              tokens: results.tokens,
              onOpen: () {
                _remember();
                ref
                    .read(viewHistoryProvider.notifier)
                    .add(ViewType.term, results.glossary[index].term.term);
              },
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
      ],
    );
  }
}

class _PointResult extends ConsumerWidget {
  const _PointResult({
    required this.hit,
    required this.tokens,
    required this.onOpen,
  });

  final PointHit hit;
  final List<String> tokens;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final point = hit.point;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final segment = ref.watch(repositoryProvider).segment(point.segmentId);
    final snippet = hit.snippet;

    return InkWell(
      onTap: () {
        onOpen();
        context.openPoint(point.code);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screen,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: CodeBadge(point.code),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightedText(
                      point.title,
                      ranges: highlightRanges(point.title, tokens),
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.3),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    if (snippet != null)
                      HighlightedText(
                        snippet,
                        ranges: highlightRanges(snippet, tokens),
                        style: muted,
                        maxLines: 3,
                      )
                    else
                      Text(
                        '${segment?.title ?? ''} · '
                        '${l10n.sourcePage(point.sourcePage)}',
                        style: muted,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymptomResult extends StatelessWidget {
  const _SymptomResult({
    required this.hit,
    required this.tokens,
    required this.onOpen,
  });

  final SymptomHit hit;
  final List<String> tokens;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      minTileHeight: 56,
      leading: hit.symptom.handwritten
          ? Icon(
              Icons.edit_note,
              color: theme.colorScheme.onSurfaceVariant,
              semanticLabel: context.l10n.handwrittenEntry,
            )
          : null,
      title: HighlightedText(
        hit.title,
        ranges: highlightRanges(hit.title, tokens),
      ),
      subtitle: Text(context.l10n.pointsCount(hit.symptom.pointCodes.length)),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        onOpen();
        context.openSymptom(hit.symptom.id);
      },
    );
  }
}

class _GlossaryResult extends StatelessWidget {
  const _GlossaryResult({
    required this.hit,
    required this.tokens,
    required this.onOpen,
  });

  final GlossaryHit hit;
  final List<String> tokens;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final term = hit.term;
    return ExpansionTile(
      key: PageStorageKey('glossary-${term.term}'),
      onExpansionChanged: (expanded) {
        if (expanded) onOpen();
      },
      title: HighlightedText(
        term.term,
        ranges: highlightRanges(term.term, tokens),
      ),
      subtitle: HighlightedText(
        term.definition,
        ranges: highlightRanges(term.definition, tokens),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
      ),
      shape: const Border(),
      collapsedShape: const Border(),
      expandedAlignment: Alignment.centerLeft,
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      children: [
        HighlightedText(
          term.definition,
          ranges: highlightRanges(term.definition, tokens),
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

/// Останні запити під порожнім полем пошуку.
class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.entries,
    required this.onSelect,
    required this.onRemove,
    required this.onClear,
  });

  final List<SearchEntry> entries;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        SectionHeader(
          l10n.recentSearches,
          actionLabel: l10n.clear,
          onAction: onClear,
        ),
        for (final entry in entries)
          ListTile(
            minTileHeight: 56,
            leading: Icon(Icons.history, color: muted),
            title: Text(entry.query),
            trailing: IconButton(
              tooltip: l10n.removeSearch(entry.query),
              icon: const Icon(Icons.close),
              onPressed: () => onRemove(entry.query),
            ),
            onTap: () => onSelect(entry.query),
          ),
      ],
    );
  }
}
