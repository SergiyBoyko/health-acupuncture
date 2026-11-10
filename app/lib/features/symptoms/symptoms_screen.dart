import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/widgets/empty_state.dart';

/// Покажчик симптомів. Реалізується в блоці 9 плану.
class SymptomsScreen extends StatelessWidget {
  const SymptomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSymptoms)),
      body: EmptyState(icon: Icons.construction, title: l10n.sectionInProgress),
    );
  }
}
