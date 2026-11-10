import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_badge.dart';
import '../../core/widgets/point_list_tile.dart';
import '../../core/widgets/section_header.dart';
import '../../data/providers.dart';
import '../shell/not_found_screen.dart';

/// Сторінка точки. Поки що заголовок і пов'язані точки; галерея, опис і
/// решта блоків — блок 7 плану.
class PointScreen extends ConsumerWidget {
  const PointScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final repository = ref.watch(repositoryProvider);
    final point = repository.point(code);
    if (point == null) return const NotFoundScreen();

    final segment = repository.segment(point.segmentId)!;
    final related = repository.pointsByCodes(point.relatedCodes);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CodeBadge(point.code, size: CodeBadgeSize.large),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(point.title, style: theme.textTheme.titleMedium),
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
          if (related.isNotEmpty) ...[
            SectionHeader(l10n.relatedPoints),
            for (final other in related)
              PointListTile(
                point: other,
                onTap: () => context.openPoint(other.code),
              ),
          ],
        ],
      ),
    );
  }
}
