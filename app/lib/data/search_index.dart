import 'dart:ui' show TextRange;

import 'content_repository.dart';
import 'models/models.dart';
import 'text_normalizer.dart';

/// Слово в тексті та його позиція в оригінальному рядку.
typedef _Token = ({String text, int start});

final RegExp _word = RegExp(r'[a-zа-яіїєґ0-9½]+');
final RegExp _markup = RegExp(r'\[\[(?:[^\]|]+\|)?([^\]]+)\]\]');

/// Нижній регістр і `ё` → `е` не змінюють довжину рядка, тож позиції
/// слів збігаються з оригіналом.
List<_Token> _tokenize(String source) {
  final lower = source.toLowerCase().replaceAll('ё', 'е');
  return [
    for (final match in _word.allMatches(lower))
      (text: match.group(0)!, start: match.start),
  ];
}

/// Слова запиту для пошуку та підсвічування.
List<String> queryTokens(String query) =>
    _tokenize(query).map((t) => t.text).toList();

/// Діапазони в [text], де слово починається з одного зі слів запиту.
List<TextRange> highlightRanges(String text, List<String> tokens) {
  if (tokens.isEmpty) return const [];
  final ranges = <TextRange>[];
  for (final token in _tokenize(text)) {
    var length = 0;
    for (final query in tokens) {
      if (query.length > length && token.text.startsWith(query)) {
        length = query.length;
      }
    }
    if (length > 0) {
      ranges.add(TextRange(start: token.start, end: token.start + length));
    }
  }
  return ranges;
}

/// Ваги полів: що вище, то важливіший збіг.
abstract final class SearchWeights {
  static const double exactCode = 100;
  static const double codePrefix = 80;
  static const double title = 60;
  static const double symptomTerm = 50;
  static const double description = 30;
  static const double note = 20;
  static const double glossaryTerm = 10;
  static const double glossaryDefinition = 5;

  /// Надбавка, коли всі слова запиту знайшлись у найважливішому полі.
  static const double sameFieldBonus = 5;
}

class PointHit {
  const PointHit({required this.point, required this.score, this.snippet});

  final Point point;
  final double score;

  /// Фрагмент опису або нотатки навколо збігу; `null`, якщо збіг у коді
  /// чи заголовку.
  final String? snippet;
}

class SymptomHit {
  const SymptomHit({
    required this.symptom,
    required this.title,
    required this.score,
  });

  final Symptom symptom;

  /// Назва з групою: «Глаза: катаракта».
  final String title;
  final double score;
}

class GlossaryHit {
  const GlossaryHit({required this.term, required this.score});

  final GlossaryTerm term;
  final double score;
}

class SearchResults {
  const SearchResults({
    required this.tokens,
    required this.points,
    required this.symptoms,
    required this.glossary,
  });

  static const SearchResults empty = SearchResults(
    tokens: [],
    points: [],
    symptoms: [],
    glossary: [],
  );

  /// Слова запиту — для підсвічування збігів.
  final List<String> tokens;
  final List<PointHit> points;
  final List<SymptomHit> symptoms;
  final List<GlossaryHit> glossary;

  bool get isEmpty => points.isEmpty && symptoms.isEmpty && glossary.isEmpty;

  int get total => points.length + symptoms.length + glossary.length;
}

class _Field {
  _Field(this.weight, this.text) : tokens = _tokenize(text);

  final double weight;
  final String text;
  final List<_Token> tokens;

  /// Перше слово поля, що починається з [query].
  _Token? firstMatch(String query) {
    for (final token in tokens) {
      if (token.text.startsWith(query)) return token;
    }
    return null;
  }
}

/// Найкраща вага для кожного слова запиту; `null`, якщо якесь слово не
/// знайшлось у жодному полі (усі слова обов'язкові).
({double score, _Field field})? _matchFields(
  List<_Field> fields,
  List<String> tokens,
) {
  var total = 0.0;
  _Field? weakest;
  _Field? strongest;
  for (final query in tokens) {
    _Field? best;
    for (final field in fields) {
      if (field.firstMatch(query) != null &&
          (best == null || field.weight > best.weight)) {
        best = field;
      }
    }
    if (best == null) return null;
    total += best.weight;
    if (weakest == null || best.weight < weakest.weight) weakest = best;
    if (strongest == null || best.weight > strongest.weight) strongest = best;
  }
  var score = total / tokens.length;
  if (identical(weakest, strongest)) score += SearchWeights.sameFieldBonus;
  return (score: score, field: weakest!);
}

class _PointDoc {
  _PointDoc(this.point)
    : code = TextNormalizer.code(point.code),
      title = _Field(SearchWeights.title, point.title),
      description = _Field(
        SearchWeights.description,
        [
          for (final section in point.sections) ...[
            ...section.headings,
            ...section.paragraphs,
          ],
        ].join(' ').replaceAllMapped(_markup, (m) => m.group(1)!),
      ),
      notes = _Field(SearchWeights.note, point.notes.join(' '));

  final Point point;
  final String code;
  final _Field title;
  final _Field description;
  final _Field notes;
}

/// Пошук по кодах, заголовках, описах, нотатках, покажчику і словнику.
///
/// Індекс живе в пам'яті: вмісту мало, тож повний перебір займає частки
/// мілісекунди і зовнішні бібліотеки не потрібні.
class SearchIndex {
  SearchIndex(ContentRepository repository)
    : _points = [for (final p in repository.points) _PointDoc(p)],
      _symptoms = [
        for (final symptom in repository.symptoms)
          (
            symptom: symptom,
            field: _Field(
              SearchWeights.symptomTerm,
              _symptomTitle(repository, symptom),
            ),
          ),
      ],
      _glossary = [
        for (final term in repository.glossary)
          (
            term: term,
            name: _Field(SearchWeights.glossaryTerm, term.term),
            definition: _Field(
              SearchWeights.glossaryDefinition,
              term.definition,
            ),
          ),
      ];

  static const int _snippetBefore = 40;
  static const int _snippetAfter = 70;

  final List<_PointDoc> _points;
  final List<({Symptom symptom, _Field field})> _symptoms;
  final List<({GlossaryTerm term, _Field name, _Field definition})> _glossary;

  static String _symptomTitle(ContentRepository repository, Symptom symptom) {
    final group = symptom.groupId == null
        ? null
        : repository.symptomGroup(symptom.groupId!)?.title;
    return group == null ? symptom.term : '$group: ${symptom.term}';
  }

  SearchResults search(String query) {
    final tokens = queryTokens(query);
    final code = TextNormalizer.code(query);
    if (tokens.isEmpty && code.isEmpty) return SearchResults.empty;

    final points = <PointHit>[];
    for (final doc in _points) {
      final hit = _matchPoint(doc, tokens, code);
      if (hit != null) points.add(hit);
    }
    points.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0
          ? byScore
          : comparePointCodes(a.point.code, b.point.code);
    });

    final symptoms = <SymptomHit>[];
    if (tokens.isNotEmpty) {
      for (final doc in _symptoms) {
        final match = _matchFields([doc.field], tokens);
        if (match == null) continue;
        // Коротша назва означає точніший збіг: «Голова» вище за «Грипп, голова».
        final brevity = 1 / (1 + doc.field.tokens.length);
        symptoms.add(
          SymptomHit(
            symptom: doc.symptom,
            title: doc.field.text,
            score: match.score + brevity,
          ),
        );
      }
      symptoms.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0
            ? byScore
            : TextNormalizer.text(
                a.title,
              ).compareTo(TextNormalizer.text(b.title));
      });
    }

    final glossary = <GlossaryHit>[];
    if (tokens.isNotEmpty) {
      for (final doc in _glossary) {
        final match = _matchFields([doc.name, doc.definition], tokens);
        if (match != null) {
          glossary.add(GlossaryHit(term: doc.term, score: match.score));
        }
      }
      glossary.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0
            ? byScore
            : TextNormalizer.text(
                a.term.term,
              ).compareTo(TextNormalizer.text(b.term.term));
      });
    }

    return SearchResults(
      tokens: tokens,
      points: points,
      symptoms: symptoms,
      glossary: glossary,
    );
  }

  PointHit? _matchPoint(_PointDoc doc, List<String> tokens, String code) {
    if (code.isNotEmpty) {
      if (doc.code == code) {
        return PointHit(point: doc.point, score: SearchWeights.exactCode);
      }
      if (doc.code.startsWith(code)) {
        return PointHit(point: doc.point, score: SearchWeights.codePrefix);
      }
    }
    if (tokens.isEmpty) return null;

    final match = _matchFields([doc.title, doc.description, doc.notes], tokens);
    if (match == null) return null;

    final field = match.field;
    return PointHit(
      point: doc.point,
      score: match.score,
      snippet: identical(field, doc.title) ? null : _snippet(field, tokens),
    );
  }

  /// Фрагмент навколо першого збігу, обрізаний по межах слів.
  static String _snippet(_Field field, List<String> tokens) {
    _Token? first;
    for (final query in tokens) {
      final token = field.firstMatch(query);
      if (token != null && (first == null || token.start < first.start)) {
        first = token;
      }
    }
    final text = field.text;
    if (first == null) return text;

    var start = first.start - _snippetBefore;
    if (start <= 0) {
      start = 0;
    } else {
      final space = text.indexOf(' ', start);
      start = space >= 0 && space < first.start ? space + 1 : first.start;
    }
    var end = first.start + _snippetAfter;
    if (end >= text.length) {
      end = text.length;
    } else {
      final space = text.lastIndexOf(' ', end);
      if (space > first.start + first.text.length) end = space;
    }
    return '${start > 0 ? '…' : ''}${text.substring(start, end).trim()}'
        '${end < text.length ? '…' : ''}';
  }
}
