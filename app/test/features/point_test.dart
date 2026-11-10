import 'package:acupoints/core/theme/app_colors.dart';
import 'package:acupoints/core/widgets/code_badge.dart';
import 'package:acupoints/core/widgets/paper_image.dart';
import 'package:acupoints/core/widgets/point_list_tile.dart';
import 'package:acupoints/core/widgets/rich_content_text.dart';
import 'package:acupoints/core/widgets/section_header.dart';
import 'package:acupoints/core/widgets/somatic_tag.dart';
import 'package:acupoints/features/body/segment_screen.dart';
import 'package:acupoints/features/point/point_screen.dart';
import 'package:acupoints/features/point/widgets/note_block.dart';
import 'package:acupoints/features/point/widgets/point_gallery.dart';
import 'package:acupoints/features/point/widgets/symptom_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/pump_router_app.dart';

/// Код точки на верхньому (видимому) екрані.
String shownPoint(WidgetTester tester) => tester
    .widget<PointScreen>(find.byType(PointScreen).hitTestable().last)
    .code;

/// Посилання-код усередині абзацу опису.
FinderBase<TextRangeContext> linkIn(Finder paragraph, String code) =>
    find.textRange.ofSubstring(code, descendentOf: paragraph);

/// Абзац опису, що містить [text].
Finder paragraphWith(String text) => find.ancestor(
  of: find.textContaining(text),
  matching: find.byType(RichContentText),
);

Finder sectionHeader(String title) => find.widgetWithText(SectionHeader, title);

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('звичайна точка (12M)', () {
    late GoRouter router;

    Future<void> open(WidgetTester tester) async {
      router = await tester.pumpRouterApp(initialLocation: '/body/point/12M');
    }

    testWidgets('малюнок зверху, потім код, заголовок і сегмент', (
      tester,
    ) async {
      await open(tester);

      final gallery = tester.getTopLeft(find.byType(PointGallery)).dy;
      final badge = tester.getTopLeft(find.byType(CodeBadge).first).dy;
      expect(gallery, lessThan(badge));

      expect(find.text('12M'), findsOneWidget);
      expect(find.text('Атеросклероз, сердце, мышцы, вены.'), findsOneWidget);
      expect(find.text('Голова · стор. 7'), findsOneWidget);
      expect(find.byType(SomaticTag), findsNothing);
    });

    testWidgets('галерея: спершу малюнок біля опису, лічильник, гортання', (
      tester,
    ) async {
      await open(tester);

      final gallery = tester.widget<PointGallery>(find.byType(PointGallery));
      expect(gallery.figures, hasLength(3));
      expect(find.text('1 з 3'), findsOneWidget);
      expect(find.textContaining('малюнок біля опису, стор. 7'), findsOne);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('2 з 3'), findsOneWidget);
      expect(find.textContaining('зведена схема, стор. 4'), findsOne);
    });

    testWidgets('опис показано повністю, код у тексті веде до точки', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Опис'), findsOneWidget);
      expect(find.textContaining('ниже точки "9B"'), findsOneWidget);
      expect(find.textContaining('Примечание: при сердечных'), findsOneWidget);

      await scrollTo(tester, find.textContaining('ниже точки "9B"'));
      await tester.tapOnText(linkIn(find.byType(RichContentText).first, '9B'));
      await tester.pumpAndSettle();

      expect(shownPoint(tester), '9B');
    });

    testWidgets('пов\'язані точки, симптоми, рукописна нотатка', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Пов\'язані точки'), findsOneWidget);
      expect(
        tester
            .widgetList<PointListTile>(find.byType(PointListTile))
            .map((t) => t.point.code),
        ['9B'],
      );

      expect(sectionHeader('Симптоми'), findsOneWidget);
      expect(find.text('Атеросклероз'), findsOneWidget);

      final note = tester.widget<NoteBlock>(find.byType(NoteBlock));
      expect(note.title, 'Рукописні нотатки власника');
      expect(note.background, AppColors.light.noteContainer);
      expect(find.textContaining('шок - S1, 12M'), findsOneWidget);
    });

    testWidgets('довгий список симптомів згорнуто до «Ще N»', (tester) async {
      await open(tester);

      final chips = tester.widget<SymptomChips>(find.byType(SymptomChips));
      final total = chips.symptoms.length;
      expect(total, greaterThan(9));
      // Вісім симптомів і кнопка «Ще N».
      expect(find.byType(ActionChip), findsNWidgets(9));

      final more = find.text('Ще ${total - 8}');
      await scrollTo(tester, more);
      await tester.tap(more);
      await tester.pumpAndSettle();

      expect(find.byType(ActionChip), findsNWidgets(total));
      expect(more, findsNothing);
    });

    testWidgets('перехід до сусідніх точок не нарощує стек', (tester) async {
      await open(tester);

      // У книзі 12M стоїть між 9B і 11B.
      await scrollTo(tester, find.byTooltip('Наступна точка'));
      await tester.tap(find.byTooltip('Наступна точка'));
      await tester.pumpAndSettle();
      expect(shownPoint(tester), '11B');
      expect(find.byType(PointScreen), findsOneWidget);

      await scrollTo(tester, find.byTooltip('Попередня точка'));
      await tester.tap(find.byTooltip('Попередня точка'));
      await tester.pumpAndSettle();
      expect(shownPoint(tester), '12M');
      expect(find.byType(PointScreen), findsOneWidget);
      expect(router.state.uri.path, '/body/point/12M');
    });

    testWidgets('сегмент відкривається з хлібної крихти', (tester) async {
      await open(tester);

      await tester.tap(find.text('Голова · стор. 7'));
      await tester.pumpAndSettle();

      expect(find.byType(SegmentScreen).hitTestable(), findsOneWidget);
    });
  });

  group('точка зі сторонами', () {
    testWidgets('S1: окремі підрозділи для правої та лівої', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/S1');

      final right = find.textContaining('S1 (правая).');
      final left = find.textContaining('S1 (левая).');
      expect(right, findsOneWidget);
      expect(left, findsOneWidget);
      expect(tester.getTopLeft(right).dy, lessThan(tester.getTopLeft(left).dy));
      expect(find.textContaining('Для правой грудной железы'), findsOneWidget);
      expect(find.textContaining('Для левой грудной железы'), findsOneWidget);
      // Власний код у тексті не є посиланням: «S1 правая» лишається текстом.
      expect(paragraphWith('аналогично точке "S1 правая"'), findsOneWidget);
    });

    testWidgets('32: два заголовки сторін над спільним абзацом', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/32');

      expect(find.textContaining('32. Левая.'), findsOneWidget);
      expect(find.textContaining('32. Правая.'), findsOneWidget);
      expect(find.textContaining('На правой стороне точка "32"'), findsOne);
    });

    testWidgets('49: посилання в другому абзаці веде до точки', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/49');

      final paragraph = paragraphWith('"14B"');
      await scrollTo(tester, paragraph);
      await tester.tapOnText(linkIn(paragraph, '14B'));
      await tester.pumpAndSettle();

      expect(shownPoint(tester), '14B');
    });
  });

  group('порожні блоки не показуються', () {
    testWidgets('67: без симптомів, пов\'язаних точок і нотаток', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/67');

      expect(find.text('67'), findsOneWidget);
      expect(find.text('Опис'), findsOneWidget);
      expect(sectionHeader('Симптоми'), findsNothing);
      expect(find.byType(SymptomChips), findsNothing);
      expect(sectionHeader('Пов\'язані точки'), findsNothing);
      expect(find.byType(NoteBlock), findsNothing);
    });

    testWidgets('перша точка сегмента не має кнопки «попередня»', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/2M');

      expect(find.byTooltip('Попередня точка'), findsNothing);
      expect(find.byTooltip('Наступна точка'), findsOneWidget);
    });

    testWidgets('остання точка сегмента не має кнопки «наступна»', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/80');

      expect(find.byTooltip('Попередня точка'), findsOneWidget);
      expect(find.byTooltip('Наступна точка'), findsNothing);
    });
  });

  group('особливі точки', () {
    testWidgets('X: заголовок із транскрипції та примітка про нього', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/X');

      expect(find.text('X'), findsOneWidget);
      expect(find.byType(SomaticTag), findsOneWidget);

      final blocks = tester
          .widgetList<NoteBlock>(find.byType(NoteBlock))
          .toList();
      expect(blocks.map((b) => b.title), [
        'Рукописні нотатки власника',
        'Примітки транскрипції',
      ]);
      expect(blocks.first.background, isNot(blocks.last.background));
      expect(find.textContaining('окремого заголовка для «X» немає'), findsOne);
    });

    testWidgets('48: виправлений код пояснено в примітці', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/48');

      expect(find.textContaining('від руки виправлено на «48»'), findsOne);
    });

    testWidgets('49½: дробовий код', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/49-half');

      expect(find.text('49½'), findsOneWidget);
      expect(find.byType(PointGallery), findsOneWidget);
    });
  });

  group('вигляд', () {
    testWidgets('малюнки на паперовій підкладці і в темній темі', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        initialLocation: '/body/point/12M',
        brightness: Brightness.dark,
      );

      final box = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(PaperImage),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(box.color, AppColors.paperColor);
      expect(
        tester.widget<NoteBlock>(find.byType(NoteBlock)).background,
        AppColors.dark.noteContainer,
      );
    });

    testWidgets('вміщається на вузькому екрані зі шрифтом 200 %', (
      tester,
    ) async {
      for (final code in ['12M', 'S3', '83', '49']) {
        await tester.pumpRouterApp(
          initialLocation: '/body/point/$code',
          size: const Size(320, 640),
          textScale: 2,
        );
        expect(tester.takeException(), isNull, reason: code);
        expect(find.byType(PointScreen), findsOneWidget, reason: code);
      }
    });
  });
}
