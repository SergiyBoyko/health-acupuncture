import 'package:acupoints/core/router/app_tab.dart';
import 'package:acupoints/core/widgets/point_list_tile.dart';
import 'package:acupoints/features/body/body_screen.dart';
import 'package:acupoints/features/body/segment_screen.dart';
import 'package:acupoints/features/home/home_screen.dart';
import 'package:acupoints/features/point/point_screen.dart';
import 'package:acupoints/features/saved/saved_screen.dart';
import 'package:acupoints/features/shell/not_found_screen.dart';
import 'package:acupoints/features/symptoms/symptoms_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/pump_router_app.dart';

/// Адреса верхнього екрана, включно з відкритими через `push`.
String location(GoRouter router) => router.state.uri.path;

Finder tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Кнопка «назад» верхнього екрана. `tester.pageBack()` шукає англійську
/// підказку, а застосунок український.
Finder backButton() => find.byType(BackButton).hitTestable().last;

/// Чи видно екран користувачеві (а не просто збережено в неактивній вкладці).
bool visible(Finder finder) => finder.hitTestable().evaluate().isNotEmpty;

void main() {
  group('AppTab', () {
    test('шляхи вкладених екранів', () {
      expect(AppTab.home.child('point/12M'), '/point/12M');
      expect(AppTab.body.child('point/12M'), '/body/point/12M');
      expect(AppTab.saved.child('segment/golova'), '/saved/segment/golova');
    });

    test('вкладка за шляхом', () {
      expect(AppTab.ofPath('/'), AppTab.home);
      expect(AppTab.ofPath('/point/12M'), AppTab.home);
      expect(AppTab.ofPath('/body'), AppTab.body);
      expect(AppTab.ofPath('/body/segment/golova'), AppTab.body);
      expect(AppTab.ofPath('/symptoms/point/2B'), AppTab.symptoms);
      expect(AppTab.ofPath('/saved'), AppTab.saved);
      expect(AppTab.ofPath('/bodywork'), AppTab.home);
    });

    test('код точки в адресі', () {
      expect(PointCodeUrl.encode('49½'), '49-half');
      expect(PointCodeUrl.decode('49-half'), '49½');
      expect(PointCodeUrl.decode(PointCodeUrl.encode('JB10')), 'JB10');
    });
  });

  group('нижня панель', () {
    testWidgets('показує чотири вкладки, відкрито Головну', (tester) async {
      await tester.pumpRouterApp();

      for (final label in ['Головна', 'Тіло', 'Симптоми', 'Збережене']) {
        expect(tab(label), findsOneWidget);
      }
      expect(visible(find.byType(HomeScreen)), isTrue);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    });

    testWidgets('перемикає вкладки', (tester) async {
      final router = await tester.pumpRouterApp();

      await tester.tap(tab('Тіло'));
      await tester.pumpAndSettle();
      expect(visible(find.byType(BodyScreen)), isTrue);
      expect(location(router), '/body');

      await tester.tap(tab('Симптоми'));
      await tester.pumpAndSettle();
      expect(visible(find.byType(SymptomsScreen)), isTrue);

      await tester.tap(tab('Збережене'));
      await tester.pumpAndSettle();
      expect(visible(find.byType(SavedScreen)), isTrue);
      expect(location(router), '/saved');
    });

    testWidgets('лишається видимою на вкладених екранах', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/12M');

      expect(visible(find.byType(PointScreen)), isTrue);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
    });
  });

  group('стек вкладки', () {
    Future<GoRouter> openPointInBody(WidgetTester tester) async {
      final router = await tester.pumpRouterApp();
      await tester.tap(tab('Тіло'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Голова'));
      await tester.pumpAndSettle();
      expect(visible(find.byType(SegmentScreen)), isTrue);
      await tester.tap(find.text('5M'));
      await tester.pumpAndSettle();
      expect(visible(find.byType(PointScreen)), isTrue);
      return router;
    }

    testWidgets('сегмент → точка → пов\'язана точка, «назад» по одному', (
      tester,
    ) async {
      final router = await openPointInBody(tester);
      expect(location(router), '/body/point/5M');

      await tester.tap(find.text('2B'));
      await tester.pumpAndSettle();
      expect(location(router), '/body/point/2B');

      await tester.tap(backButton());
      await tester.pumpAndSettle();
      expect(location(router), '/body/point/5M');

      await tester.tap(backButton());
      await tester.pumpAndSettle();
      expect(visible(find.byType(SegmentScreen)), isTrue);

      await tester.tap(backButton());
      await tester.pumpAndSettle();
      expect(visible(find.byType(BodyScreen)), isTrue);
    });

    testWidgets('зберігається при перемиканні вкладок', (tester) async {
      await openPointInBody(tester);

      await tester.tap(tab('Симптоми'));
      await tester.pumpAndSettle();
      expect(visible(find.byType(PointScreen)), isFalse);

      await tester.tap(tab('Тіло'));
      await tester.pumpAndSettle();
      expect(visible(find.byType(PointScreen)), isTrue);
      expect(find.text('5M').hitTestable(), findsOneWidget);

      await tester.tap(backButton());
      await tester.pumpAndSettle();
      expect(visible(find.byType(SegmentScreen)), isTrue);
    });

    testWidgets('повторний дотик активної вкладки повертає на корінь', (
      tester,
    ) async {
      final router = await openPointInBody(tester);

      await tester.tap(tab('Тіло'));
      await tester.pumpAndSettle();

      expect(location(router), '/body');
      expect(visible(find.byType(BodyScreen)), isTrue);
      expect(find.byType(PointScreen), findsNothing);
      expect(find.byType(SegmentScreen), findsNothing);
    });

    testWidgets('позиція прокрутки зберігається при перемиканні', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/golova');

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
        of: find.byType(SegmentScreen),
        matching: find.byType(Scrollable),
      );
      final offset = tester.state<ScrollableState>(scrollable).position.pixels;
      expect(offset, greaterThan(0));

      await tester.tap(tab('Головна'));
      await tester.pumpAndSettle();
      await tester.tap(tab('Тіло'));
      await tester.pumpAndSettle();

      expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    });

    testWidgets('точка відкривається у стеку тієї вкладки, де її відкрили', (
      tester,
    ) async {
      final router = await tester.pumpRouterApp(
        initialLocation: '/saved/segment/shyya',
      );

      await tester.tap(find.byType(PointListTile).first);
      await tester.pumpAndSettle();

      expect(location(router), '/saved/point/48');
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
    });
  });

  group('сторінка точки', () {
    testWidgets('показує сегмент і веде до нього', (tester) async {
      final router = await tester.pumpRouterApp(initialLocation: '/point/12M');

      expect(find.text('Голова · стор. 7'), findsOneWidget);
      await tester.tap(find.text('Голова · стор. 7'));
      await tester.pumpAndSettle();

      expect(location(router), '/segment/golova');
      expect(visible(find.byType(SegmentScreen)), isTrue);
    });

    testWidgets('відкривається за адресою з дробовим кодом', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/49-half');

      expect(visible(find.byType(PointScreen)), isTrue);
      expect(find.text('49½'), findsOneWidget);
    });
  });

  group('не знайдено', () {
    testWidgets('невідома адреса', (tester) async {
      final router = await tester.pumpRouterApp(
        initialLocation: '/no-such-page',
      );

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('Сторінку не знайдено'), findsOneWidget);

      await tester.tap(find.text('На головну'));
      await tester.pumpAndSettle();
      expect(location(router), '/');
      expect(visible(find.byType(HomeScreen)), isTrue);
    });

    testWidgets('невідомий код точки', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/999');

      expect(visible(find.byType(NotFoundScreen)), isTrue);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('невідомий сегмент', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/hvist');

      expect(visible(find.byType(NotFoundScreen)), isTrue);
    });
  });
}
