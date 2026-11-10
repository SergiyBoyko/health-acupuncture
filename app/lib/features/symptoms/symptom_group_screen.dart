import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../core/widgets/search_action.dart';
import '../shell/not_found_screen.dart';
import 'symptom_entry_tile.dart';
import 'symptom_index.dart';

/// Підтерміни групи покажчика (Глаза, Голова, Сердце, Боль).
class SymptomGroupScreen extends ConsumerWidget {
  const SymptomGroupScreen({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(repositoryProvider);
    final group = repository.symptomGroup(groupId);
    if (group == null) return const NotFoundScreen();

    final entries = groupEntries(repository, groupId);
    return Scaffold(
      appBar: AppBar(title: Text(group.title), actions: const [SearchAction()]),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) => SymptomEntryTile(entries[index]),
      ),
    );
  }
}
