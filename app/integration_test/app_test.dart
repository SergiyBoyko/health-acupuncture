// Наскрізний сценарій на справжньому пристрої чи емуляторі:
// пошук → точка → обране → перезапуск → обране та історія на місці.
//
// Запуск:  fvm flutter test integration_test/app_test.dart -d <пристрій>
//
// Сценарій стирає дані користувача застосунку на цьому пристрої.
import 'package:acupoints/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> launch(WidgetTester tester) async {
  await app.main();
  await tester.pumpAndSettle();
}

Finder inBar(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('пошук, точка, обране і збереження між запусками', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();

    // Перший запуск: застереження, потім Головна.
    await launch(tester);
    expect(find.text('Перш ніж почати'), findsOneWidget);
    await tester.tap(find.text('Я прочитав(ла), продовжити'));
    await tester.pumpAndSettle();
    expect(find.text('Частини тіла'), findsOneWidget);

    // Пошук «голов».
    await tester.tap(find.text('Код, симптом або слово'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'голов');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.textContaining('Точки · '), findsOneWidget);

    // Відкриваємо точку 3M («Головокружение…») і додаємо в обране.
    await tester.tap(find.text('3M').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Додати в обране'), findsOneWidget);
    await tester.tap(find.byTooltip('Додати в обране'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byTooltip('Прибрати з обраного'), findsOneWidget);

    // «Перезапуск»: застосунок стартує знову на тих самих даних.
    await tester.pumpWidget(const SizedBox.shrink());
    await launch(tester);

    // Застереження вже підтверджено; на Головній є запит і перегляд.
    expect(find.text('Перш ніж почати'), findsNothing);
    expect(find.text('голов'), findsOneWidget);
    expect(find.text('Нещодавні'), findsOneWidget);

    // Обране на місці.
    await tester.tap(inBar('Збережене'));
    await tester.pumpAndSettle();
    expect(find.text('3M'), findsOneWidget);

    // Історія на місці.
    await tester.tap(find.text('Історія'));
    await tester.pumpAndSettle();
    expect(find.text('3M'), findsOneWidget);
    expect(find.text('Сьогодні'), findsOneWidget);
  });
}
