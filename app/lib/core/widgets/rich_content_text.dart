import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Шматок абзацу: звичайний текст або посилання на точку.
@immutable
class RichSegment {
  const RichSegment.text(this.text) : code = null;

  const RichSegment.link(String this.code, this.text);

  final String text;

  /// Код точки, якщо це посилання.
  final String? code;

  bool get isLink => code != null;

  @override
  bool operator ==(Object other) =>
      other is RichSegment && other.text == text && other.code == code;

  @override
  int get hashCode => Object.hash(text, code);

  @override
  String toString() => isLink ? 'link($code, $text)' : 'text($text)';
}

final RegExp _link = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');

/// Розбирає розмітку вмісту: `[[12M]]` і `[[S1|S1 правая]]`.
List<RichSegment> parseRichContent(String source) {
  final segments = <RichSegment>[];
  var position = 0;
  for (final match in _link.allMatches(source)) {
    if (match.start > position) {
      segments.add(RichSegment.text(source.substring(position, match.start)));
    }
    final code = match.group(1)!;
    segments.add(RichSegment.link(code, match.group(2) ?? code));
    position = match.end;
  }
  if (position < source.length) {
    segments.add(RichSegment.text(source.substring(position)));
  }
  return segments;
}

/// Абзац із клікабельними кодами точок.
class RichContentText extends StatefulWidget {
  const RichContentText(
    this.source, {
    required this.onPointTap,
    this.style,
    super.key,
  });

  final String source;
  final ValueChanged<String> onPointTap;
  final TextStyle? style;

  @override
  State<RichContentText> createState() => _RichContentTextState();
}

class _RichContentTextState extends State<RichContentText> {
  final List<TapGestureRecognizer> _recognizers = [];
  late List<RichSegment> _segments;

  @override
  void initState() {
    super.initState();
    _segments = parseRichContent(widget.source);
  }

  @override
  void didUpdateWidget(RichContentText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _segments = parseRichContent(widget.source);
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    _disposeRecognizers();
    final spans = <InlineSpan>[
      for (final segment in _segments)
        if (segment.isLink)
          TextSpan(
            text: segment.text,
            style: linkStyle,
            recognizer: _recognizerFor(segment.code!),
          )
        else
          TextSpan(text: segment.text),
    ];

    return Text.rich(
      TextSpan(children: spans),
      style: widget.style ?? theme.textTheme.bodyLarge,
    );
  }

  TapGestureRecognizer _recognizerFor(String code) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onPointTap(code);
    _recognizers.add(recognizer);
    return recognizer;
  }
}
