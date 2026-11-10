import 'dart:convert';

import 'package:acupoints/data/user/user_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_router_app.dart';

/// Екрани застосунку з даними, на яких видно всі їхні елементи.
final DateTime _now = DateTime(2026, 11, 10, 15, 30);

Map<String, Object> _userData() => {
  UserStore.searchKey: jsonEncode([
    for (final q in ['головная боль', '12M'])
      {'query': q, 'at': _now.toIso8601String()},
  ]),
  UserStore.viewKey: jsonEncode([
    for (final (type, id) in [
      ('point', '12M'),
      ('segment', 'shyya'),
      ('symptom', 'kolit'),
      ('term', 'Аорта'),
    ])
      {'type': type, 'id': id, 'at': _now.toIso8601String()},
  ]),
  UserStore.favoritesKey: jsonEncode([
    for (final c in ['2B', '10M']) {'code': c, 'at': _now.toIso8601String()},
  ]),
};

const _screens = <(String, String)>[
  ('Головна', '/'),
  ('Тіло', '/body'),
  ('сегмент', '/body/segment/golova'),
  ('точка', '/body/point/12M'),
  ('точка зі сторонами', '/body/point/S1'),
  ('малюнок на весь екран', '/body/segment/golova/image/g01'),
  ('Симптоми', '/symptoms'),
  ('група симптомів', '/symptoms/symptom-group/bol'),
  ('симптом', '/symptoms/symptom/ataksiya'),
  ('симптом із невідомим кодом', '/symptoms/symptom/kolit'),
  ('Словник', '/symptoms/glossary'),
  ('пошук: останні запити', '/body/search'),
  ('пошук: результати', '/body/search?q=мозг'),
  ('пошук: нічого не знайдено', '/body/search?q=ййй'),
  ('Збережене: обране', '/saved'),
  ('Збережене: історія', '/saved?tab=history'),
  ('Налаштування', '/settings'),
  ('Про джерело', '/about'),
  ('не знайдено', '/body/point/999'),
];

void main() {
  for (final brightness in Brightness.values) {
    group('доступність, ${brightness.name} тема', () {
      for (final (name, location) in _screens) {
        testWidgets(name, (tester) async {
          final semantics = tester.ensureSemantics();
          await tester.pumpRouterApp(
            initialLocation: location,
            brightness: brightness,
            stored: _userData(),
            now: () => _now,
          );

          // Цілі дотику не менші за 48×48 dp (Android) і 44×44 pt (iOS).
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          // Кожен елемент, який можна натиснути, має назву для читача.
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          // Контраст тексту не нижчий за 4.5:1 (3:1 для великого).
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantics.dispose();
        });
      }

      testWidgets('застереження першого запуску', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpRouterApp(firstLaunch: true, brightness: brightness);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });

      testWidgets('легенда позначень', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpRouterApp(
          initialLocation: '/symptoms',
          brightness: brightness,
        );
        await tester.tap(find.byTooltip('Позначення'));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    });
  }
}
