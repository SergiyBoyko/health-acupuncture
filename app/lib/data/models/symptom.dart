import 'json_utils.dart';

enum SymptomPartKind {
  /// Посилання на описану точку (або пару точок).
  point,

  /// Код, якого немає серед описаних точок.
  unknown,

  /// Довільний текст із джерела («положительные ионы»).
  text,
}

enum BodySide { left, right, both }

/// Одна точка (або текст) у посиланні симптому.
class SymptomPart {
  const SymptomPart({
    required this.kind,
    required this.codes,
    required this.pair,
    this.side,
    this.qualifier,
    this.label,
  });

  factory SymptomPart.fromJson(JsonMap json) {
    final side = json['side'] as String?;
    return SymptomPart(
      kind: SymptomPartKind.values.byName(json['kind'] as String),
      codes: stringList(json['codes']),
      pair: json['pair'] as bool,
      side: side == null ? null : BodySide.values.byName(side),
      qualifier: json['qualifier'] as String?,
      label: json['label'] as String?,
    );
  }

  final SymptomPartKind kind;

  /// Один код, або два для парних точок (`10MB` → 10M і 10B).
  final List<String> codes;
  final bool pair;
  final BodySide? side;
  final String? qualifier;

  /// Текст як надруковано — для `unknown` і `text`.
  final String? label;
}

/// Посилання симптому: одна точка або кілька, які натискають разом.
class SymptomRef {
  const SymptomRef({required this.parts, required this.alternative});

  factory SymptomRef.fromJson(JsonMap json) => SymptomRef(
    parts: objectList(json['parts'], SymptomPart.fromJson),
    alternative: json['alternative'] as bool,
  );

  final List<SymptomPart> parts;

  /// «или» відносно попереднього посилання.
  final bool alternative;

  bool get together => parts.length > 1;
}

class SymptomGroup {
  const SymptomGroup({required this.id, required this.title});

  factory SymptomGroup.fromJson(JsonMap json) =>
      SymptomGroup(id: json['id'] as String, title: json['title'] as String);

  final String id;
  final String title;
}

/// Рядок покажчика «хвороба / орган → точки».
class Symptom {
  const Symptom({
    required this.id,
    required this.term,
    required this.handwritten,
    required this.refs,
    required this.sourceLines,
    this.groupId,
  });

  factory Symptom.fromJson(JsonMap json) => Symptom(
    id: json['id'] as String,
    term: json['term'] as String,
    groupId: json['group'] as String?,
    handwritten: json['handwritten'] as bool,
    refs: objectList(json['refs'], SymptomRef.fromJson),
    sourceLines: stringList(json['sourceLines']),
  );

  final String id;
  final String term;
  final String? groupId;
  final bool handwritten;
  final List<SymptomRef> refs;

  /// Рядки як надруковано в книзі.
  final List<String> sourceLines;

  /// Унікальні коди описаних точок у порядку джерела.
  List<String> get pointCodes {
    final seen = <String>{};
    return [
      for (final ref in refs)
        for (final part in ref.parts)
          for (final code in part.codes)
            if (seen.add(code)) code,
    ];
  }
}
