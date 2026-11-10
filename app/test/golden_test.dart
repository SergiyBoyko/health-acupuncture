// Знімки ключових екранів у світлій і темній темах.
//
// Оновити еталони:  fvm flutter test --update-goldens test/golden_test.dart
//
// Еталони згенеровано на macOS; на іншій ОС згладжування шрифтів трохи
// відрізняється, тож там їх треба перегенерувати.
@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:acupoints/data/user/user_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_router_app.dart';

final DateTime _now = DateTime(2026, 11, 10, 15, 30);

Map<String, Object> _userData() => {
  UserStore.searchKey: jsonEncode([
    for (final q in ['головная боль', '12M', 'желчные камни'])
      {'query': q, 'at': _now.toIso8601String()},
  ]),
  UserStore.viewKey: jsonEncode([
    for (final (type, id) in [
      ('point', '12M'),
      ('segment', 'shyya'),
      ('symptom', 'kolit'),
      ('point', '2B'),
    ])
      {'type': type, 'id': id, 'at': _now.toIso8601String()},
  ]),
  UserStore.favoritesKey: jsonEncode([
    {'code': '12M', 'at': _now.toIso8601String()},
  ]),
};

/// Справжні шрифти замість тестових квадратиків: Roboto й іконки Material
/// зі складу Flutter SDK.
Future<bool> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return false;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return false;

  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('${dir.path}/$name').readAsBytes());

  final roboto = FontLoader('Roboto');
  for (final name in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    roboto.addFont(read(name));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await icons.load();
  return true;
}

/// Декодує малюнки, які вже є на екрані: у тестах це не відбувається саме.
Future<void> _loadImages(WidgetTester tester) async {
  final elements = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final element in elements) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  late bool fontsReady;

  setUpAll(() async => fontsReady = await _loadFonts());

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('Головна, $theme', (tester) async {
      await tester.pumpRouterApp(
        brightness: brightness,
        stored: _userData(),
        now: () => _now,
      );
      await _loadImages(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_$theme.png'),
      );
    }, skip: !_fontsAvailable());

    testWidgets('Точка, $theme', (tester) async {
      await tester.pumpRouterApp(
        initialLocation: '/body/point/12M',
        brightness: brightness,
        stored: _userData(),
        now: () => _now,
      );
      await _loadImages(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/point_$theme.png'),
      );
      expect(fontsReady, isTrue);
    }, skip: !_fontsAvailable());
  }
}

/// Без шрифтів SDK знімки не збіглися б з еталонами, тому тести
/// пропускаються, а не падають.
bool _fontsAvailable() {
  final root = Platform.environment['FLUTTER_ROOT'];
  return root != null &&
      File(
        '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      ).existsSync();
}
