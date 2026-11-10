import 'package:acupoints/core/theme/app_colors.dart';
import 'package:acupoints/data/user/user_store.dart';
import 'package:acupoints/features/home/home_screen.dart';
import 'package:acupoints/features/settings/about_screen.dart';
import 'package:acupoints/features/settings/disclaimer_screen.dart';
import 'package:acupoints/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/pump_router_app.dart';

Future<UserStore> store() async =>
    UserStore(await SharedPreferences.getInstance());

ThemeMode appThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

/// Яскравість теми, яку справді бачить користувач.
Brightness shownBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

Finder themeTile(String label) => find.widgetWithText(ListTile, label);

bool isChecked(WidgetTester tester, String label) => find
    .descendant(of: themeTile(label), matching: find.byIcon(Icons.check))
    .evaluate()
    .isNotEmpty;

void main() {
  group('сховище налаштувань', () {
    Future<UserStore> storeWith(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return UserStore(await SharedPreferences.getInstance());
    }

    test('типові значення', () async {
      final s = await storeWith({});
      expect(s.loadThemeName(), 'system');
      expect(s.loadDisclaimerAccepted(), isFalse);
    });

    test('збереження теми та підтвердження', () async {
      final s = await storeWith({});
      s.saveThemeName('dark');
      s.saveDisclaimerAccepted();

      final reopened = await store();
      expect(reopened.loadThemeName(), 'dark');
      expect(reopened.loadDisclaimerAccepted(), isTrue);
    });

    test('невідома або зіпсована тема → системна', () async {
      expect(
        (await storeWith({UserStore.themeKey: 'sepia'})).loadThemeName(),
        'system',
      );
      expect(
        (await storeWith({UserStore.themeKey: 42})).loadThemeName(),
        'system',
      );
    });

    test('зіпсоване підтвердження вважається непідтвердженим', () async {
      final s = await storeWith({UserStore.disclaimerKey: 'так'});
      expect(s.loadDisclaimerAccepted(), isFalse);
    });

    test('налаштування не залежать від історії', () async {
      final s = await storeWith({});
      s.saveThemeName('light');
      s.addSearch('мозг');
      s.clearSearches();
      s.clearViews();

      expect(s.loadThemeName(), 'light');
    });
  });

  group('застереження першого запуску', () {
    testWidgets('показується замість застосунку', (tester) async {
      await tester.pumpRouterApp(firstLaunch: true);

      expect(find.byType(DisclaimerScreen), findsOneWidget);
      expect(find.text('Перш ніж почати'), findsOneWidget);
      expect(find.textContaining('Це не медична порада'), findsOneWidget);
      expect(find.textContaining('брошури'), findsOneWidget);
      expect(find.textContaining('1992'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('після підтвердження відкривається застосунок', (tester) async {
      await tester.pumpRouterApp(firstLaunch: true);

      await tester.tap(find.text('Я прочитав(ла), продовжити'));
      await tester.pumpAndSettle();

      expect(find.byType(DisclaimerScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect((await store()).loadDisclaimerAccepted(), isTrue);
    });

    testWidgets('показується один раз: після перезапуску його немає', (
      tester,
    ) async {
      await tester.pumpRouterApp(firstLaunch: true);
      await tester.tap(find.text('Я прочитав(ла), продовжити'));
      await tester.pumpAndSettle();

      // Перезапуск на тих самих збережених даних.
      await tester.pumpRouterApp();

      expect(find.byType(DisclaimerScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('без підтвердження показується знову', (tester) async {
      await tester.pumpRouterApp(firstLaunch: true);
      await tester.pumpRouterApp(firstLaunch: true);

      expect(find.byType(DisclaimerScreen), findsOneWidget);
    });

    testWidgets('пряма адреса не обходить застереження', (tester) async {
      await tester.pumpRouterApp(
        firstLaunch: true,
        initialLocation: '/body/point/12M',
      );

      expect(find.byType(DisclaimerScreen), findsOneWidget);
      expect(find.text('12M'), findsNothing);
    });

    testWidgets('вміщається на малому екрані зі шрифтом 200 %', (tester) async {
      await tester.pumpRouterApp(
        firstLaunch: true,
        size: const Size(320, 568),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      // Кнопка підтвердження завжди на екрані, навіть коли текст довгий.
      expect(
        find.text('Я прочитав(ла), продовжити').hitTestable(),
        findsOneWidget,
      );
    });
  });

  group('налаштування', () {
    testWidgets('відкриваються з Головної', (tester) async {
      await tester.pumpRouterApp();

      await tester.tap(find.byTooltip('Налаштування'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen).hitTestable(), findsOneWidget);
      expect(themeTile('Як у системі'), findsOneWidget);
      expect(themeTile('Світла'), findsOneWidget);
      expect(themeTile('Темна'), findsOneWidget);
    });

    testWidgets('типово — системна тема, що йде за пристроєм', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/settings',
        brightness: Brightness.dark,
      );

      expect(appThemeMode(tester), ThemeMode.system);
      expect(isChecked(tester, 'Як у системі'), isTrue);
      expect(shownBrightness(tester), Brightness.dark);
    });

    testWidgets('вибір теми застосовується одразу і зберігається', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/settings');
      expect(shownBrightness(tester), Brightness.light);

      await tester.tap(themeTile('Темна'));
      await tester.pumpAndSettle();

      expect(appThemeMode(tester), ThemeMode.dark);
      expect(shownBrightness(tester), Brightness.dark);
      expect(isChecked(tester, 'Темна'), isTrue);
      expect(isChecked(tester, 'Як у системі'), isFalse);
      expect((await store()).loadThemeName(), 'dark');
    });

    testWidgets('обрана тема лишається після перезапуску', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/settings');
      await tester.tap(themeTile('Темна'));
      await tester.pumpAndSettle();

      await tester.pumpRouterApp(initialLocation: '/settings');

      expect(appThemeMode(tester), ThemeMode.dark);
      expect(isChecked(tester, 'Темна'), isTrue);
    });

    testWidgets('світла тема не йде за темним пристроєм', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/settings',
        brightness: Brightness.dark,
        stored: {UserStore.themeKey: 'light'},
      );

      expect(shownBrightness(tester), Brightness.light);
      expect(isChecked(tester, 'Світла'), isTrue);
    });

    testWidgets('повернення до системної теми', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/settings',
        stored: {UserStore.themeKey: 'dark'},
      );

      await tester.tap(themeTile('Як у системі'));
      await tester.pumpAndSettle();

      expect(appThemeMode(tester), ThemeMode.system);
      expect(shownBrightness(tester), Brightness.light);
      expect((await store()).loadThemeName(), 'system');
    });

    testWidgets('підкладка малюнків однакова в обраній темній темі', (
      tester,
    ) async {
      await tester.pumpRouterApp(
        initialLocation: '/body/point/12M',
        stored: {UserStore.themeKey: 'dark'},
      );

      final context = tester.element(find.byType(Scaffold).last);
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(context.appColors.paper, AppColors.paperColor);
    });
  });

  group('про джерело', () {
    testWidgets('застереження доступне повторно з налаштувань', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/settings');

      await tester.tap(find.text('Про джерело і застереження'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen).hitTestable(), findsOneWidget);
      expect(find.textContaining('Це не медична порада'), findsOneWidget);
      expect(find.textContaining('зверніться по медичну допомогу'), findsOne);
    });

    testWidgets('відомості про джерело, обсяг і приватність', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/about');

      expect(find.textContaining('«Интерес»'), findsOneWidget);
      expect(find.textContaining('январь 1992'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Приватність'), 200);
      expect(
        find.text('У довіднику: 119 точок, 304 записи покажчика, 71 термін.'),
        findsOneWidget,
      );
      expect(find.textContaining('транскрибовано вручну'), findsOneWidget);
      expect(find.textContaining('лише на цьому пристрої'), findsOneWidget);
    });

    testWidgets('вміщається на вузькому екрані зі шрифтом 200 %', (
      tester,
    ) async {
      for (final location in ['/settings', '/about']) {
        await tester.pumpRouterApp(
          initialLocation: location,
          size: const Size(320, 640),
          textScale: 2,
        );
        expect(tester.takeException(), isNull, reason: location);
      }
    });
  });
}
