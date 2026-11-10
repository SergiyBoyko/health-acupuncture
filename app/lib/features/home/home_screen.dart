import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/providers.dart';

/// Головна. Пошук, історія та сегменти з'являться в блоці 12 плану.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repository = ref.watch(repositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: EmptyState(
        icon: Icons.construction,
        title: l10n.sectionInProgress,
        message: l10n.pointsCount(repository.points.length),
      ),
    );
  }
}
