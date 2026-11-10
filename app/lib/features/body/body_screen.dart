import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/search_action.dart';
import '../../data/providers.dart';
import 'segment_card.dart';

/// Вкладка «Тіло»: п'ять частин тіла.
class BodyScreen extends ConsumerWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(repositoryProvider);
    final segments = repository.segments;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.bodyTitle),
        actions: const [SearchAction()],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screen),
        itemCount: segments.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final segment = segments[index];
          return SegmentCard(
            segment: segment,
            cover: repository.coverFigure(segment),
            onTap: () => context.openSegment(segment.id),
          );
        },
      ),
    );
  }
}
