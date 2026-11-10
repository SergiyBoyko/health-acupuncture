import 'dart:convert';

import 'package:acupoints/core/widgets/code_badge.dart';
import 'package:acupoints/core/widgets/point_list_tile.dart';
import 'package:acupoints/data/user/user_store.dart';
import 'package:acupoints/features/body/body_screen.dart';
import 'package:acupoints/features/body/segment_screen.dart';
import 'package:acupoints/features/glossary/glossary_screen.dart';
import 'package:acupoints/features/point/point_screen.dart';
import 'package:acupoints/features/saved/saved_screen.dart';
import 'package:acupoints/features/search/search_screen.dart';
import 'package:acupoints/features/symptoms/symptom_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/pump_router_app.dart';

final DateTime now = DateTime(2026, 11, 10, 15, 30);

String view(String type, String id, DateTime at) =>
    jsonEncode({'type': type, 'id': id, 'at': at.toIso8601String()});

Map<String, Object> stored({
  List<String> searches = const [],
  List<(String, String, DateTime)> views = const [],
  List<String> favorites = const [],
}) => {
  if (searches.isNotEmpty)
    UserStore.searchKey: jsonEncode([
      for (final q in searches) {'query': q, 'at': now.toIso8601String()},
    ]),
  if (views.isNotEmpty)
    UserStore.viewKey:
        '[${views.map((v) => view(v.$1, v.$2, v.$3)).join(',')}]',
  if (favorites.isNotEmpty)
    UserStore.favoritesKey: jsonEncode([
      for (final c in favorites) {'code': c, 'at': now.toIso8601String()},
    ]),
};

Future<UserStore> store() async =>
    UserStore(await SharedPreferences.getInstance());

Finder tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Finder savedTab(String label) => find.descendant(
  of: find.byType(SegmentedButton<SavedTab>),
  matching: find.text(label),
);

Finder searchField() => find.descendant(
  of: find.byType(SearchScreen),
  matching: find.byType(TextField),
);

List<String> favoriteCodes(WidgetTester tester) => tester
    .widgetList<PointListTile>(
      find.descendant(
        of: find.byType(SavedScreen),
        matching: find.byType(PointListTile),
      ),
    )
    .map((t) => t.point.code)
    .toList();

void main() {
  group('обране', () {
    testWidgets('зірочка на сторінці точки додає і прибирає', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/12M');

      await tester.tap(find.byTooltip('Додати в обране'));
      await tester.pump();

      expect(find.byTooltip('Прибрати з обраного'), findsOneWidget);
      expect(find.text('Точку 12M додано в обране'), findsOneWidget);
      expect((await store()).loadFavorites().single.code, '12M');

      await tester.tap(find.byTooltip('Прибрати з обраного'));
      await tester.pump();

      expect(find.byTooltip('Додати в обране'), findsOneWidget);
      expect(find.text('Точку 12M прибрано з обраного'), findsOneWidget);
      expect((await store()).loadFavorites(), isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('довгий дотик у списку сегмента і позначка в рядку', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/shyya');
      expect(find.byIcon(Icons.star), findsNothing);

      await tester.longPress(find.text('5B'));
      await tester.pump();

      final tile = tester.widget<PointListTile>(
        find.widgetWithText(PointListTile, '5B'),
      );
      expect(tile.isFavorite, isTrue);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect((await store()).loadFavorites().single.code, '5B');
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('порожній стан пояснює, як додати, і веде до тіла', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/saved');

      expect(find.text('Збережіть першу точку'), findsOneWidget);
      await tester.tap(find.text('Відкрити частини тіла'));
      await tester.pumpAndSettle();

      expect(find.byType(BodyScreen).hitTestable(), findsOneWidget);
    });

    testWidgets('список: новіші зверху, дотик відкриває точку', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/saved',
        stored: stored(favorites: ['2B', '12M', '49½']),
      );

      expect(favoriteCodes(tester), ['2B', '12M', '49½']);

      await tester.tap(find.widgetWithText(CodeBadge, '12M'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PointScreen>(find.byType(PointScreen).hitTestable()).code,
        '12M',
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
    });

    testWidgets('зірочка в списку прибирає точку', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/saved',
        stored: stored(favorites: ['2B', '12M']),
      );

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(PointListTile, '2B'),
          matching: find.byTooltip('Прибрати з обраного'),
        ),
      );
      await tester.pump();

      expect(favoriteCodes(tester), ['12M']);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('обране з неіснуючим кодом пропускається', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/saved',
        stored: stored(favorites: ['999', '12M']),
      );

      expect(favoriteCodes(tester), ['12M']);
    });
  });

  group('історія переглядів', () {
    testWidgets('точка, сегмент і симптом записуються при відкритті', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/shyya');
      await tester.tap(find.text('5B'));
      await tester.pumpAndSettle();
      final chip = find.widgetWithText(ActionChip, 'Аппендицит');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.byType(SymptomScreen).hitTestable(), findsOneWidget);

      final views = (await store()).loadViews();
      expect(views.map((e) => '${e.type.name}:${e.id}'), [
        'symptom:appenditsit',
        'point:5B',
        'segment:shyya',
      ]);
    });

    testWidgets('повторне відкриття піднімає запис, а не дублює', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/12M');
      await tester.pumpRouterApp(initialLocation: '/body/point/2B');
      await tester.pumpRouterApp(initialLocation: '/body/point/12M');

      expect((await store()).loadViews().map((e) => e.id), ['12M', '2B']);
    });

    testWidgets('перехід «наступна точка» теж записується', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/12M');
      final next = find.byTooltip('Наступна точка');
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();

      expect((await store()).loadViews().map((e) => e.id), ['11B', '12M']);
    });

    testWidgets('неіснуючі коди в історію не потрапляють', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/999');
      await tester.pumpRouterApp(initialLocation: '/body/segment/hvist');

      expect((await store()).loadViews(), isEmpty);
    });

    testWidgets('термін словника записується при розгортанні', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/symptoms/glossary');
      final term = find.text('Аорта');
      await tester.dragUntilVisible(
        term,
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.tap(term);
      await tester.pumpAndSettle();

      final views = (await store()).loadViews();
      expect(views.single.type.name, 'term');
      expect(views.single.id, 'Аорта');
    });

    testWidgets('екран історії: за днями, з часом і типом', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/saved?tab=history',
        now: () => now,
        stored: stored(
          views: [
            ('point', '12M', DateTime(2026, 11, 10, 14, 5)),
            ('symptom', 'glaza--katarakta', DateTime(2026, 11, 10, 9, 40)),
            ('segment', 'shyya', DateTime(2026, 11, 9, 23, 59)),
            ('term', 'Аорта', DateTime(2026, 11, 3, 8)),
          ],
        ),
      );

      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(texts, containsAllInOrder(['Сьогодні', 'Вчора', 'Раніше']));
      expect(find.text('Голова · 14:05'), findsOneWidget);
      expect(find.text('Глаза: катаракта'), findsOneWidget);
      expect(find.text('Симптом · 09:40'), findsOneWidget);
      expect(find.text('Частина тіла · 23:59'), findsOneWidget);
      expect(find.text('Термін словника · 3 лист.'), findsOneWidget);
      expect(find.widgetWithText(CodeBadge, '12M'), findsOneWidget);
    });

    testWidgets('запис відкриває відповідний екран', (tester) async {
      final data = stored(
        views: [
          ('point', '12M', now),
          ('symptom', 'kolit', now),
          ('segment', 'shyya', now),
          ('term', 'Аорта', now),
        ],
      );

      await tester.pumpRouterApp(
        initialLocation: '/saved?tab=history',
        stored: data,
      );
      await tester.tap(find.text('Шия'));
      await tester.pumpAndSettle();
      expect(find.byType(SegmentScreen).hitTestable(), findsOneWidget);

      await tester.pumpRouterApp(
        initialLocation: '/saved?tab=history',
        stored: data,
      );
      await tester.tap(find.text('Колит'));
      await tester.pumpAndSettle();
      expect(find.byType(SymptomScreen).hitTestable(), findsOneWidget);

      await tester.pumpRouterApp(
        initialLocation: '/saved?tab=history',
        stored: data,
      );
      await tester.tap(find.text('Аорта'));
      await tester.pumpAndSettle();
      expect(find.byType(GlossaryScreen).hitTestable(), findsOneWidget);
      // Словник відкрито одразу на цьому терміні, з розгорнутим визначенням.
      expect(find.textContaining('основной ствол артерий'), findsOneWidget);
    });

    testWidgets('очищення з підтвердженням; «Скасувати» нічого не змінює', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        initialLocation: '/saved?tab=history',
        stored: stored(views: [('point', '12M', now)], favorites: ['2B']),
      );

      await tester.tap(find.byTooltip('Очистити історію'));
      await tester.pumpAndSettle();
      expect(find.text('Очистити історію переглядів?'), findsOneWidget);
      await tester.tap(find.text('Скасувати'));
      await tester.pumpAndSettle();
      expect((await store()).loadViews(), hasLength(1));

      await tester.tap(find.byTooltip('Очистити історію'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Очистити'));
      await tester.pumpAndSettle();

      expect((await store()).loadViews(), isEmpty);
      expect(find.text('Історія порожня'), findsOneWidget);
      expect(find.byTooltip('Очистити історію'), findsNothing);
      // Обране лишилось.
      expect((await store()).loadFavorites().single.code, '2B');
    });

    testWidgets('кнопки очищення немає на вкладці «Обране»', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/saved',
        stored: stored(views: [('point', '12M', now)]),
      );
      expect(find.byTooltip('Очистити історію'), findsNothing);

      await tester.tap(savedTab('Історія'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Очистити історію'), findsOneWidget);
      expect(find.widgetWithText(CodeBadge, '12M'), findsOneWidget);
    });
  });

  group('історія пошуку', () {
    testWidgets('запит зберігається, коли відкрито результат', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');
      await tester.enterText(searchField(), 'jb10');
      await tester.pumpAndSettle(SearchScreen.debounce);
      // Сам набір тексту нічого не зберігає.
      expect((await store()).loadSearches(), isEmpty);

      await tester.tap(find.widgetWithText(CodeBadge, 'JB10'));
      await tester.pumpAndSettle();

      expect((await store()).loadSearches().single.query, 'jb10');
    });

    testWidgets('запит зберігається при підтвердженні з клавіатури', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');
      await tester.enterText(searchField(), 'мозг');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect((await store()).loadSearches().single.query, 'мозг');
    });

    testWidgets('під порожнім полем — останні запити; дотик повторює', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        initialLocation: '/body/search',
        stored: stored(searches: ['jb10', 'мозг']),
      );

      expect(find.text('Останні запити'), findsOneWidget);
      expect(find.text('Що шукаємо?'), findsNothing);

      await tester.tap(find.text('jb10'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(searchField()).controller!.text, 'jb10');
      expect(find.widgetWithText(CodeBadge, 'JB10'), findsOneWidget);
    });

    testWidgets('видалення одного запиту', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/body/search',
        stored: stored(searches: ['jb10', 'мозг']),
      );

      await tester.tap(find.byTooltip('Видалити запит «jb10»'));
      await tester.pumpAndSettle();

      expect(find.text('jb10'), findsNothing);
      expect(find.text('мозг'), findsOneWidget);
      expect((await store()).loadSearches().single.query, 'мозг');
    });

    testWidgets('очищення всіх запитів із підтвердженням', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/body/search',
        stored: stored(searches: ['jb10', 'мозг']),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Очистити'));
      await tester.pumpAndSettle();
      expect(find.text('Очистити останні запити?'), findsOneWidget);
      await tester.tap(find.text('Скасувати'));
      await tester.pumpAndSettle();
      expect((await store()).loadSearches(), hasLength(2));

      await tester.tap(find.widgetWithText(TextButton, 'Очистити'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Очистити').last);
      await tester.pumpAndSettle();

      expect((await store()).loadSearches(), isEmpty);
      expect(find.text('Що шукаємо?'), findsOneWidget);
    });
  });

  group('збереження між запусками', () {
    testWidgets('обране, історія й запити на місці після перезапуску', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');
      await tester.enterText(searchField(), 'jb10');
      await tester.pumpAndSettle(SearchScreen.debounce);
      await tester.tap(find.widgetWithText(CodeBadge, 'JB10'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Додати в обране'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // «Перезапуск»: новий застосунок на тих самих збережених даних.
      await tester.pumpRouterApp(initialLocation: '/saved');
      expect(favoriteCodes(tester), ['JB10']);

      await tester.tap(savedTab('Історія'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(CodeBadge, 'JB10'), findsOneWidget);

      await tester.tap(find.byTooltip('Пошук').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('jb10'), findsOneWidget);
    });

    testWidgets('пошкоджені збережені дані не ламають застосунок', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        initialLocation: '/saved',
        stored: {
          UserStore.favoritesKey: 'зламано',
          UserStore.viewKey: '{"not": "a list"}',
          UserStore.searchKey: '[1, 2, 3]',
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Збережіть першу точку'), findsOneWidget);
      await tester.tap(savedTab('Історія'));
      await tester.pumpAndSettle();
      expect(find.text('Історія порожня'), findsOneWidget);
    });
  });

  testWidgets('«Збережене» вміщається на вузькому екрані зі шрифтом 200 %', (
    tester,
  ) async {
    for (final location in ['/saved', '/saved?tab=history']) {
      await tester.pumpRouterApp(
        initialLocation: location,
        size: const Size(320, 640),
        textScale: 2,
        now: () => now,
        stored: stored(
          favorites: ['83', '12M'],
          views: [
            ('point', '83', now),
            ('symptom', 'serdtse--pischevaritelnye-prichiny', now),
          ],
        ),
      );
      expect(tester.takeException(), isNull, reason: location);
    }
  });
}
