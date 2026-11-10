import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/json_utils.dart';
import 'models/models.dart';

/// Сусідні точки в межах сегмента (порядок книги).
typedef PointNeighbors = ({Point? previous, Point? next});

/// Доступ до вмісту довідника лише для читання.
///
/// Дані завантажуються один раз і живуть у пам'яті: їх небагато
/// (119 точок, 131 малюнок, 304 симптоми).
class ContentRepository {
  ContentRepository(this.content)
    : _points = {for (final p in content.points) p.code: p},
      _segments = {for (final s in content.segments) s.id: s},
      _figures = {for (final f in content.figures) f.id: f},
      _symptoms = {for (final s in content.symptoms) s.id: s},
      _groups = {for (final g in content.symptomGroups) g.id: g};

  factory ContentRepository.fromJsonString(String source) =>
      ContentRepository(Content.fromJson(jsonDecode(source) as JsonMap));

  static const String assetPath = 'assets/content.json';

  static Future<ContentRepository> load(AssetBundle bundle) async =>
      ContentRepository.fromJsonString(await bundle.loadString(assetPath));

  final Content content;
  final Map<String, Point> _points;
  final Map<String, Segment> _segments;
  final Map<String, Figure> _figures;
  final Map<String, Symptom> _symptoms;
  final Map<String, SymptomGroup> _groups;

  List<Segment> get segments => content.segments;
  List<Point> get points => content.points;
  List<Figure> get figures => content.figures;
  List<Symptom> get symptoms => content.symptoms;
  List<SymptomGroup> get symptomGroups => content.symptomGroups;
  List<GlossaryTerm> get glossary => content.glossary;
  ContentMeta get meta => content.meta;

  Point? point(String code) => _points[code];
  Segment? segment(String id) => _segments[id];
  Figure? figure(String id) => _figures[id];
  Symptom? symptom(String id) => _symptoms[id];
  SymptomGroup? symptomGroup(String id) => _groups[id];

  /// Точки сегмента в порядку книги.
  List<Point> pointsOfSegment(String segmentId) => [
    for (final code in _segments[segmentId]?.pointCodes ?? const <String>[])
      ?_points[code],
  ];

  List<Figure> figuresByIds(Iterable<String> ids) => [
    for (final id in ids) ?_figures[id],
  ];

  List<Figure> figuresOfPoint(Point point) => figuresByIds(point.figureIds);

  List<Point> pointsByCodes(Iterable<String> codes) => [
    for (final code in codes) ?_points[code],
  ];

  List<Symptom> symptomsOfPoint(Point point) => [
    for (final id in point.symptomIds) ?_symptoms[id],
  ];

  /// Симптоми верхнього рівня (без тих, що входять у групи).
  List<Symptom> get topLevelSymptoms => [
    for (final s in content.symptoms)
      if (s.groupId == null) s,
  ];

  List<Symptom> symptomsOfGroup(String groupId) => [
    for (final s in content.symptoms)
      if (s.groupId == groupId) s,
  ];

  /// Ілюстрація сегмента: перша зведена схема, а якщо її немає —
  /// перший малюнок першої точки.
  Figure? coverFigure(Segment segment) {
    for (final id in segment.overviewFigureIds) {
      final figure = _figures[id];
      if (figure != null) return figure;
    }
    for (final point in pointsOfSegment(segment.id)) {
      final figures = figuresOfPoint(point);
      if (figures.isNotEmpty) return figures.first;
    }
    return null;
  }

  PointNeighbors neighbors(String code) {
    final point = _points[code];
    if (point == null) return (previous: null, next: null);
    final codes = _segments[point.segmentId]?.pointCodes ?? const <String>[];
    final index = codes.indexOf(code);
    if (index < 0) return (previous: null, next: null);
    return (
      previous: index > 0 ? _points[codes[index - 1]] : null,
      next: index < codes.length - 1 ? _points[codes[index + 1]] : null,
    );
  }
}
