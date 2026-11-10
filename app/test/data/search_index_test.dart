import 'package:acupoints/data/search_index.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_content.dart';

void main() {
  final repo = loadTestContent();
  final index = SearchIndex(repo);

  List<String> codes(String query) =>
      index.search(query).points.map((h) => h.point.code).toList();

  List<String> symptoms(String query) =>
      index.search(query).symptoms.map((h) => h.title).toList();

  group('коди', () {
    // запит → перший результат серед точок
    const first = {
      '12M': '12M',
      '12m': '12M',
      '12м': '12M',
      '2в': '2B',
      'jb10': 'JB10',
      'JB 10': 'JB10',
      '49 1/2': '49½',
      '49,1/2': '49½',
      '49½': '49½',
      '49': '49',
      'x': 'X',
      'х': 'X',
      'e': 'E',
      's1': 'S1',
      '7': '7',
    };
    for (final MapEntry(key: query, value: expected) in first.entries) {
      test('«$query» → $expected перша', () {
        expect(codes(query).first, expected);
      });
    }

    test('точний код вище за коди з тим самим початком', () {
      final result = index.search('1').points;
      expect(result.take(4).map((h) => h.point.code), [
        '1B',
        '1M',
        '10B',
        '10M',
      ]);
      expect(result.first.score, SearchWeights.codePrefix);

      final exact = index.search('4').points;
      expect(exact.first.point.code, '4');
      expect(exact.first.score, SearchWeights.exactCode);
      expect(exact[1].point.code, '40');
    });

    test('початок коду: «jb» знаходить три точки за номером', () {
      expect(codes('jb').take(3), ['JB8', 'JB9', 'JB10']);
    });

    test('збіг за кодом не має фрагмента', () {
      expect(index.search('12M').points.first.snippet, isNull);
    });
  });

  group('слова', () {
    test('початок слова', () {
      final result = index.search('голов').points;
      final found = result.map((h) => h.point.code).toList();
      // «…головная боль», «Головокружение…», «Головные боли…» — у заголовках.
      expect(found, containsAll(['2M', '3M', '80']));
      for (final code in ['2M', '3M', '80']) {
        final hit = result.firstWhere((h) => h.point.code == code);
        expect(hit.snippet, isNull, reason: code);
        expect(hit.score, greaterThan(SearchWeights.title), reason: code);
      }
      // Збіги в заголовку стоять вище за збіги в описі.
      final lastTitle = result.lastIndexWhere((h) => h.snippet == null);
      final firstBody = result.indexWhere((h) => h.snippet != null);
      expect(firstBody, greaterThan(lastTitle));
    });

    test('без урахування регістру та ё', () {
      expect(codes('РОДНИЧОК'), containsAll(['2M', '9M']));
      expect(codes('отёк'), codes('отек'));
      expect(codes('отек'), isNotEmpty);
    });

    test('заголовок вище за опис', () {
      final result = index.search('амнезия').points;
      expect(result.first.point.code, '63');
      expect(result.first.snippet, isNull);
      expect(result.first.score, greaterThan(SearchWeights.description));
    });

    test('збіг в описі дає фрагмент навколо слова', () {
      final hit = index
          .search('пирамиду')
          .points
          .singleWhere((h) => h.point.code == '35');
      expect(hit.snippet, contains('пирамиду'));
      expect(hit.snippet, startsWith('…'));
      expect(hit.snippet!.length, lessThan(130));
      expect(hit.score, lessThan(SearchWeights.title));
    });

    test('фрагмент не містить розмітки посилань', () {
      final hit = index
          .search('фасцией')
          .points
          .singleWhere((h) => h.point.code == '12M');
      expect(hit.snippet, contains('"9B"'));
      expect(hit.snippet, isNot(contains('[[')));
    });

    test('шукає в рукописних нотатках', () {
      final hit = index
          .search('морщины')
          .points
          .singleWhere((h) => h.point.code == '51');
      expect(hit.snippet, contains('Морщины'));
    });

    test('усі слова запиту обов\'язкові', () {
      expect(codes('головная боль'), contains('2M'));
      expect(codes('головная слон'), isEmpty);
      // Слова можуть бути в різних полях: заголовок і опис.
      expect(codes('родничок жидкость'), contains('2M'));
    });

    test('обидва слова в заголовку вище, ніж у різних полях', () {
      final result = index.search('родничок жидкость').points;
      final both = index.search('передний родничок').points;
      expect(both.first.point.code, '2M');
      expect(
        both.first.score,
        greaterThan(result.firstWhere((h) => h.point.code == '2M').score),
      );
    });
  });

  group('симптоми і словник', () {
    test('симптоми за початком слова, коротша назва вище', () {
      final found = symptoms('голов');
      expect(found, contains('Головокружение'));
      expect(found, contains('Голова: боль'));
      expect(
        found.indexOf('Головокружение'),
        lessThan(found.indexOf('Грипп, голова')),
      );
    });

    test('підтермін групи знаходиться з назвою групи', () {
      expect(symptoms('катаракта'), ['Глаза: катаракта']);
    });

    test('рукописний запис', () {
      final hit = index.search('шок').symptoms.first;
      expect(hit.title, 'шок');
      expect(hit.symptom.handwritten, isTrue);
    });

    test('словник: термін вище за визначення', () {
      final found = index.search('мозжечок').glossary;
      expect(found.first.term.term, 'Мозжечок');

      final byDefinition = index.search('разветвление').glossary;
      expect(byDefinition.single.term.term, 'Бифуркация');
    });

    test('один запит повертає всі три групи', () {
      final result = index.search('мозг');
      expect(result.points, isNotEmpty);
      expect(result.symptoms, isNotEmpty);
      expect(result.glossary, isNotEmpty);
      expect(
        result.total,
        result.points.length + result.symptoms.length + result.glossary.length,
      );
    });
  });

  group('крайні випадки', () {
    test('порожній запит і лише пунктуація', () {
      expect(index.search('').isEmpty, isTrue);
      expect(index.search('   ').isEmpty, isTrue);
      expect(index.search('?!.').isEmpty, isTrue);
    });

    test('немає збігів', () {
      final result = index.search('ййй');
      expect(result.isEmpty, isTrue);
      expect(result.tokens, ['ййй']);
    });

    test('результати детерміновані', () {
      expect(codes('мозг'), codes('мозг'));
      expect(codes(' Мозг '), codes('мозг'));
    });

    test('порядок: за оцінкою, далі за кодом', () {
      final result = index.search('мозг').points;
      for (var i = 1; i < result.length; i++) {
        expect(
          result[i - 1].score,
          greaterThanOrEqualTo(result[i].score),
          reason: '${result[i - 1].point.code} перед ${result[i].point.code}',
        );
      }
    });

    test('швидкість: сотня запитів за частки секунди', () {
      final watch = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        index.search('голов');
        index.search('12м');
        index.search('желчный пузырь');
      }
      // 300 пошуків; вимога — результат за 100 мс на один запит.
      expect(watch.elapsedMilliseconds, lessThan(3000));
    });
  });

  group('підсвічування', () {
    test('початок слова, а не середина', () {
      const text = 'Головокружение, боль в голове';
      expect(highlightRanges(text, ['голов']), const [
        TextRange(start: 0, end: 5),
        TextRange(start: 23, end: 28),
      ]);
      expect(highlightRanges('преголовье', ['голов']), isEmpty);
    });

    test('регістр і ё не зсувають позиції', () {
      expect(highlightRanges('ОТЁК ног', ['отек']), const [
        TextRange(start: 0, end: 4),
      ]);
    });

    test('найдовше зі слів запиту', () {
      expect(highlightRanges('головная', ['гол', 'голов']), const [
        TextRange(start: 0, end: 5),
      ]);
    });

    test('порожній запит', () {
      expect(highlightRanges('текст', const []), isEmpty);
    });

    test('слова запиту', () {
      expect(queryTokens(' Желчный  пузырь! '), ['желчный', 'пузырь']);
      expect(queryTokens('12-перстная'), ['12', 'перстная']);
    });
  });
}
