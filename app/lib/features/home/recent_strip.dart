import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_badge.dart';
import '../../core/widgets/paper_image.dart';
import '../../data/models/figure.dart';

/// Картка нещодавно відкритого: точка, сегмент, симптом або термін.
class RecentItem {
  const RecentItem({
    required this.title,
    required this.onTap,
    this.code,
    this.figure,
    this.icon,
  });

  /// Назва для підпису та екранного читача.
  final String title;

  /// Код точки; якщо є, показується бейджем замість назви.
  final String? code;
  final Figure? figure;

  /// Іконка, коли малюнка немає (симптом, термін).
  final IconData? icon;
  final VoidCallback onTap;
}

/// Горизонтальна стрічка нещодавно відкритого.
class RecentStrip extends StatelessWidget {
  const RecentStrip({required this.items, super.key});

  static const double cardWidth = 124;
  static const double imageHeight = 76;

  final List<RecentItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    // Висота підпису росте разом із системним шрифтом.
    final labelHeight = MediaQuery.textScalerOf(context).scale(22) + 14;

    return SizedBox(
      height: imageHeight + labelHeight + AppSpacing.sm,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: cardWidth,
            child: Card(
              child: Semantics(
                button: true,
                label: item.title,
                excludeSemantics: true,
                child: InkWell(
                  onTap: item.onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: imageHeight,
                        child: item.figure != null
                            ? PaperImage(
                                item.figure!,
                                fit: BoxFit.cover,
                                borderRadius: 0,
                                cacheWidth: (cardWidth * pixelRatio).round(),
                              )
                            : ColoredBox(
                                color: scheme.secondaryContainer,
                                child: Icon(
                                  item.icon ?? Icons.article_outlined,
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: item.code != null
                                ? FittedBox(child: CodeBadge(item.code!))
                                : Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
