import 'package:flutter/material.dart';

import '../../data/models/figure.dart';
import '../l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Малюнок із джерела на «паперовій» підкладці.
///
/// Підкладка однакова у світлій і темній темах: скан не інвертується.
class PaperImage extends StatelessWidget {
  const PaperImage(
    this.figure, {
    this.fit = BoxFit.contain,
    this.borderRadius = AppRadius.card,
    this.padding = EdgeInsets.zero,
    this.cacheWidth,
    super.key,
  });

  final Figure figure;
  final BoxFit fit;
  final double borderRadius;
  final EdgeInsets padding;

  /// Ширина декодування для мініатюр (логічні пікселі × щільність).
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: colors.paper,
        child: Padding(
          padding: padding,
          child: Image.asset(
            figure.asset,
            fit: fit,
            cacheWidth: cacheWidth,
            semanticLabel: figure.caption,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: colors.onPaper,
                semanticLabel: context.l10n.imageUnavailable,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
