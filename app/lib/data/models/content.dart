import 'figure.dart';
import 'json_utils.dart';
import 'point.dart';
import 'segment.dart';
import 'symptom.dart';

class GlossaryTerm {
  const GlossaryTerm({required this.term, required this.definition});

  factory GlossaryTerm.fromJson(JsonMap json) => GlossaryTerm(
    term: json['term'] as String,
    definition: json['definition'] as String,
  );

  final String term;
  final String definition;
}

class LegendEntry {
  const LegendEntry({required this.code, required this.meaning});

  factory LegendEntry.fromJson(JsonMap json) => LegendEntry(
    code: json['code'] as String,
    meaning: json['meaning'] as String,
  );

  final String code;
  final String meaning;
}

/// Код із покажчика, для якого немає описаної точки.
class UnresolvedCode {
  const UnresolvedCode({required this.symptomId, required this.label});

  factory UnresolvedCode.fromJson(JsonMap json) => UnresolvedCode(
    symptomId: json['symptomId'] as String,
    label: json['label'] as String,
  );

  final String symptomId;
  final String label;
}

class ContentMeta {
  const ContentMeta({
    required this.legend,
    required this.somaticCodes,
    required this.unresolvedCodes,
    required this.introSections,
    required this.introFigureIds,
    required this.source,
  });

  factory ContentMeta.fromJson(JsonMap json) {
    final intro = json['intro'] as JsonMap;
    return ContentMeta(
      legend: objectList(json['legend'], LegendEntry.fromJson),
      somaticCodes: stringList(json['somaticCodes']),
      unresolvedCodes: objectList(
        json['unresolvedCodes'],
        UnresolvedCode.fromJson,
      ),
      introSections: objectList(intro['sections'], ContentSection.fromJson),
      introFigureIds: stringList(intro['figureIds']),
      source: json['source'] as String,
    );
  }

  final List<LegendEntry> legend;
  final List<String> somaticCodes;
  final List<UnresolvedCode> unresolvedCodes;
  final List<ContentSection> introSections;
  final List<String> introFigureIds;
  final String source;
}

/// Увесь вміст довідника, як він лежить у `assets/content.json`.
class Content {
  const Content({
    required this.version,
    required this.segments,
    required this.points,
    required this.figures,
    required this.symptomGroups,
    required this.symptoms,
    required this.glossary,
    required this.meta,
  });

  factory Content.fromJson(JsonMap json) => Content(
    version: json['version'] as int,
    segments: objectList(json['segments'], Segment.fromJson),
    points: objectList(json['points'], Point.fromJson),
    figures: objectList(json['figures'], Figure.fromJson),
    symptomGroups: objectList(json['symptomGroups'], SymptomGroup.fromJson),
    symptoms: objectList(json['symptoms'], Symptom.fromJson),
    glossary: objectList(json['glossary'], GlossaryTerm.fromJson),
    meta: ContentMeta.fromJson(json['meta'] as JsonMap),
  );

  final int version;
  final List<Segment> segments;
  final List<Point> points;
  final List<Figure> figures;
  final List<SymptomGroup> symptomGroups;
  final List<Symptom> symptoms;
  final List<GlossaryTerm> glossary;
  final ContentMeta meta;
}
