import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_field.dart';
import '../../core/widgets/search_action.dart';
import '../../data/models/content.dart';
import '../../data/providers.dart';
import '../../data/text_normalizer.dart';
import '../../data/user/user_models.dart';
import '../../data/user/user_providers.dart';

/// Словник термінів: за алфавітом, з фільтром; визначення розгортається
/// на місці.
class GlossaryScreen extends ConsumerStatefulWidget {
  const GlossaryScreen({this.initialQuery = '', super.key});

  /// Термін, з яким відкрити словник (перехід з історії).
  final String initialQuery;

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  late final TextEditingController _filter = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  List<GlossaryTerm> _terms(List<GlossaryTerm> all) {
    final needle = TextNormalizer.text(_filter.text);
    return [
      for (final term in all)
        if (needle.isEmpty || TextNormalizer.text(term.term).contains(needle))
          term,
    ]..sort(
      (a, b) =>
          TextNormalizer.text(a.term).compareTo(TextNormalizer.text(b.term)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final terms = _terms(ref.watch(repositoryProvider).glossary);
    final query = _filter.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.glossary),
        actions: const [SearchAction()],
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
              hintText: l10n.glossaryFilterHint,
              onChanged: () => setState(() {}),
            ),
          ),
          Expanded(
            child: terms.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: l10n.noMatchesTitle,
                    message: l10n.glossaryNoMatchesMessage(query),
                    actionLabel: l10n.clearFilter,
                    onAction: () => setState(_filter.clear),
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    itemCount: terms.length,
                    itemBuilder: (context, index) {
                      final term = terms[index];
                      return ExpansionTile(
                        key: PageStorageKey(term.term),
                        title: Text(term.term),
                        initiallyExpanded:
                            widget.initialQuery.isNotEmpty &&
                            term.term == widget.initialQuery,
                        onExpansionChanged: (expanded) {
                          if (!expanded) return;
                          ref
                              .read(viewHistoryProvider.notifier)
                              .add(ViewType.term, term.term);
                        },
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
                          Text(
                            term.definition,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
