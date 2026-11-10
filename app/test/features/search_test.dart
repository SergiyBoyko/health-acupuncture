import 'package:acupoints/core/widgets/code_badge.dart';
import 'package:acupoints/core/widgets/highlighted_text.dart';
import 'package:acupoints/core/widgets/section_header.dart';
import 'package:acupoints/features/point/point_screen.dart';
import 'package:acupoints/features/search/search_screen.dart';
import 'package:acupoints/features/symptoms/symptom_screen.dart';
import 'package:acupoints/features/symptoms/symptoms_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_router_app.dart';

Finder searchField() => find.descendant(
  of: find.byType(SearchScreen),
  matching: find.byType(TextField),
);

Future<void> type(WidgetTester tester, String query) async {
  await tester.enterText(searchField(), query);
  await tester.pump(SearchScreen.debounce);
  await tester.pumpAndSettle();
}

/// Коди точок у результатах, згори вниз.
List<String> resultCodes(WidgetTester tester) => tester
    .widgetList<CodeBadge>(
      find.descendant(
        of: find.byType(SearchScreen),
        matching: find.byType(CodeBadge),
      ),
    )
    .map((badge) => badge.code)
    .toList();

Finder header(String title) => find.widgetWithText(SectionHeader, title);

/// Підсвічені фрагменти в тексті.
List<String> highlighted(WidgetTester tester, Finder finder) {
  final widget = tester.widget<HighlightedText>(finder);
  return [for (final r in widget.ranges) widget.text.substring(r.start, r.end)];
}

void main() {
  group('доступ', () {
    for (final (location, name) in [
      ('/body', 'Тіло'),
      ('/body/segment/golova', 'сегмент'),
      ('/body/point/12M', 'точка'),
      ('/symptoms', 'Симптоми'),
      ('/symptoms/symptom/kolit', 'симптом'),
      ('/symptoms/symptom-group/bol', 'група симптомів'),
      ('/symptoms/glossary', 'Словник'),
      ('/saved', 'Збережене'),
    ]) {
      testWidgets('іконка пошуку на екрані «$name»', (tester) async {
        await tester.pumpRouterApp(initialLocation: location);

        await tester.tap(find.byTooltip('Пошук').hitTestable());
        await tester.pumpAndSettle();

        expect(find.byType(SearchScreen).hitTestable(), findsOneWidget);
      });
    }

    testWidgets('поле у фокусі, порожній запит показує підказку', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');

      expect(tester.widget<TextField>(searchField()).autofocus, isTrue);
      expect(find.text('Що шукаємо?'), findsOneWidget);
      expect(find.byTooltip('Очистити запит'), findsNothing);
    });
  });

  group('результати', () {
    testWidgets('з\'являються під час введення, згруповані з лічильниками', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');

      await tester.enterText(searchField(), 'мозг');
      // До спливу затримки пошук ще не виконано.
      expect(find.text('Що шукаємо?'), findsOneWidget);
      await tester.pump(SearchScreen.debounce);
      await tester.pumpAndSettle();

      expect(find.text('Що шукаємо?'), findsNothing);
      expect(find.textContaining('Точки · '), findsOneWidget);
      expect(resultCodes(tester), isNotEmpty);

      await tester.scrollUntilVisible(
        find.textContaining('Симптоми · '),
        400,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.textContaining('Симптоми · '), findsOneWidget);
    });

    testWidgets('точний код — перший результат', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');

      await type(tester, '12м');
      expect(resultCodes(tester).first, '12M');

      // Далі йдуть точки, де цей код згадано в описі.
      await type(tester, 'jb10');
      expect(resultCodes(tester).first, 'JB10');

      await type(tester, '49 1/2');
      expect(resultCodes(tester).first, '49½');
    });

    testWidgets('збіг підсвічено в заголовку', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');
      await type(tester, 'амнез');

      expect(header('Точки · 1'), findsOneWidget);
      expect(
        highlighted(
          tester,
          find.widgetWithText(HighlightedText, 'Амнезия (потеря памяти).'),
        ),
        ['Амнез'],
      );
      expect(find.text('Голова · стор. 7'), findsOneWidget);
    });

    testWidgets('збіг в описі: фрагмент із підсвіченням', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');
      await type(tester, 'пирамиду');

      expect(resultCodes(tester), ['35']);
      final snippet = find.byWidgetPredicate(
        (w) => w is HighlightedText && w.text.contains('пирамиду'),
      );
      expect(snippet, findsOneWidget);
      expect(highlighted(tester, snippet), ['пирамиду']);
    });

    testWidgets('запит уточнюється без повторного відкриття', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');

      await type(tester, 'желч');
      final broad = resultCodes(tester).length;
      await type(tester, 'желчные камни');
      final narrow = resultCodes(tester);

      expect(narrow, isNotEmpty);
      expect(narrow.length, lessThanOrEqualTo(broad));
      expect(narrow, contains('54'));
    });

    testWidgets('дотик до точки відкриває її в тій самій вкладці', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');
      await type(tester, 'jb10');

      await tester.tap(find.widgetWithText(CodeBadge, 'JB10'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<PointScreen>(find.byType(PointScreen).hitTestable()).code,
        'JB10',
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );

      // «Назад» повертає до результатів із тим самим запитом.
      await tester.tap(find.byType(BackButton).hitTestable().last);
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen).hitTestable(), findsOneWidget);
      expect(tester.widget<TextField>(searchField()).controller!.text, 'jb10');
      expect(resultCodes(tester).first, 'JB10');
    });

    testWidgets('симптом відкриває список своїх точок', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');
      await type(tester, 'катаракта');

      expect(header('Симптоми · 1'), findsOneWidget);
      await tester.tap(find.text('Глаза: катаракта'));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomScreen).hitTestable(), findsOneWidget);
    });

    testWidgets('термін словника розгортається на місці', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');
      await type(tester, 'бифуркация');

      expect(header('Словник · 1'), findsOneWidget);
      // Згорнуто: визначення одним рядком у підзаголовку.
      expect(find.text('разветвление.'), findsOneWidget);

      await tester.tap(find.text('Бифуркация'));
      await tester.pumpAndSettle();
      expect(find.text('разветвление.'), findsNWidgets(2));
    });

    testWidgets('запит з адреси виконується одразу', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/search?q=jb10');

      expect(tester.widget<TextField>(searchField()).controller!.text, 'jb10');
      expect(resultCodes(tester).first, 'JB10');
    });
  });

  group('порожні стани', () {
    testWidgets('немає результатів: підказка і перехід до симптомів', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');
      await type(tester, 'ййй');

      expect(find.text('Нічого не знайдено'), findsOneWidget);
      expect(find.textContaining('За запитом «ййй» нічого немає'), findsOne);

      await tester.tap(find.text('Відкрити покажчик симптомів'));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomsScreen).hitTestable(), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
    });

    testWidgets('очищення повертає підказку', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/search');
      await type(tester, 'мозг');

      await tester.tap(find.byTooltip('Очистити запит'));
      await tester.pumpAndSettle();

      expect(find.text('Що шукаємо?'), findsOneWidget);
      expect(tester.widget<TextField>(searchField()).controller!.text, isEmpty);
      expect(resultCodes(tester), isEmpty);
    });

    testWidgets('закриття екрана під час затримки не падає', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/12M');
      await tester.tap(find.byTooltip('Пошук').hitTestable());
      await tester.pumpAndSettle();

      await tester.enterText(searchField(), 'мозг');
      await tester.tap(find.byType(BackButton).hitTestable().last);
      await tester.pumpAndSettle(SearchScreen.debounce * 2);

      expect(tester.takeException(), isNull);
      expect(find.byType(SearchScreen), findsNothing);
    });
  });

  testWidgets('вміщається на вузькому екрані зі шрифтом 200 %', (tester) async {
    await tester.pumpRouterApp(
      initialLocation: '/body/search?q=мозг',
      size: const Size(320, 640),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(resultCodes(tester), isNotEmpty);
  });
}
