import 'package:acupoints/core/theme/app_colors.dart';
import 'package:acupoints/core/theme/app_theme.dart';
import 'package:acupoints/core/widgets/code_badge.dart';
import 'package:acupoints/core/widgets/empty_state.dart';
import 'package:acupoints/core/widgets/paper_image.dart';
import 'package:acupoints/core/widgets/point_list_tile.dart';
import 'package:acupoints/core/widgets/section_header.dart';
import 'package:acupoints/data/content_repository.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/test_content.dart';

void main() {
  late ContentRepository repo;

  setUpAll(() => repo = loadTestContent());

  group('AppTheme', () {
    test('підкладка малюнків однакова в обох темах', () {
      final light = AppTheme.light().extension<AppColors>()!;
      final dark = AppTheme.dark().extension<AppColors>()!;
      expect(light.paper, dark.paper);
      expect(light.noteContainer, isNot(dark.noteContainer));
    });

    test('iOS має перехід із жестом «назад»', () {
      final builders = AppTheme.light().pageTransitionsTheme.builders;
      expect(
        builders[TargetPlatform.iOS],
        isA<CupertinoPageTransitionsBuilder>(),
      );
    });

    test('текст на підкладках має контраст не менше 4.5:1', () {
      double contrast(Color a, Color b) {
        final la = a.computeLuminance();
        final lb = b.computeLuminance();
        final hi = la > lb ? la : lb;
        final lo = la > lb ? lb : la;
        return (hi + 0.05) / (lo + 0.05);
      }

      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final colors = theme.extension<AppColors>()!;
        final scheme = theme.colorScheme;
        expect(contrast(colors.onPaper, colors.paper), greaterThan(4.5));
        expect(
          contrast(colors.onNoteContainer, colors.noteContainer),
          greaterThan(4.5),
        );
        expect(
          contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
          greaterThan(4.5),
        );
        expect(
          contrast(scheme.onTertiaryContainer, scheme.tertiaryContainer),
          greaterThan(4.5),
        );
      }
    });
  });

  group('CodeBadge', () {
    testWidgets('показує код і має підпис для екранного читача', (
      tester,
    ) async {
      await tester.pumpApp(const Center(child: CodeBadge('12M')));

      expect(find.text('12M'), findsOneWidget);
      expect(find.bySemanticsLabel('Точка 12M'), findsOneWidget);
      expect(
        tester.getSize(find.byType(CodeBadge)).width,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('неактивний код пояснює, що точки немає', (tester) async {
      await tester.pumpApp(
        const Center(child: CodeBadge('11E', enabled: false)),
      );

      expect(
        find.bySemanticsLabel('Код 11E: такої точки в книзі немає'),
        findsOneWidget,
      );
    });

    testWidgets('довгий код не переноситься при шрифті 200 %', (tester) async {
      await tester.pumpApp(
        const Center(child: CodeBadge('JB10')),
        textScale: 2,
      );

      final text = tester.widget<Text>(find.text('JB10'));
      expect(text.maxLines, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('PointListTile', () {
    testWidgets('показує код, заголовок і мініатюру', (tester) async {
      final point = repo.point('12M')!;
      var taps = 0;
      await tester.pumpApp(
        PointListTile(
          point: point,
          figure: repo.figuresOfPoint(point).first,
          onTap: () => taps++,
        ),
      );

      expect(find.text('12M'), findsOneWidget);
      expect(find.text(point.title), findsOneWidget);
      expect(find.byType(PaperImage), findsOneWidget);
      expect(find.text('Соматична'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(
        tester.getSize(find.byType(PointListTile)).height,
        greaterThanOrEqualTo(72),
      );

      await tester.tap(find.byType(PointListTile));
      expect(taps, 1);
    });

    testWidgets('позначає соматичну точку та обране', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpApp(
        PointListTile(point: repo.point('10M')!, isFavorite: true),
      );

      expect(find.text('Соматична'), findsOneWidget);
      // Екранний читач озвучує рядок як одне ціле.
      expect(
        tester.getSemantics(find.byType(PointListTile)).label,
        allOf(
          startsWith('Точка 10M'),
          contains('Соматична'),
          endsWith('В обраному'),
        ),
      );
      expect(find.byType(PaperImage), findsNothing);
      semantics.dispose();
    });

    testWidgets('показує додатковий рядок', (tester) async {
      await tester.pumpApp(
        PointListTile(point: repo.point('77')!, subtitle: 'правая'),
      );

      expect(find.text('правая'), findsOneWidget);
    });

    testWidgets('вміщається на вузькому екрані зі шрифтом 200 %', (
      tester,
    ) async {
      // Найдовший заголовок у книзі — точка 83.
      final point = repo.point('83')!;
      await tester.pumpApp(
        SingleChildScrollView(
          child: PointListTile(
            point: point,
            figure: repo.figuresOfPoint(point).first,
            subtitle: 'левая и правая',
            isFavorite: true,
          ),
        ),
        textScale: 2,
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('83'), findsOneWidget);
    });
  });

  group('SectionHeader', () {
    testWidgets('показує дію і викликає її', (tester) async {
      var calls = 0;
      await tester.pumpApp(
        SectionHeader(
          'Останні запити',
          actionLabel: 'Очистити',
          onAction: () => calls++,
        ),
      );

      await tester.tap(find.text('Очистити'));
      expect(calls, 1);
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('без дії показує лише заголовок', (tester) async {
      await tester.pumpApp(const SectionHeader('Частини тіла'));

      expect(find.text('Частини тіла'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('EmptyState', () {
    testWidgets('показує текст і дію', (tester) async {
      var calls = 0;
      await tester.pumpApp(
        EmptyState(
          icon: Icons.star_border,
          title: 'Збережіть першу точку',
          message: 'Торкніться зірочки на сторінці точки.',
          actionLabel: 'Відкрити тіло',
          onAction: () => calls++,
        ),
      );

      expect(find.text('Збережіть першу точку'), findsOneWidget);
      await tester.tap(find.text('Відкрити тіло'));
      expect(calls, 1);
    });

    testWidgets('вміщається на малому екрані зі шрифтом 200 %', (tester) async {
      await tester.pumpApp(
        const EmptyState(
          icon: Icons.search_off,
          title: 'Нічого не знайдено',
          message: 'Спробуйте інше слово або відкрийте покажчик симптомів.',
        ),
        textScale: 2,
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('PaperImage має підкладку і підпис малюнка', (tester) async {
    final figure = repo.figure('g24')!;
    await tester.pumpApp(
      Center(
        child: SizedBox(width: 200, height: 200, child: PaperImage(figure)),
      ),
      brightness: Brightness.dark,
    );

    final box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(PaperImage),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(box.color, AppColors.paperColor);
    expect(
      tester.widget<Image>(find.byType(Image)).semanticLabel,
      figure.caption,
    );
  });
}
