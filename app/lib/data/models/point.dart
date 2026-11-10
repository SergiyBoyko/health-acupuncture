import 'json_utils.dart';

/// Фрагмент тексту із заголовками (наприклад, сторони «левая» / «правая»).
///
/// Абзаци містять розмітку посилань: `[[12M]]` або `[[S1|S1 правая]]`.
class ContentSection {
  const ContentSection({required this.headings, required this.paragraphs});

  factory ContentSection.fromJson(JsonMap json) => ContentSection(
    headings: stringList(json['headings']),
    paragraphs: stringList(json['paragraphs']),
  );

  final List<String> headings;
  final List<String> paragraphs;
}

/// Точка надавлювання.
class Point {
  const Point({
    required this.code,
    required this.segmentId,
    required this.title,
    required this.somatic,
    required this.sourcePage,
    required this.order,
    required this.sections,
    required this.notes,
    required this.transcriptionNotes,
    required this.figureIds,
    required this.relatedCodes,
    required this.symptomIds,
  });

  factory Point.fromJson(JsonMap json) => Point(
    code: json['code'] as String,
    segmentId: json['segmentId'] as String,
    title: json['title'] as String,
    somatic: json['somatic'] as bool,
    sourcePage: json['sourcePage'] as int,
    order: json['order'] as int,
    sections: objectList(json['sections'], ContentSection.fromJson),
    notes: stringList(json['notes']),
    transcriptionNotes: stringList(json['transcriptionNotes']),
    figureIds: stringList(json['figureIds']),
    relatedCodes: stringList(json['relatedCodes']),
    symptomIds: stringList(json['symptomIds']),
  );

  final String code;
  final String segmentId;
  final String title;
  final bool somatic;
  final int sourcePage;

  /// Порядковий номер у книзі (наскрізний).
  final int order;
  final List<ContentSection> sections;

  /// Рукописні нотатки власника брошури.
  final List<String> notes;
  final List<String> transcriptionNotes;

  /// Спершу малюнки біля опису, потім зведені схеми.
  final List<String> figureIds;
  final List<String> relatedCodes;
  final List<String> symptomIds;
}
