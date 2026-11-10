import 'package:acupoints/core/widgets/code_badge.dart';
import 'package:acupoints/core/widgets/paper_image.dart';
import 'package:acupoints/features/body/segment_screen.dart';
import 'package:acupoints/features/point/point_screen.dart';
import 'package:acupoints/features/point/widgets/point_gallery.dart';
import 'package:acupoints/features/shell/not_found_screen.dart';
import 'package:acupoints/features/viewer/image_viewer_screen.dart';
import 'package:acupoints/features/viewer/zoomable_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_router_app.dart';
import '../support/test_content.dart';

Finder viewer() => find.byType(ImageViewerScreen);

/// Видимий зараз малюнок у переглядачі.
ZoomableImageState shownImage(WidgetTester tester) =>
    tester.state<ZoomableImageState>(find.byType(ZoomableImage).hitTestable());

Finder viewerCode(String code) => find.descendant(
  of: viewer(),
  matching: find.widgetWithText(CodeBadge, code),
);

Future<void> doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 80));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openFromPoint(WidgetTester tester, String code) async {
  await tester.pumpRouterApp(initialLocation: '/body/point/$code');
  await tester.tap(find.byType(PointGallery));
  await tester.pumpAndSettle();
  expect(viewer(), findsOneWidget);
}

void main() {
  group('відкриття', () {
    testWidgets('дотик до малюнка точки відкриває його поверх панелі', (
      tester,
    ) async {
      await openFromPoint(tester, '12M');

      expect(find.byType(NavigationBar).hitTestable(), findsNothing);
      expect(find.text('1 з 3'), findsOneWidget);
      expect(
        find.descendant(
          of: viewer(),
          matching: find.text('Голова сбоку: 4, 9B, 12M, 13M, 16M, 16B'),
        ),
        findsOneWidget,
      );
      expect(find.text('Точки на малюнку'), findsOneWidget);
    });

    testWidgets('відкривається на тому малюнку, якого торкнулись', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/12M');
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PointGallery));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: viewer(), matching: find.text('2 з 3')),
        findsOne,
      );
      expect(shownImage(tester).widget.figure.kind.name, 'overview');
    });

    testWidgets('зведена схема сегмента відкривається зі стрічки', (
      tester,
    ) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/golova');

      await tester.tap(find.byType(PaperImage).first);
      await tester.pumpAndSettle();

      final total = loadTestContent()
          .segment('golova')!
          .overviewFigureIds
          .length;
      expect(viewer(), findsOneWidget);
      expect(find.text('1 з $total'), findsOneWidget);
    });

    testWidgets('єдиний малюнок: без лічильника', (tester) async {
      final repo = loadTestContent();
      final single = repo.points.firstWhere((p) => p.figureIds.length == 1);
      await openFromPoint(tester, single.code);

      expect(find.textContaining(' з 1'), findsNothing);
    });

    testWidgets('за прямою адресою', (tester) async {
      final figureId = loadTestContent().point('12M')!.figureIds[2];
      await tester.pumpRouterApp(
        initialLocation: '/body/point/12M/image/$figureId',
      );

      expect(viewer(), findsOneWidget);
      expect(find.text('3 з 3'), findsOneWidget);
    });
  });

  group('гортання і масштаб', () {
    testWidgets('гортання змінює малюнок, підпис і точки', (tester) async {
      await openFromPoint(tester, '12M');
      expect(viewerCode('13M'), findsOneWidget);

      await tester.drag(find.byType(ZoomableImage), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('2 з 3'), findsOneWidget);
      expect(
        find.descendant(
          of: viewer(),
          matching: find.text('Голова сбоку: сводная схема'),
        ),
        findsOneWidget,
      );
      expect(viewerCode('JB10'), findsOneWidget);
    });

    testWidgets('подвійний дотик збільшує, повторний повертає', (tester) async {
      await openFromPoint(tester, '12M');
      expect(shownImage(tester).scale, 1);

      await doubleTap(tester, find.byType(ZoomableImage));
      expect(shownImage(tester).scale, ZoomableImage.doubleTapScale);

      await doubleTap(tester, find.byType(ZoomableImage));
      expect(shownImage(tester).scale, 1);
    });

    testWidgets('збільшений малюнок пересувається, а не гортається', (
      tester,
    ) async {
      await openFromPoint(tester, '12M');
      await doubleTap(tester, find.byType(ZoomableImage));

      await tester.drag(find.byType(ZoomableImage), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('1 з 3'), findsOneWidget);
      expect(shownImage(tester).scale, ZoomableImage.doubleTapScale);

      // Після повернення масштабу гортання знову працює.
      await doubleTap(tester, find.byType(ZoomableImage));
      await tester.drag(find.byType(ZoomableImage), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 з 3'), findsOneWidget);
    });

    testWidgets('щипок збільшує в межах дозволеного', (tester) async {
      await openFromPoint(tester, '12M');
      final center = tester.getCenter(find.byType(ZoomableImage));

      final first = await tester.startGesture(center - const Offset(20, 0));
      final second = await tester.startGesture(center + const Offset(20, 0));
      await tester.pump();
      for (var i = 1; i <= 10; i++) {
        await first.moveBy(const Offset(-18, 0));
        await second.moveBy(const Offset(18, 0));
        await tester.pump();
      }
      await first.up();
      await second.up();
      await tester.pumpAndSettle();

      expect(shownImage(tester).scale, greaterThan(1.5));
      expect(
        shownImage(tester).scale,
        lessThanOrEqualTo(ZoomableImage.maxScale),
      );
    });
  });

  group('перехід до точок', () {
    testWidgets('точка з малюнка відкривається в тій самій вкладці', (
      tester,
    ) async {
      await openFromPoint(tester, '12M');

      await tester.tap(viewerCode('9B'));
      await tester.pumpAndSettle();

      expect(viewer(), findsNothing);
      expect(
        tester
            .widget<PointScreen>(find.byType(PointScreen).hitTestable().last)
            .code,
        '9B',
      );
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 1);

      // «Назад» повертає до точки, з якої відкривали малюнок.
      await tester.tap(find.byType(BackButton).hitTestable().last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PointScreen>(find.byType(PointScreen).hitTestable().last)
            .code,
        '12M',
      );
    });

    testWidgets('поточна точка просто закриває перегляд', (tester) async {
      await openFromPoint(tester, '12M');

      await tester.tap(viewerCode('12M'));
      await tester.pumpAndSettle();

      expect(viewer(), findsNothing);
      expect(find.byType(PointScreen), findsOneWidget);
    });

    testWidgets('точка зі схеми сегмента', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/segment/golova');
      await tester.tap(find.byType(PaperImage).first);
      await tester.pumpAndSettle();

      await tester.tap(viewerCode('1B'));
      await tester.pumpAndSettle();

      expect(viewer(), findsNothing);
      expect(
        tester.widget<PointScreen>(find.byType(PointScreen).hitTestable()).code,
        '1B',
      );
      // Сегмент лишився у стеку під точкою.
      expect(find.byType(SegmentScreen, skipOffstage: false), findsOneWidget);
    });
  });

  group('закриття і помилки', () {
    testWidgets('кнопка «Закрити» повертає на сторінку точки', (tester) async {
      await openFromPoint(tester, '12M');

      await tester.tap(find.byTooltip('Закрити'));
      await tester.pumpAndSettle();

      expect(viewer(), findsNothing);
      expect(find.byType(PointScreen).hitTestable(), findsOneWidget);
      expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
    });

    testWidgets('невідомий малюнок', (tester) async {
      await tester.pumpRouterApp(initialLocation: '/body/point/12M/image/nope');

      expect(find.byType(NotFoundScreen), findsOneWidget);
    });

    testWidgets('малюнок іншої точки не відкривається', (tester) async {
      // b01 — схема спини, до 12M не належить.
      await tester.pumpRouterApp(initialLocation: '/body/point/12M/image/b01');

      expect(find.byType(NotFoundScreen), findsOneWidget);
    });
  });

  testWidgets('схема з багатьма точками вміщається на малому екрані', (
    tester,
  ) async {
    // g01 — зведена схема голови з 23 точками.
    await tester.pumpRouterApp(
      initialLocation: '/body/segment/golova/image/g01',
      size: const Size(320, 568),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(viewer(), findsOneWidget);
    expect(tester.getSize(find.byType(ZoomableImage)).height, greaterThan(150));
  });
}
