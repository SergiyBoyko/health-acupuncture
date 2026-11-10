import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content_repository.dart';
import '../../data/providers.dart';

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
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Завантаження довідника',
          ),
        ),
      ),
      error: (error, stackTrace) => _ContentError(
        onRetry: () => ref.invalidate(contentRepositoryProvider),
      ),
    );
  }
}

class _ContentError extends StatelessWidget {
  const _ContentError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Не вдалося відкрити довідник',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Дані застосунку пошкоджені. Спробуйте ще раз або '
                'перевстановіть застосунок.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Спробувати ще'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
