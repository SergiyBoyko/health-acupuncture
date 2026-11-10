import 'package:flutter/material.dart';

/// Текст із підсвіченими діапазонами (збіги пошуку).
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    required this.ranges,
    this.style,
    this.maxLines,
    super.key,
  });

  final String text;

  /// Діапазони за зростанням, без перетинів.
  final List<TextRange> ranges;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlight = TextStyle(
      backgroundColor: scheme.tertiaryContainer,
      color: scheme.onTertiaryContainer,
      fontWeight: FontWeight.w600,
    );

    final spans = <TextSpan>[];
    var position = 0;
    for (final range in ranges) {
      if (range.start < position || range.end > text.length) continue;
      if (range.start > position) {
        spans.add(TextSpan(text: text.substring(position, range.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: highlight,
        ),
      );
      position = range.end;
    }
    if (position < text.length) {
      spans.add(TextSpan(text: text.substring(position)));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
