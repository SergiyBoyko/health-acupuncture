import 'package:acupoints/core/widgets/empty_state.dart';
import 'package:acupoints/core/widgets/paper_image.dart';
import 'package:acupoints/core/widgets/point_list_tile.dart';
import 'package:acupoints/features/body/body_screen.dart';
import 'package:acupoints/features/body/segment_card.dart';
import 'package:acupoints/features/body/segment_screen.dart';
import 'package:acupoints/features/point/point_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_router_app.dart';

/// Коди точок у рядках, які зараз побудовані, згори вниз.
List<String> shownCodes(WidgetTester tester) => tester
    .widgetList<PointListTile>(find.byType(PointListTile))
    .map((tile) => tile.point.code)
    .toList();

Finder galleryImages() => find.descendant(
  of: find.byWidgetPredicate(
    (w) => w is ListView && w.scrollDirection == Axis.horizontal,
  ),
  matching: find.byType(PaperImage),
);

void main() {
  group('Тіло', () {
    testWidgets('показує п\'ять частин тіла з кількістю точок', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body');

      expect(find.byType(SegmentCard), findsNWidgets(5));
      expect(find.text('Голова'), findsOneWidget);
      expect(find.text('36 точок · стор. 4–8'), findsOneWidget);
      expect(find.text('6 точок · стор. 9–10'), findsOneWidget);
      expect(find.text('37 точок · стор. 10–14'), findsOneWidget);
      expect(find.text('15 точок · стор. 15–16'), findsOneWidget);
      expect(find.text('25 точок · стор. 17–20'), findsOneWidget);
    });

    testWidgets('кожна картка має ілюстрацію, зокрема «Шия» без схем', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body');

      for (final card in tester.widgetList<SegmentCard>(
        find.byType(SegmentCard),
      )) {
        expect(card.cover, isNotNull, reason: card.segment.id);
      }
    });

    testWidgets('дотик відкриває сегмент', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body');

      await tester.tap(find.text('Спина'));
      await tester.pumpAndSettle();

      expect(find.byType(SegmentScreen).hitTestable(), findsOneWidget);
      expect(shownCodes(tester).first, '50');
    });

    testWidgets('вміщається на вузькому екрані зі шрифтом 200 %', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        initialLocation: '/body',
        size: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(BodyScreen), findsOneWidget);
    });
  });

  group('Сегмент', () {
    testWidgets('показує зведені схеми і точки в порядку книги', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/golova');

      expect(find.text('Зведені схеми'), findsOneWidget);
      expect(galleryImages(), findsWidgets);
      expect(shownCodes(tester).take(3), ['2M', '35', '5M']);
    });

    testWidgets('сегмент без зведених схем не показує порожню стрічку', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/shyya');

      expect(find.text('Зведені схеми'), findsNothing);
      expect(galleryImages(), findsNothing);
      expect(shownCodes(tester), ['48', '5B', '15B', '12B', '15M', '13B']);
    });

    testWidgets('рядок має мініатюру і позначку соматичної точки', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/shyya');

      final tiles = tester
          .widgetList<PointListTile>(find.byType(PointListTile))
          .toList();
      expect(tiles.every((t) => t.figure != null), isTrue);
      // 5B, 12B, 15M і 13B — соматичні.
      expect(find.text('Соматична'), findsNWidgets(4));
    });

    testWidgets('перемикач упорядковує за кодом і назад', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/shyya');

      await tester.tap(find.text('За кодом'));
      await tester.pumpAndSettle();
      expect(shownCodes(tester), ['5B', '12B', '13B', '15B', '15M', '48']);

      await tester.tap(find.text('Як у книзі'));
      await tester.pumpAndSettle();
      expect(shownCodes(tester), ['48', '5B', '15B', '12B', '15M', '13B']);
    });

    testWidgets('фільтр за початком коду', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/golova');

      await tester.enterText(find.byType(TextField), 'jb');
      await tester.pumpAndSettle();

      expect(shownCodes(tester), ['JB8', 'JB9', 'JB10']);
    });

    testWidgets('фільтр приймає кирилицю в коді', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/golova');

      await tester.enterText(find.byType(TextField), '12м');
      await tester.pumpAndSettle();

      expect(shownCodes(tester), ['12M']);
    });

    testWidgets('фільтр за словом у заголовку, без урахування регістру', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/golova');

      await tester.enterText(find.byType(TextField), 'РОДНИЧОК');
      await tester.pumpAndSettle();

      expect(shownCodes(tester), ['2M', '9M']);
    });

    testWidgets('фільтр і порядок за кодом працюють разом', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/golova');

      await tester.enterText(find.byType(TextField), 'jb');
      await tester.pumpAndSettle();
      await tester.tap(find.text('За кодом'));
      await tester.pumpAndSettle();

      expect(shownCodes(tester), ['JB8', 'JB9', 'JB10']);
    });

    testWidgets('немає збігів: порожній стан і очищення фільтра', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/shyya');

      await tester.enterText(find.byType(TextField), 'щось');
      await tester.pumpAndSettle();

      expect(find.byType(PointListTile), findsNothing);
      expect(find.text('Нічого не знайдено'), findsOneWidget);
      expect(
        find.text('У цьому розділі немає точок за запитом «щось».'),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.text('Очистити фільтр'),
        ),
      );
      await tester.pumpAndSettle();

      expect(shownCodes(tester), hasLength(6));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('кнопка очищення з\'являється лише з текстом', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/shyya');
      expect(find.byTooltip('Очистити фільтр'), findsNothing);

      await tester.enterText(find.byType(TextField), '15');
      await tester.pumpAndSettle();
      expect(shownCodes(tester), ['15B', '15M']);

      await tester.tap(find.byTooltip('Очистити фільтр'));
      await tester.pumpAndSettle();
      expect(shownCodes(tester), hasLength(6));
    });

    testWidgets('дотик до рядка відкриває точку', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/shyya');

      await tester.tap(find.text('5B'));
      await tester.pumpAndSettle();

      expect(tester.widget<PointScreen>(find.byType(PointScreen)).code, '5B');
    });

    testWidgets('вміщається на вузькому екрані зі шрифтом 200 %', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        initialLocation: '/body/segment/golova',
        size: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SegmentScreen), findsOneWidget);
    });
  });
}
