import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../data/providers.dart';

/// Вкладка «Тіло»: перелік сегментів. Картки з ілюстраціями — блок 6 плану.
class BodyScreen extends ConsumerWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repository = ref.watch(repositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bodyTitle)),
      body: ListView(
        children: [
          for (final segment in repository.segments)
            ListTile(
              title: Text(segment.title),
              subtitle: Text(l10n.pointsCount(segment.pointCodes.length)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.openSegment(segment.id),
            ),
        ],
      ),
    );
  }
}
