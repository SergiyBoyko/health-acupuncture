import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_field.dart';
import '../../core/widgets/search_action.dart';
import '../../data/providers.dart';
import 'legend_sheet.dart';
import 'symptom_entry_tile.dart';
import 'symptom_index.dart';

/// Покажчик «хвороба / орган → точки» за алфавітом.
class SymptomsScreen extends ConsumerStatefulWidget {
  const SymptomsScreen({super.key});

  @override
  ConsumerState<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends ConsumerState<SymptomsScreen> {
  final TextEditingController _filter = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};

  @override
  void dispose() {
    _filter.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jumpTo(String letter) {
    final target = _letterKeys[letter]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(repositoryProvider);
    final query = _filter.text.trim();
    final filtering = query.isNotEmpty;
    final entries = filterEntries(repository, query);

    // Розділи за першою літерою, у порядку списку.
    final sections = <String, List<SymptomEntry>>{};
    for (final entry in entries) {
      sections.putIfAbsent(entry.letter, () => []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabSymptoms),
        actions: [
          IconButton(
            tooltip: l10n.legend,
            icon: const Icon(Icons.info_outline),
            onPressed: () => showLegendSheet(
              context,
              repository: repository,
              onPointTap: (code) => context.openPoint(code),
            ),
          ),
          IconButton(
            tooltip: l10n.glossary,
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => context.openGlossary(),
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
            child: FilterField(
              controller: _filter,
              hintText: l10n.symptomFilterHint,
              onChanged: () => setState(() {}),
            ),
          ),
          if (!filtering)
            _LetterBar(letters: sections.keys.toList(), onLetterTap: _jumpTo),
          Expanded(
            child: entries.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: l10n.noMatchesTitle,
                    message: l10n.symptomNoMatchesMessage(query),
                    actionLabel: l10n.clearFilter,
                    onAction: () => setState(_filter.clear),
                  )
                : SingleChildScrollView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    // Список будується цілком (≈260 рядків), щоб перехід за
                    // літерою міг знайти будь-який розділ.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final MapEntry(key: letter, value: items)
                            in sections.entries) ...[
                          if (!filtering)
                            _LetterHeader(
                              letter,
                              key: _letterKeys.putIfAbsent(
                                letter,
                                GlobalKey.new,
                              ),
                            ),
                          for (final entry in items) SymptomEntryTile(entry),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LetterHeader extends StatelessWidget {
  const _LetterHeader(this.letter, {super.key});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          letter,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Швидкий перехід за літерою: горизонтальна стрічка з повноцінними цілями
/// дотику (48 dp), а не вузька смужка збоку.
class _LetterBar extends StatelessWidget {
  const _LetterBar({required this.letters, required this.onLetterTap});

  final List<String> letters;
  final ValueChanged<String> onLetterTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemCount: letters.length,
        itemBuilder: (context, index) {
          final letter = letters[index];
          return Semantics(
            button: true,
            label: l10n.jumpToLetter(letter),
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onLetterTap(letter),
              customBorder: const CircleBorder(),
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: Text(
                    letter,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    textScaler: TextScaler.noScaling,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
