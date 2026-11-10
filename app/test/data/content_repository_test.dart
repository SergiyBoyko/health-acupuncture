import 'dart:io';

import 'package:acupoints/data/content_repository.dart';
import 'package:acupoints/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_content.dart';

void main() {
  late ContentRepository repo;

  setUpAll(() => repo = loadTestContent());

  group('обсяг вмісту', () {
    test('кількості відповідають джерелу', () {
      expect(repo.segments, hasLength(5));
      expect(repo.points, hasLength(119));
      expect(repo.figures, hasLength(131));
      expect(repo.glossary, hasLength(71));
      expect(repo.symptomGroups, hasLength(4));
      expect(repo.symptoms, hasLength(304));
    });

    test('точки розподілені за сегментами', () {
      final counts = {
        for (final s in repo.segments) s.id: repo.pointsOfSegment(s.id).length,
      };
      expect(counts, {
        'golova': 36,
        'shyya': 6,
        'tulub': 37,
        'spyna': 15,
        'ruky-nohy': 25,
      });
    });
  });

  group('цілісність', () {
    test('кожен малюнок має файл і розміри', () {
      for (final figure in repo.figures) {
        expect(File(figure.asset).existsSync(), isTrue, reason: figure.asset);
        expect(figure.width, greaterThan(0));
        expect(figure.height, greaterThan(0));
        expect(figure.width, lessThanOrEqualTo(1200));
        expect(figure.height, lessThanOrEqualTo(1200));
      }
    });

    test('посилання точок розв\'язуються', () {
      for (final point in repo.points) {
        expect(repo.segment(point.segmentId), isNotNull, reason: point.code);
        expect(point.figureIds, isNotEmpty, reason: point.code);
        expect(
          repo.figuresOfPoint(point),
          hasLength(point.figureIds.length),
          reason: point.code,
        );
        expect(
          repo.pointsByCodes(point.relatedCodes),
          hasLength(point.relatedCodes.length),
          reason: point.code,
        );
        expect(
          repo.symptomsOfPoint(point),
          hasLength(point.symptomIds.length),
          reason: point.code,
        );
      }
    });

    test('посилання симптомів розв\'язуються, групи існують', () {
      for (final symptom in repo.symptoms) {
        if (symptom.groupId != null) {
          expect(repo.symptomGroup(symptom.groupId!), isNotNull);
        }
        for (final ref in symptom.refs) {
          for (final part in ref.parts) {
            if (part.kind == SymptomPartKind.point) {
              expect(part.codes, isNotEmpty, reason: symptom.id);
              expect(
                repo.pointsByCodes(part.codes),
                hasLength(part.codes.length),
                reason: symptom.id,
              );
            } else {
              expect(part.label, isNotEmpty, reason: symptom.id);
            }
          }
        }
      }
    });

    test('ідентифікатори унікальні', () {
      expect(repo.points.map((p) => p.code).toSet(), hasLength(119));
      expect(repo.figures.map((f) => f.id).toSet(), hasLength(131));
      expect(repo.symptoms.map((s) => s.id).toSet(), hasLength(304));
    });
  });

  group('точки', () {
    test('звичайна точка', () {
      final point = repo.point('12M')!;
      expect(point.segmentId, 'golova');
      expect(point.sourcePage, 7);
      expect(point.somatic, isFalse);
      expect(point.relatedCodes, contains('9B'));
      expect(point.sections.single.paragraphs.first, contains('[[9B]]'));
      expect(point.notes, isNotEmpty);
    });

    test('точка зі сторонами має секції із заголовками', () {
      final point = repo.point('S1')!;
      expect(point.sections, hasLength(2));
      expect(point.sections.first.headings.single, contains('правая'));
      expect(point.sections.last.headings.single, contains('левая'));
    });

    test('два заголовки сторін над спільним абзацом', () {
      final section = repo.point('32')!.sections.single;
      expect(section.headings, hasLength(2));
      expect(section.paragraphs, hasLength(1));
    });

    test('соматична точка і точка з дробовим кодом', () {
      expect(repo.point('10M')!.somatic, isTrue);
      expect(repo.point('49½'), isNotNull);
    });

    test('точка без згадок у покажчику', () {
      expect(repo.point('67')!.symptomIds, isEmpty);
    });

    test('спершу малюнки біля опису, потім зведені схеми', () {
      final kinds = repo
          .figuresOfPoint(repo.point('2M')!)
          .map((f) => f.kind)
          .toList();
      final firstOverview = kinds.indexOf(FigureKind.overview);
      expect(firstOverview, greaterThan(0));
      expect(kinds.sublist(firstOverview), everyElement(FigureKind.overview));
    });

    test('невідомий код', () {
      expect(repo.point('999'), isNull);
      expect(repo.neighbors('999'), (previous: null, next: null));
    });
  });

  group('сусідні точки', () {
    test('перша точка сегмента не має попередньої', () {
      final n = repo.neighbors('2M');
      expect(n.previous, isNull);
      expect(n.next!.code, '35');
    });

    test('остання точка сегмента не має наступної', () {
      final n = repo.neighbors('80');
      expect(n.previous!.code, '14B');
      expect(n.next, isNull);
    });

    test('сусіди не виходять за межі сегмента', () {
      expect(repo.neighbors('48').previous, isNull);
    });
  });

  group('симптоми', () {
    test('сторона точки', () {
      final part = repo.symptom('appenditsit')!.refs.first.parts.single;
      expect(part.codes, ['5B']);
      expect(part.side, BodySide.right);
    });

    test('альтернатива «или»', () {
      final refs = repo.symptom('appenditsit')!.refs;
      expect(refs[1].alternative, isTrue);
      expect(refs[1].parts.single.codes, ['77']);
    });

    test('точки, які натискають разом', () {
      final together = repo
          .symptom('ataksiya')!
          .refs
          .where((r) => r.together)
          .single;
      expect(together.parts.expand((p) => p.codes), ['56', '90']);
    });

    test('парні точки MB', () {
      final pair = repo
          .symptom('bolezn-addisona')!
          .refs
          .map((r) => r.parts.single)
          .firstWhere((p) => p.pair);
      expect(pair.codes, ['10M', '10B']);
    });

    test('код без описаної точки', () {
      final first = repo.symptom('kolit')!.refs.first.parts.single;
      expect(first.kind, SymptomPartKind.unknown);
      expect(first.label, '11E');
      expect(repo.meta.unresolvedCodes.map((u) => u.label), contains('11E'));
    });

    test('однакові терміни об\'єднані зі збереженням рядків джерела', () {
      final symptom = repo.symptom('polovye-zhelezy')!;
      expect(symptom.sourceLines, ['73', '26,56,83']);
      expect(symptom.pointCodes, ['73', '26', '56', '83']);
    });

    test('групи та верхній рівень', () {
      expect(repo.symptomsOfGroup('bol'), hasLength(19));
      expect(repo.topLevelSymptoms.every((s) => s.groupId == null), isTrue);
      expect(
        repo.topLevelSymptoms.length +
            repo.symptomGroups
                .map((g) => repo.symptomsOfGroup(g.id).length)
                .reduce((a, b) => a + b),
        304,
      );
    });

    test('рукописні рядки позначені', () {
      final hand = repo.symptoms.where((s) => s.handwritten);
      expect(hand, hasLength(7));
      expect(hand.map((s) => s.term), contains('шок'));
    });
  });

  group('сегменти і довідкові дані', () {
    test('обкладинка є в кожного сегмента', () {
      for (final segment in repo.segments) {
        expect(repo.coverFigure(segment), isNotNull, reason: segment.id);
      }
    });

    test('обкладинка сегмента без зведених схем — малюнок першої точки', () {
      final neck = repo.segment('shyya')!;
      expect(neck.overviewFigureIds, isEmpty);
      expect(repo.coverFigure(neck)!.pointCodes, contains('48'));
    });

    test('легенда, соматичні точки, вступ', () {
      expect(repo.meta.legend.map((l) => l.code), ['JB', 'S', 'E', 'X', 'MB']);
      expect(repo.meta.somaticCodes, hasLength(15));
      expect(repo.pointsByCodes(repo.meta.somaticCodes), hasLength(15));
      expect(repo.meta.introSections, hasLength(2));
      expect(repo.figuresByIds(repo.meta.introFigureIds), hasLength(3));
    });
  });

  test('пошкоджений JSON дає виняток, а не тихий порожній вміст', () {
    expect(
      () => ContentRepository.fromJsonString('{"version": 1}'),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => ContentRepository.fromJsonString('not json'),
      throwsFormatException,
    );
  });
}
