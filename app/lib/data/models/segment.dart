import 'json_utils.dart';

/// Частина тіла — розділ довідника.
class Segment {
  const Segment({
    required this.id,
    required this.title,
    required this.sourceTitle,
    required this.sourcePages,
    required this.overviewFigureIds,
    required this.pointCodes,
  });

  factory Segment.fromJson(JsonMap json) => Segment(
    id: json['id'] as String,
    title: json['title'] as String,
    sourceTitle: json['sourceTitle'] as String,
    sourcePages: json['sourcePages'] as String,
    overviewFigureIds: stringList(json['overviewFigureIds']),
    pointCodes: stringList(json['pointCodes']),
  );

  final String id;

  /// Назва для інтерфейсу («Голова»).
  final String title;

  /// Назва розділу в джерелі («Точки надавливания на голове»).
  final String sourceTitle;
  final String sourcePages;
  final List<String> overviewFigureIds;

  /// Коди точок у порядку книги.
  final List<String> pointCodes;
}
