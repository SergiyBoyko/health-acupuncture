import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user/user_providers.dart';
import '../l10n.dart';

/// Перемикає обране з тактильним відгуком і коротким повідомленням.
void toggleFavorite(BuildContext context, WidgetRef ref, String code) {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final added = ref.read(favoritesProvider.notifier).toggle(code);
  HapticFeedback.selectionClick();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          added ? l10n.addedToFavorites(code) : l10n.removedFromFavorites(code),
        ),
      ),
    );
}

/// Зірочка «в обране» для верхньої панелі та рядків списку.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isFavorite = ref.watch(favoriteCodesProvider).contains(code);
    return IconButton(
      tooltip: isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
      isSelected: isFavorite,
      icon: const Icon(Icons.star_outline),
      selectedIcon: Icon(
        Icons.star,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () => toggleFavorite(context, ref, code),
    );
  }
}
