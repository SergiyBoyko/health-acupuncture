import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/widgets/empty_state.dart';

/// Невідома адреса або код, якого немає в довіднику.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.travel_explore,
        title: l10n.notFoundTitle,
        message: l10n.notFoundMessage,
        actionLabel: l10n.goHome,
        onAction: () => context.go(AppTab.home.root),
      ),
    );
  }
}
