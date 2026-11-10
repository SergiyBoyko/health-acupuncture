import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_badge.dart';
import '../../core/widgets/favorite_toggle.dart';
import '../../core/widgets/point_list_tile.dart';
import '../../core/widgets/rich_content_text.dart';
import '../../core/widgets/search_action.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/somatic_tag.dart';
import '../../core/widgets/view_recorder.dart';
import '../../data/content_repository.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../data/user/user_models.dart';
import '../shell/not_found_screen.dart';
import 'widgets/note_block.dart';
import 'widgets/point_gallery.dart';
import 'widgets/symptom_chips.dart';

/// Сторінка точки: де вона, що лікує, з чим пов'язана.
class PointScreen extends ConsumerWidget {
  const PointScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(repositoryProvider);
    final point = repository.point(code);
    if (point == null) return const NotFoundScreen();

    return Scaffold(
      appBar: AppBar(
        actions: [
          FavoriteButton(code: point.code),
          const SearchAction(),
        ],
      ),
      body: ViewRecorder(
        type: ViewType.point,
        id: point.code,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: _PointBody(point: point, repository: repository),
        ),
      ),
    );
  }
}

class _PointBody extends StatelessWidget {
  const _PointBody({required this.point, required this.repository});

  final Point point;
  final ContentRepository repository;

  static String _symptomLabel(Symptom symptom, ContentRepository repository) {
    final group = symptom.groupId == null
        ? null
        : repository.symptomGroup(symptom.groupId!)?.title;
    return group == null ? symptom.term : '$group: ${symptom.term}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final segment = repository.segment(point.segmentId)!;
    final figures = repository.figuresOfPoint(point);
    final related = repository.pointsByCodes(point.relatedCodes);
    final symptoms = repository.symptomsOfPoint(point);
    final neighbors = repository.neighbors(point.code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (figures.isNotEmpty) ...[
          PointGallery(
            figures: figures,
            onFigureTap: (index) =>
                context.openPointImage(point.code, figures[index].id),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CodeBadge(point.code, size: CodeBadgeSize.large),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        point.title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (point.somatic)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xs),
                        child: SomaticTag(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: TextButton.icon(
              onPressed: () => context.openSegment(segment.id),
              icon: const Icon(Icons.chevron_right),
              iconAlignment: IconAlignment.end,
              label: Text(
                '${segment.title} · ${l10n.sourcePage(point.sourcePage)}',
              ),
            ),
          ),
        ),
        SectionHeader(l10n.pointDescription),
        for (final section in point.sections)
          _SectionView(
            section: section,
            onPointTap: (code) => context.openPoint(code),
          ),
        if (related.isNotEmpty) ...[
          SectionHeader(l10n.relatedPoints),
          for (final other in related)
            PointListTile(
              point: other,
              onTap: () => context.openPoint(other.code),
            ),
        ],
        if (symptoms.isNotEmpty) ...[
          SectionHeader(l10n.pointSymptoms),
          SymptomChips(
            onSymptomTap: (id) => context.openSymptom(id),
            symptoms: [
              for (final symptom in symptoms)
                (id: symptom.id, label: _symptomLabel(symptom, repository)),
            ],
          ),
        ],
        if (point.notes.isNotEmpty)
          NoteBlock(
            icon: Icons.edit_note,
            title: l10n.handwrittenNotes,
            notes: point.notes,
            background: colors.noteContainer,
            foreground: colors.onNoteContainer,
          ),
        if (point.transcriptionNotes.isNotEmpty)
          NoteBlock(
            icon: Icons.info_outline,
            title: l10n.transcriptionNotes,
            notes: point.transcriptionNotes,
            background: theme.colorScheme.surfaceContainerHigh,
            foreground: theme.colorScheme.onSurfaceVariant,
          ),
        if (neighbors.previous != null || neighbors.next != null)
          _NeighborBar(neighbors: neighbors),
      ],
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section, required this.onPointTap});

  final ContentSection section;
  final ValueChanged<String> onPointTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final heading in section.headings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Semantics(
                header: true,
                child: Text(
                  heading,
                  style: theme.textTheme.titleSmall?.copyWith(height: 1.35),
                ),
              ),
            ),
          for (final (index, paragraph) in section.paragraphs.indexed)
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.sm),
              child: RichContentText(paragraph, onPointTap: onPointTap),
            ),
        ],
      ),
    );
  }
}

/// Перехід до попередньої та наступної точки сегмента.
class _NeighborBar extends StatelessWidget {
  const _NeighborBar({required this.neighbors});

  final PointNeighbors neighbors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final previous = neighbors.previous;
    final next = neighbors.next;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xl,
        AppSpacing.screen,
        0,
      ),
      child: Row(
        children: [
          if (previous != null)
            OutlinedButton.icon(
              onPressed: () => context.replacePoint(previous.code),
              icon: const Icon(Icons.chevron_left),
              label: Text(previous.code),
              style: OutlinedButton.styleFrom(minimumSize: const Size(72, 48)),
            ).withTooltip(l10n.previousPoint),
          const Spacer(),
          if (next != null)
            OutlinedButton.icon(
              onPressed: () => context.replacePoint(next.code),
              icon: const Icon(Icons.chevron_right),
              iconAlignment: IconAlignment.end,
              label: Text(next.code),
              style: OutlinedButton.styleFrom(minimumSize: const Size(72, 48)),
            ).withTooltip(l10n.nextPoint),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget withTooltip(String message) => Tooltip(message: message, child: this);
}
