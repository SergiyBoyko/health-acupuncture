import 'package:acupoints/core/widgets/rich_content_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/test_content.dart';

void main() {
  group('parseRichContent', () {
    test('текст без посилань', () {
      expect(parseRichContent('Лечит мозг.'), [
        const RichSegment.text('Лечит мозг.'),
      ]);
    });

    test('посилання в середині речення', () {
      expect(parseRichContent('ниже точки "[[9B]]" и касается'), [
        const RichSegment.text('ниже точки "'),
        const RichSegment.link('9B', '9B'),
        const RichSegment.text('" и касается'),
      ]);
    });

    test('посилання з підписом', () {
      expect(parseRichContent('точке "[[S1|S1 правая]]".'), [
        const RichSegment.text('точке "'),
        const RichSegment.link('S1', 'S1 правая'),
        const RichSegment.text('".'),
      ]);
    });

    test('кілька посилань, на початку й у кінці', () {
      expect(parseRichContent('[[38]] и [[54]]'), [
        const RichSegment.link('38', '38'),
        const RichSegment.text(' и '),
        const RichSegment.link('54', '54'),
      ]);
    });

    test('порожній рядок і незакрита розмітка', () {
      expect(parseRichContent(''), isEmpty);
      expect(parseRichContent('точка [[12M'), [
        const RichSegment.text('точка [[12M'),
      ]);
    });

    test('усі посилання в книзі ведуть на наявні точки', () {
      final repo = loadTestContent();
      var links = 0;
      for (final point in repo.points) {
        for (final section in point.sections) {
          for (final paragraph in section.paragraphs) {
            expect(paragraph, isNot(contains(']]]')), reason: point.code);
            for (final segment in parseRichContent(paragraph)) {
              if (!segment.isLink) {
                expect(segment.text, isNot(contains('[[')), reason: point.code);
                continue;
              }
              links++;
              expect(repo.point(segment.code!), isNotNull, reason: point.code);
            }
          }
        }
      }
      expect(links, greaterThan(40));
    });
  });

  group('RichContentText', () {
    testWidgets('дотик до коду повідомляє код, а не підпис', (tester) async {
      final tapped = <String>[];
      await tester.pumpApp(
        RichContentText(
          'Аналогично точке "[[S1|S1 правая]]" и ниже "[[9B]]".',
          onPointTap: tapped.add,
        ),
      );

      expect(
        find.text('Аналогично точке "S1 правая" и ниже "9B".'),
        findsOneWidget,
      );

      await tester.tapOnText(find.textRange.ofSubstring('S1 правая'));
      await tester.tapOnText(find.textRange.ofSubstring('9B'));
      expect(tapped, ['S1', '9B']);
    });

    testWidgets('оновлюється, коли змінюється текст', (tester) async {
      final tapped = <String>[];
      await tester.pumpApp(
        RichContentText('точка "[[2B]]"', onPointTap: tapped.add),
      );
      await tester.pumpApp(
        RichContentText('точка "[[5M]]"', onPointTap: tapped.add),
      );

      await tester.tapOnText(find.textRange.ofSubstring('5M'));
      expect(tapped, ['5M']);
    });
  });
}
