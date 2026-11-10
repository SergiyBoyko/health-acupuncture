import 'dart:convert';

import 'package:acupoints/data/user/user_models.dart';
import 'package:acupoints/data/user/user_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late DateTime clock;

  Future<UserStore> storeWith([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    prefs = await SharedPreferences.getInstance();
    return UserStore(
      prefs,
      now: () {
        // Кожен виклик на хвилину пізніше: порядок записів однозначний.
        clock = clock.add(const Duration(minutes: 1));
        return clock;
      },
    );
  }

  setUp(() => clock = DateTime(2026, 11, 10, 12));

  group('історія пошуку', () {
    test('порожня на початку', () async {
      final store = await storeWith();
      expect(store.loadSearches(), isEmpty);
    });

    test('новіший запит зверху, пробіли обрізаються', () async {
      final store = await storeWith();
      store.addSearch('мозг');
      final result = store.addSearch('  12M ');

      expect(result.map((e) => e.query), ['12M', 'мозг']);
      expect(result.first.at.isAfter(result.last.at), isTrue);
    });

    test('порожній запит не зберігається', () async {
      final store = await storeWith();
      store.addSearch('мозг');

      expect(store.addSearch('   ').map((e) => e.query), ['мозг']);
      expect(store.loadSearches(), hasLength(1));
    });

    test(
      'повтор піднімається нагору без дубліката, регістр неважливий',
      () async {
        final store = await storeWith();
        store.addSearch('мозг');
        store.addSearch('12M');
        final result = store.addSearch('МОЗГ');

        expect(result.map((e) => e.query), ['МОЗГ', '12M']);
      },
    );

    test('зберігає не більше 20 останніх', () async {
      final store = await storeWith();
      for (var i = 1; i <= 25; i++) {
        store.addSearch('запит $i');
      }
      final result = store.loadSearches();

      expect(result, hasLength(UserStore.maxSearches));
      expect(result.first.query, 'запит 25');
      expect(result.last.query, 'запит 6');
    });

    test('видалення одного запиту та очищення', () async {
      final store = await storeWith();
      store.addSearch('мозг');
      store.addSearch('12M');

      expect(store.removeSearch('мозг').map((e) => e.query), ['12M']);
      expect(store.clearSearches(), isEmpty);
      expect(store.loadSearches(), isEmpty);
      expect(prefs.containsKey(UserStore.searchKey), isFalse);
    });

    test('переживає перезапуск', () async {
      final store = await storeWith();
      store.addSearch('мозг');
      store.addSearch('12M');

      final reopened = UserStore(await SharedPreferences.getInstance());
      expect(reopened.loadSearches().map((e) => e.query), ['12M', 'мозг']);
    });
  });

  group('історія переглядів', () {
    test('новіший зверху, без дублікатів', () async {
      final store = await storeWith();
      store.addView(ViewType.point, '12M');
      store.addView(ViewType.segment, 'golova');
      final result = store.addView(ViewType.point, '12M');

      expect(result.map((e) => '${e.type.name}:${e.id}'), [
        'point:12M',
        'segment:golova',
      ]);
    });

    test('однаковий ідентифікатор різного типу — різні записи', () async {
      final store = await storeWith();
      store.addView(ViewType.segment, 'golova');
      final result = store.addView(ViewType.symptom, 'golova');

      expect(result, hasLength(2));
    });

    test('зберігає не більше 50 останніх', () async {
      final store = await storeWith();
      for (var i = 1; i <= 60; i++) {
        store.addView(ViewType.point, '$i');
      }
      final result = store.loadViews();

      expect(result, hasLength(UserStore.maxViews));
      expect(result.first.id, '60');
      expect(result.last.id, '11');
    });

    test('очищення не чіпає обране і запити', () async {
      final store = await storeWith();
      store.addView(ViewType.point, '12M');
      store.addSearch('мозг');
      store.toggleFavorite('2B');

      expect(store.clearViews(), isEmpty);
      expect(store.loadViews(), isEmpty);
      expect(store.loadSearches(), hasLength(1));
      expect(store.loadFavorites(), hasLength(1));
    });
  });

  group('обране', () {
    test('додавання: новіші зверху', () async {
      final store = await storeWith();
      store.toggleFavorite('12M');
      final result = store.toggleFavorite('2B');

      expect(result.map((e) => e.code), ['2B', '12M']);
    });

    test('повторний виклик прибирає', () async {
      final store = await storeWith();
      store.toggleFavorite('12M');
      store.toggleFavorite('2B');

      expect(store.toggleFavorite('12M').map((e) => e.code), ['2B']);
      expect(store.loadFavorites().map((e) => e.code), ['2B']);
    });

    test('переживає перезапуск', () async {
      final store = await storeWith();
      store.toggleFavorite('49½');

      final reopened = UserStore(await SharedPreferences.getInstance());
      expect(reopened.loadFavorites().single.code, '49½');
    });
  });

  group('пошкоджені дані', () {
    final cases = {
      'не JSON': 'це не json',
      'не список': '{"query": "мозг"}',
      'елемент не об\'єкт': '["мозг"]',
      'немає поля': '[{"at": "2026-11-10T12:00:00.000"}]',
      'неправильна дата': '[{"query": "мозг", "at": "вчора"}]',
      'неправильний тип поля':
          '[{"query": 5, "at": "2026-11-10T12:00:00.000"}]',
    };

    for (final MapEntry(key: name, value: raw) in cases.entries) {
      test('запити: $name → порожньо, запис скинуто', () async {
        final store = await storeWith({UserStore.searchKey: raw});

        expect(store.loadSearches(), isEmpty);
        expect(prefs.containsKey(UserStore.searchKey), isFalse);
        // Після скидання сховище працює як зазвичай.
        expect(store.addSearch('мозг').single.query, 'мозг');
      });
    }

    test('перегляди з невідомим типом скидаються', () async {
      final store = await storeWith({
        UserStore.viewKey: jsonEncode([
          {'type': 'figure', 'id': 'g01', 'at': '2026-11-10T12:00:00.000'},
        ]),
      });

      expect(store.loadViews(), isEmpty);
      expect(store.addView(ViewType.point, '12M'), hasLength(1));
    });

    test('пошкодження одного списку не зачіпає інші', () async {
      final store = await storeWith({
        UserStore.favoritesKey: 'зламано',
        UserStore.searchKey: jsonEncode([
          {'query': 'мозг', 'at': '2026-11-10T12:00:00.000'},
        ]),
      });

      expect(store.loadFavorites(), isEmpty);
      expect(store.loadSearches().single.query, 'мозг');
    });
  });
}
