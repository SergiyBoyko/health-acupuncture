import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_badge.dart';
import '../../core/widgets/point_list_tile.dart';
import '../../core/widgets/search_action.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/view_recorder.dart';
import '../../data/content_repository.dart';
import '../../data/models/symptom.dart';
import '../../data/providers.dart';
import '../../data/user/user_models.dart';
import '../point/widgets/note_block.dart';
import '../shell/not_found_screen.dart';

/// Симптом: точки в порядку джерела з уточненнями.
class SymptomScreen extends ConsumerWidget {
  const SymptomScreen({required this.symptomId, super.key});

  final String symptomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final repository = ref.watch(repositoryProvider);
    final symptom = repository.symptom(symptomId);
    if (symptom == null) return const NotFoundScreen();

    final group = symptom.groupId == null
        ? null
        : repository.symptomGroup(symptom.groupId!);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(actions: const [SearchAction()]),
      body: ViewRecorder(
        type: ViewType.symptom,
        id: symptom.id,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group != null) Text(group.title, style: muted),
                  Semantics(
                    header: true,
                    child: Text(
                      symptom.term,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    symptom.pointCodes.isEmpty
                        ? l10n.noPointsForSymptom
                        : l10n.pointsCount(symptom.pointCodes.length),
                    style: muted,
                  ),
                ],
              ),
            ),
            if (symptom.handwritten)
              NoteBlock(
                icon: Icons.edit_note,
                title: l10n.handwrittenEntry,
                notes: [l10n.handwrittenEntryMessage],
                background: colors.noteContainer,
                foreground: colors.onNoteContainer,
              ),
            const SizedBox(height: AppSpacing.md),
            for (final ref in symptom.refs)
              _RefView(ref: ref, repository: repository),
            SectionHeader(l10n.asPrinted),
            for (final line in symptom.sourceLines)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  0,
                  AppSpacing.screen,
                  AppSpacing.xs,
                ),
                child: Text(
                  '${symptom.term}-$line',
                  style: muted?.copyWith(fontFamily: 'monospace'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Одне посилання симптому: точка, пара, кілька точок разом або текст.
class _RefView extends StatelessWidget {
  const _RefView({required this.ref, required this.repository});

  final SymptomRef ref;
  final ContentRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rows = [
      for (final part in ref.parts) ..._partRows(context, part, repository),
    ];

    final content = ref.together
        ? Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    0,
                  ),
                  child: Text(
                    l10n.pressTogether,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                ...rows,
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          );

    if (!ref.alternative) return content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  l10n.alternative,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),
        content,
      ],
    );
  }

  static String? _qualifier(AppLocalizations l10n, SymptomPart part) {
    final parts = [
      switch (part.side) {
        BodySide.left => l10n.sideLeft,
        BodySide.right => l10n.sideRight,
        BodySide.both => l10n.sideBoth,
        null => null,
      },
      if (part.pair) l10n.pairedPoints,
      part.qualifier,
    ].nonNulls.toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static List<Widget> _partRows(
    BuildContext context,
    SymptomPart part,
    ContentRepository repository,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    switch (part.kind) {
      case SymptomPartKind.point:
        final qualifier = _qualifier(l10n, part);
        return [
          for (final point in repository.pointsByCodes(part.codes))
            PointListTile(
              point: point,
              subtitle: qualifier,
              onTap: () => context.openPoint(point.code),
            ),
        ];
      case SymptomPartKind.unknown:
        return [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                CodeBadge(part.label ?? '', enabled: false),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.unknownCodeMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      case SymptomPartKind.text:
        return [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.notes,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    part.label ?? '',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ];
    }
  }
}
