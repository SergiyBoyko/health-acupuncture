import 'package:acupoints/data/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_content.dart';

void main() {
  group('TextNormalizer.text', () {
    test('регістр, ё, пунктуація', () {
      expect(TextNormalizer.text('  ПЕРЕДНИЙ Родничок. '), 'передний родничок');
      expect(TextNormalizer.text('Ещё, отёк'), 'еще отек');
      expect(TextNormalizer.text('12-перстная (кишка)'), '12 перстная кишка');
    });

    test('порожній і лише з пунктуації', () {
      expect(TextNormalizer.text(''), '');
      expect(TextNormalizer.text(' .,- '), '');
    });
  });

  group('TextNormalizer.code', () {
    test('кирилиця замість латиниці', () {
      expect(TextNormalizer.code('12м'), TextNormalizer.code('12M'));
      expect(TextNormalizer.code('2в'), TextNormalizer.code('2B'));
      expect(TextNormalizer.code('Х'), TextNormalizer.code('X'));
      expect(TextNormalizer.code('Е'), TextNormalizer.code('E'));
      expect(TextNormalizer.code('с1'), TextNormalizer.code('S1'));
    });

    test('дробовий код', () {
      expect(TextNormalizer.code('49 1/2'), TextNormalizer.code('49½'));
      expect(TextNormalizer.code('49,1/2'), TextNormalizer.code('49½'));
    });

    test('пробіли й регістр', () {
      expect(TextNormalizer.code(' jb 10 '), TextNormalizer.code('JB10'));
    });
  });

  group('comparePointCodes', () {
    test('числа порівнюються як числа, а не як рядки', () {
      final codes = ['10B', '9M', '2B', '1M', '1B', '12M', '4', '2M'];
      expect(codes..sort(comparePointCodes), [
        '1B',
        '1M',
        '2B',
        '2M',
        '4',
        '9M',
        '10B',
        '12M',
      ]);
    });

    test('буквені коди після числових і за номером', () {
      final codes = ['X', 'JB10', 'S1', '98', 'JB8', 'E', 'JB9', 'S3'];
      expect(codes..sort(comparePointCodes), [
        '98',
        'E',
        'JB8',
        'JB9',
        'JB10',
        'S1',
        'S3',
        'X',
      ]);
    });

    test('дробовий код одразу після цілого', () {
      final codes = ['50', '49½', '49', '48'];
      expect(codes..sort(comparePointCodes), ['48', '49', '49½', '50']);
    });

    test('порядок усіх кодів книги детермінований і без дублікатів', () {
      final codes = loadTestContent().points.map((p) => p.code).toList();
      final sorted = [...codes]..sort(comparePointCodes);
      final reversed = [...codes.reversed]..sort(comparePointCodes);
      expect(sorted, reversed);
      expect(sorted.first, '1B');
      expect(sorted.last, 'X');
    });
  });
}
