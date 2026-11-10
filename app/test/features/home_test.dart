import 'dart:convert';

import 'package:acupoints/core/widgets/code_badge.dart';
import 'package:acupoints/core/widgets/section_header.dart';
import 'package:acupoints/data/user/user_store.dart';
import 'package:acupoints/features/body/segment_screen.dart';
import 'package:acupoints/features/glossary/glossary_screen.dart';
import 'package:acupoints/features/home/home_screen.dart';
import 'package:acupoints/features/home/recent_strip.dart';
import 'package:acupoints/features/point/point_screen.dart';
import 'package:acupoints/features/saved/saved_screen.dart';
import 'package:acupoints/features/search/search_screen.dart';
import 'package:acupoints/features/symptoms/symptom_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/pump_router_app.dart';

final DateTime now = DateTime(2026, 11, 10, 15, 30);

Map<String, Object> stored({
  List<String> searches = const [],
  List<(String, String)> views = const [],
}) => {
  if (searches.isNotEmpty)
    UserStore.searchKey: jsonEncode([
      for (final q in searches) {'query': q, 'at': now.toIso8601String()},
    ]),
  if (views.isNotEmpty)
    UserStore.viewKey: jsonEncode([
      for (final (type, id) in views)
        {'type': type, 'id': id, 'at': now.toIso8601String()},
    ]),
};

Finder header(String title) => find.widgetWithText(SectionHeader, title);

Finder searchEntry() => find.bySemanticsLabel('Пошук');

List<RecentItem> recentItems(WidgetTester tester) =>
    tester.widget<RecentStrip>(find.byType(RecentStrip)).items;

List<String> chips(WidgetTester tester) => tester
    .widgetList<ActionChip>(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(ActionChip),
      ),
    )
    .map((c) => (c.label as Text).data!)
    .toList();

void main() {
  group('перший запуск', () {
    testWidgets('пошук і частини тіла, без порожніх блоків історії', (
      tester,
    ) async {
      await tester.pumpRouterApp();

      expect(find.text('Точки надавлювання'), findsOneWidget);
      expect(searchEntry(), findsOneWidget);
      expect(find.text('Код, симптом або слово'), findsOneWidget);
      expect(header('Останні запити'), findsNothing);
      expect(header('Нещодавні'), findsNothing);
      expect(find.byType(RecentStrip), findsNothing);
      expect(header('Частини тіла'), findsOneWidget);
    });

    testWidgets('п\'ять частин тіла з кількістю точок і словник', (
      tester,
    ) async {
      await tester.pumpRouterApp();

      for (final (title, count) in [
        ('Голова', '36 точок'),
        ('Шия', '6 точок'),
        ('Тулуб', '37 точок'),
        ('Спина', '15 точок'),
        ('Руки і ноги', '25 точок'),
        ('Словник', '71 термін'),
      ]) {
        await tester.scrollUntilVisible(find.text(title), 200);
        expect(find.text(title), findsOneWidget);
        expect(find.text(count), findsOneWidget);
      }
    });

    testWidgets('поле пошуку відкриває пошук із клавіатурою', (tester) async {
      await tester.pumpRouterApp();

      await tester.tap(searchEntry());
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen).hitTestable(), findsOneWidget);
      expect(find.text('Що шукаємо?'), findsOneWidget);
    });

    testWidgets('частина тіла відкривається у вкладці «Головна»', (
      tester,
    ) async {
      final GoRouter router = await tester.pumpRouterApp();

      await tester.tap(find.text('Шия'));
      await tester.pumpAndSettle();

      expect(find.byType(SegmentScreen).hitTestable(), findsOneWidget);
      expect(router.state.uri.path, '/segment/shyya');
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    });

    testWidgets('словник відкривається з Головної', (tester) async {
      await tester.pumpRouterApp();

      await tester.scrollUntilVisible(find.text('Словник'), 200);
      await tester.tap(find.text('Словник'));
      await tester.pumpAndSettle();

      expect(find.byType(GlossaryScreen).hitTestable(), findsOneWidget);
    });
  });

  group('останні запити', () {
    final seven = ['q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7'];

    testWidgets('не більше п\'яти, найновіші перші', (tester) async {
      await tester.pumpRouterApp(stored: stored(searches: seven));

      expect(header('Останні запити'), findsOneWidget);
      expect(chips(tester), ['q1', 'q2', 'q3', 'q4', 'q5']);
    });

    testWidgets('чип відкриває пошук із результатами цього запиту', (
      tester,
    ) async {
      await tester.pumpRouterApp(stored: stored(searches: ['jb10', 'мозг']));

      await tester.tap(find.widgetWithText(ActionChip, 'jb10'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen).hitTestable(), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byType(SearchScreen),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'jb10',
      );
      expect(find.widgetWithText(CodeBadge, 'JB10'), findsOneWidget);
    });

    testWidgets('очищення з підтвердженням прибирає блок', (tester) async {
      await tester.pumpRouterApp(stored: stored(searches: ['jb10', 'мозг']));

      await tester.tap(find.widgetWithText(TextButton, 'Очистити'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Скасувати'));
      await tester.pumpAndSettle();
      expect(chips(tester), ['jb10', 'мозг']);

      await tester.tap(find.widgetWithText(TextButton, 'Очистити'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Очистити').last);
      await tester.pumpAndSettle();

      expect(header('Останні запити'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(UserStore(prefs).loadSearches(), isEmpty);
    });
  });

  group('нещодавні', () {
    testWidgets('не більше восьми, найновіші перші, різні типи', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        stored: stored(
          views: [
            ('point', '12M'),
            ('segment', 'shyya'),
            ('symptom', 'kolit'),
            ('term', 'Аорта'),
            ('point', '2B'),
            ('point', '9B'),
            ('point', '35'),
            ('point', '5M'),
            ('point', '1B'),
            ('point', '1M'),
          ],
        ),
      );

      final items = recentItems(tester);
      expect(items, hasLength(HomeScreen.maxRecent));
      expect(items.take(4).map((i) => i.code ?? i.title), [
        '12M',
        'Шия',
        'Колит',
        'Аорта',
      ]);
      // Точка і сегмент мають малюнок, симптом і термін — іконку.
      expect(items[0].figure, isNotNull);
      expect(items[1].figure, isNotNull);
      expect(items[2].figure, isNull);
      expect(items[3].figure, isNull);
    });

    testWidgets('записи без вмісту пропускаються', (tester) async {
      await tester.pumpRouterApp(
        stored: stored(
          views: [('point', '999'), ('segment', 'hvist'), ('point', '12M')],
        ),
      );

      expect(recentItems(tester).map((i) => i.code), ['12M']);
    });

    testWidgets('картка відкриває точку, симптом', (tester) async {
      final data = stored(views: [('point', '12M'), ('symptom', 'kolit')]);

      await tester.pumpRouterApp(stored: data);
      await tester.tap(find.widgetWithText(CodeBadge, '12M'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PointScreen>(find.byType(PointScreen).hitTestable()).code,
        '12M',
      );

      await tester.pumpRouterApp(stored: data);
      await tester.tap(find.text('Колит'));
      await tester.pumpAndSettle();
      expect(find.byType(SymptomScreen).hitTestable(), findsOneWidget);
    });

    testWidgets('«Усі» відкриває повну історію у «Збереженому»', (
      tester,
    ) async {
      await tester.pumpRouterApp(stored: stored(views: [('point', '12M')]));

      await tester.tap(find.widgetWithText(TextButton, 'Усі'));
      await tester.pumpAndSettle();

      expect(find.byType(SavedScreen).hitTestable(), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(find.byTooltip('Очистити історію'), findsOneWidget);
    });

    testWidgets('з\'являється одразу після перегляду, без перезапуску', (
      tester,
    ) async {
      await tester.pumpRouterApp();
      expect(find.byType(RecentStrip), findsNothing);

      await tester.tap(find.text('Шия'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5B'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).hitTestable().last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).hitTestable().last);
      await tester.pumpAndSettle();

      expect(recentItems(tester).map((i) => i.code ?? i.title), ['5B', 'Шия']);
    });
  });

  testWidgets('вміщається на вузькому екрані зі шрифтом 200 %', (tester) async {
    await tester.pumpRouterApp(
      size: const Size(320, 640),
      textScale: 2,
      stored: stored(
        searches: ['головная боль', 'желчные камни', '12M'],
        views: [
          ('point', '83'),
          ('segment', 'ruky-nohy'),
          ('symptom', 'serdtse--pischevaritelnye-prichiny'),
        ],
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Словник'), findsOneWidget);
  });
}
