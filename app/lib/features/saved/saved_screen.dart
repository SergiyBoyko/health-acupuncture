import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/widgets/empty_state.dart';

/// Обране та історія. Реалізується в блоці 11 плану.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSaved)),
      body: EmptyState(icon: Icons.construction, title: l10n.sectionInProgress),
    );
  }
}
