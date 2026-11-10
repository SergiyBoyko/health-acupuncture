import 'package:flutter/material.dart';

import '../l10n.dart';
import '../router/app_tab.dart';

/// Іконка пошуку для верхньої панелі: пошук доступний з кожного екрана.
class SearchAction extends StatelessWidget {
  const SearchAction({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.search,
    icon: const Icon(Icons.search),
    onPressed: () => context.openSearch(),
  );
}
