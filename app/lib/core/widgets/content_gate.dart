import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content_repository.dart';
import '../../data/providers.dart';
import '../l10n.dart';
import 'empty_state.dart';

/// Показує [builder] лише після завантаження вмісту довідника;
/// до того — індикатор, а в разі збою — повідомлення з повтором.
class ContentGate extends ConsumerWidget {
  const ContentGate({required this.builder, super.key});

  final Widget Function(BuildContext context, ContentRepository repository)
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentRepositoryProvider);
    return content.when(
      data: (repository) => builder(context, repository),
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            semanticsLabel: context.l10n.contentLoading,
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          title: context.l10n.contentErrorTitle,
          message: context.l10n.contentErrorMessage,
          actionLabel: context.l10n.retry,
          onAction: () => ref.invalidate(contentRepositoryProvider),
        ),
      ),
    );
  }
}
