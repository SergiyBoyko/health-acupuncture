import 'package:acupoints/core/widgets/code_badge.dart';
import 'package:acupoints/core/widgets/point_list_tile.dart';
import 'package:acupoints/features/glossary/glossary_screen.dart';
import 'package:acupoints/features/point/point_screen.dart';
import 'package:acupoints/features/point/widgets/note_block.dart';
import 'package:acupoints/features/shell/not_found_screen.dart';
import 'package:acupoints/features/symptoms/symptom_entry_tile.dart';
import 'package:acupoints/features/symptoms/symptom_group_screen.dart';
import 'package:acupoints/features/symptoms/symptom_index.dart';
import 'package:acupoints/features/symptoms/symptom_screen.dart';
import 'package:acupoints/features/symptoms/symptoms_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_router_app.dart';
import '../support/test_content.dart';

List<String> shownEntries(WidgetTester tester) => tester
    .widgetList<SymptomEntryTile>(find.byType(SymptomEntryTile))
    .map((tile) => tile.entry.title)
    .toList();

List<PointListTile> pointTiles(WidgetTester tester) => tester
    .widgetList<PointListTile>(
      find.descendant(
        of: find.byType(SymptomScreen),
        matching: find.byType(PointListTile),
      ),
    )
    .toList();

String shownPoint(WidgetTester tester) => tester
    .widget<PointScreen>(find.byType(PointScreen).hitTestable().last)
    .code;

void main() {
  group('упорядкування покажчика', () {
    final repo = loadTestContent();

    test('верхній рівень: усі симптоми без груп плюс чотири групи', () {
      final entries = topLevelEntries(repo);
      expect(entries.where((e) => e.isGroup), hasLength(4));
      expect(entries, hasLength(repo.topLevelSymptoms.length + 4));
    });

    test('алфавітний порядок без урахування регістру', () {
      final keys = topLevelEntries(repo).map((e) => e.sortKey).toList();
      expect(keys, [...keys]..sort());
      // Рукописне «алергия» стоїть серед друкованих на «А».
      final titles = topLevelEntries(repo).map((e) => e.title).toList();
      expect(titles.indexOf('Алергия'), lessThan(titles.indexOf('Амнезия')));
    });

    test('літери розділів, цифри — під «#»', () {
      final entries = topLevelEntries(repo);
      expect(entries.first.title, '12-перстная кишка');
      expect(entries.first.letter, '#');
      expect(entries.firstWhere((e) => e.title == 'Желчные камни').letter, 'Ж');
    });

    test('підтерміни групи за алфавітом', () {
      final pain = groupEntries(repo, 'bol');
      expect(pain, hasLength(19));
      final keys = pain.map((e) => e.sortKey).toList();
      expect(keys, [...keys]..sort());
    });

    test('фільтр шукає і в підтермінах, показуючи назву групи', () {
      final titles = filterEntries(repo, 'катаракта').map((e) => e.title);
      expect(titles, ['Глаза: катаракта']);
    });

    test('фільтр знаходить групу за назвою', () {
      final found = filterEntries(repo, 'сердц');
      expect(found.where((e) => e.isGroup).map((e) => e.title), ['Сердце']);
      expect(found.map((e) => e.title), contains('Сердце: ангина'));
    });
  });

  group('Симптоми', () {
    testWidgets('список за алфавітом з кількістю точок', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms');

      final entries = shownEntries(tester);
      expect(entries.take(3), ['12-перстная кишка', 'Аденоиды', 'Алергия']);
      expect(
        find.descendant(
          of: find.widgetWithText(SymptomEntryTile, 'Аденоиды'),
          matching: find.text('2 точки'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('група показує кількість підтем і відкриває їх', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms');

      final group = find.widgetWithText(SymptomEntryTile, 'Боль');
      await tester.ensureVisible(group);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: group, matching: find.text('19 підтем')),
        findsOneWidget,
      );

      await tester.tap(group);
      await tester.pumpAndSettle();

      expect(find.byType(SymptomGroupScreen).hitTestable(), findsOneWidget);
      expect(shownEntries(tester).first, 'Бедра');
    });

    testWidgets('фільтр звужує список і ховає стрічку літер', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms');
      expect(find.bySemanticsLabel('Перейти до літери Б'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'желч');
      await tester.pumpAndSettle();

      expect(shownEntries(tester), [
        'Желчные камни',
        'Желчный проток',
        'Желчный пузырь',
        'Разлитие желчи',
      ]);
      expect(find.bySemanticsLabel('Перейти до літери Б'), findsNothing);
    });

    testWidgets('немає збігів: порожній стан і очищення', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms');

      await tester.enterText(find.byType(TextField), 'ййй');
      await tester.pumpAndSettle();
      expect(
        find.text('У покажчику немає записів за запитом «ййй».'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Очистити фільтр'));
      await tester.pumpAndSettle();
      expect(shownEntries(tester).first, '12-перстная кишка');
    });

    testWidgets('перехід за літерою прокручує до розділу', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms');
      final target = find.widgetWithText(SymptomEntryTile, 'Сахар');
      expect(target.hitTestable(), findsNothing);

      final letter = find.bySemanticsLabel('Перейти до літери С');
      await tester.dragUntilVisible(
        letter,
        find.byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.horizontal,
        ),
        const Offset(-200, 0),
      );
      await tester.tap(letter);
      await tester.pumpAndSettle();

      expect(target.hitTestable(), findsOneWidget);
    });

    testWidgets('рукописний рядок позначено', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms');

      await tester.enterText(find.byType(TextField), 'шок');
      await tester.pumpAndSettle();

      expect(shownEntries(tester), ['Шок']);
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
    });

    testWidgets('вміщається на вузькому екрані зі шрифтом 200 %', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        initialLocation: '/symptoms',
        size: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SymptomsScreen), findsOneWidget);
    });
  });

  group('Симптом', () {
    testWidgets('точки в порядку джерела, сторона, «або»', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/symptoms/symptom/appenditsit',
      );

      expect(find.text('Аппендицит'), findsOneWidget);
      expect(find.text('3 точки'), findsOneWidget);
      final tiles = pointTiles(tester);
      expect(tiles.map((t) => t.point.code), ['5B', '77', '65']);
      expect(tiles[0].subtitle, 'права сторона');
      expect(tiles[1].subtitle, 'права сторона');
      expect(tiles[2].subtitle, isNull);
      expect(find.text('або'), findsOneWidget);
      expect(find.text('Аппендицит-5Bправая или 77правая,65'), findsOneWidget);
    });

    testWidgets('точки, які натискають разом, згруповано', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms/symptom/ataksiya');

      expect(pointTiles(tester).map((t) => t.point.code), [
        '1M',
        '89',
        '56',
        '90',
        '3M',
        '79',
      ]);
      expect(find.text('Натискати разом'), findsOneWidget);
    });

    testWidgets('парні точки MB', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/symptoms/symptom/bolezn-addisona',
      );

      final tiles = pointTiles(tester);
      expect(tiles.map((t) => t.point.code), [
        '46',
        '10M',
        '10B',
        '11M',
        '11B',
      ]);
      expect(tiles[1].subtitle, 'парні точки');
      expect(tiles[0].subtitle, isNull);
    });

    testWidgets('уточнення з джерела: підточки і примітка', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/symptoms/symptom/anevrizma',
      );
      expect(pointTiles(tester).map((t) => t.subtitle), [
        'ліва сторона',
        '(3 и 4)',
      ]);

      await tester.pumpRouterApp(initialLocation: '/symptoms/symptom/astma');
      expect(
        pointTiles(tester).last.subtitle,
        'ліва сторона · (на коронарной точке)',
      );
    });

    testWidgets('код без описаної точки неактивний і пояснений', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms/symptom/kolit');

      final badge = tester.widget<CodeBadge>(
        find.widgetWithText(CodeBadge, '11E'),
      );
      expect(badge.enabled, isFalse);
      expect(find.text('Точки з таким кодом у книзі немає'), findsOneWidget);
      expect(pointTiles(tester).map((t) => t.point.code), [
        '72',
        '91',
        '9B',
        '40',
      ]);
    });

    testWidgets('текст із джерела без коду показано як є', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/symptoms/symptom/krovotechenie',
      );

      expect(pointTiles(tester).map((t) => t.point.code), ['2B']);
      expect(find.text('положительные ионы'), findsOneWidget);
    });

    testWidgets('об\'єднаний запис зберігає обидва рядки джерела', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        initialLocation: '/symptoms/symptom/polovye-zhelezy',
      );

      expect(find.text('4 точки'), findsOneWidget);
      expect(find.text('Половые железы-73'), findsOneWidget);
      expect(find.text('Половые железы-26,56,83'), findsOneWidget);
    });

    testWidgets('підтермін показує назву групи', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/symptoms/symptom/glaza--katarakta',
      );

      expect(find.text('Глаза'), findsOneWidget);
      expect(find.text('катаракта'), findsOneWidget);
    });

    testWidgets('рукописний запис позначено', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/symptoms/symptom/shok--hand',
      );

      expect(
        tester.widget<NoteBlock>(find.byType(NoteBlock)).title,
        'Дописано від руки',
      );
      expect(pointTiles(tester).map((t) => t.point.code), ['S1', '12M']);
    });

    testWidgets('запис без точок', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/symptoms/symptom/pislya-insult--hand',
      );

      expect(
        find.text('Для цього запису в книзі не вказано точок.'),
        findsOneWidget,
      );
      expect(pointTiles(tester), isEmpty);
    });

    testWidgets('дотик до точки відкриває її в тій самій вкладці', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        initialLocation: '/symptoms/symptom/appenditsit',
      );

      await tester.tap(find.text('65'));
      await tester.pumpAndSettle();

      expect(shownPoint(tester), '65');
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
    });

    testWidgets('невідомий симптом і невідома група', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms/symptom/nope');
      expect(find.byType(NotFoundScreen), findsOneWidget);

      await tester.pumpRouterApp(
        initialLocation: '/symptoms/symptom-group/nope',
      );
      expect(find.byType(NotFoundScreen), findsOneWidget);
    });

    testWidgets('вміщається на вузькому екрані зі шрифтом 200 %', (
      tester,
    ) async {
      for (final id in ['ataksiya', 'serdtse--stopa', 'kolit']) {
        await tester.pumpRouterApp(
          initialLocation: '/symptoms/symptom/$id',
          size: const Size(320, 640),
          textScale: 2,
        );
        expect(tester.takeException(), isNull, reason: id);
      }
    });
  });

  group('зі сторінки точки', () {
    testWidgets('чип симптому відкриває симптом', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/63');

      final chip = find.widgetWithText(ActionChip, 'Амнезия');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(find.byType(SymptomScreen).hitTestable(), findsOneWidget);
      expect(pointTiles(tester).map((t) => t.point.code), ['63']);
      // Лишаємось у вкладці «Тіло».
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
    });
  });

  group('легенда', () {
    testWidgets('показує позначення і соматичні точки', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms');

      await tester.tap(find.byTooltip('Позначення'));
      await tester.pumpAndSettle();

      expect(find.text('Позначення в покажчику'), findsOneWidget);
      expect(find.text('челюстная кость'), findsOneWidget);
      expect(find.text('парные точки'), findsOneWidget);
      expect(find.text('Соматичні точки'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(CodeBadge),
        ),
        findsNWidgets(15),
      );
    });

    testWidgets('соматична точка відкривається з легенди', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms');
      await tester.tap(find.byTooltip('Позначення'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CodeBadge, '13B'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(shownPoint(tester), '13B');
    });
  });

  group('Словник', () {
    testWidgets('відкривається з покажчика, терміни за алфавітом', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms');

      await tester.tap(find.byTooltip('Словник'));
      await tester.pumpAndSettle();

      expect(find.byType(GlossaryScreen).hitTestable(), findsOneWidget);
      final titles = tester
          .widgetList<ExpansionTile>(find.byType(ExpansionTile))
          .map((t) => (t.title as Text).data!)
          .toList();
      expect(titles.take(2), [
        'Адреналин (эпинефрин)',
        'Анасарка (отек подкожной клетчатки)',
      ]);
    });

    testWidgets('визначення розгортається на місці', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms/glossary');
      const definition = 'разветвление.';
      expect(find.text(definition), findsNothing);

      final term = find.text('Бифуркация');
      await tester.dragUntilVisible(
        term,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.tap(term);
      await tester.pumpAndSettle();

      expect(find.text(definition), findsOneWidget);
    });

    testWidgets('фільтр і порожній стан', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms/glossary');

      await tester.enterText(find.byType(TextField), 'кость');
      await tester.pumpAndSettle();
      final titles = tester
          .widgetList<ExpansionTile>(find.byType(ExpansionTile))
          .map((t) => (t.title as Text).data!)
          .toList();
      expect(titles, isNotEmpty);
      expect(titles.every((t) => t.toLowerCase().contains('кость')), isTrue);

      await tester.enterText(find.byType(TextField), 'ййй');
      await tester.pumpAndSettle();
      expect(
        find.text('У словнику немає термінів за запитом «ййй».'),
        findsOneWidget,
      );
    });
  });
}
