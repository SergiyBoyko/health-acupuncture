import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/json_utils.dart';
import 'user_models.dart';

/// Локальні дані користувача: історія пошуку, історія переглядів, обране.
///
/// Усе зберігається лише на пристрої. Кожен метод зміни повертає новий
/// список і записує його; пошкоджені дані тихо скидаються до порожніх.
class UserStore {
  UserStore(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const String searchKey = 'search_history_v1';
  static const String viewKey = 'view_history_v1';
  static const String favoritesKey = 'favorites_v1';

  static const int maxSearches = 20;
  static const int maxViews = 50;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  // ----- історія пошуку -----

  List<SearchEntry> loadSearches() => _load(searchKey, SearchEntry.fromJson);

  /// Додає запит нагору. Повтор (без урахування регістру) піднімається,
  /// а не дублюється.
  List<SearchEntry> addSearch(String query) {
    final trimmed = query.trim();
    final current = loadSearches();
    if (trimmed.isEmpty) return current;
    final key = trimmed.toLowerCase();
    final next = [
      SearchEntry(query: trimmed, at: _now()),
      ...current.where((e) => e.query.toLowerCase() != key),
    ].take(maxSearches).toList();
    _save(searchKey, next.map((e) => e.toJson()));
    return next;
  }

  List<SearchEntry> removeSearch(String query) {
    final next = loadSearches().where((e) => e.query != query).toList();
    _save(searchKey, next.map((e) => e.toJson()));
    return next;
  }

  List<SearchEntry> clearSearches() {
    unawaited(_prefs.remove(searchKey));
    return const [];
  }

  // ----- історія переглядів -----

  List<ViewEntry> loadViews() => _load(viewKey, ViewEntry.fromJson);

  /// Додає перегляд нагору без дублікатів.
  List<ViewEntry> addView(ViewType type, String id) {
    final next = [
      ViewEntry(type: type, id: id, at: _now()),
      ...loadViews().where((e) => e.type != type || e.id != id),
    ].take(maxViews).toList();
    _save(viewKey, next.map((e) => e.toJson()));
    return next;
  }

  List<ViewEntry> clearViews() {
    unawaited(_prefs.remove(viewKey));
    return const [];
  }

  // ----- обране -----

  /// Новіші зверху.
  List<FavoriteEntry> loadFavorites() =>
      _load(favoritesKey, FavoriteEntry.fromJson);

  List<FavoriteEntry> toggleFavorite(String code) {
    final current = loadFavorites();
    final next = current.any((e) => e.code == code)
        ? current.where((e) => e.code != code).toList()
        : [FavoriteEntry(code: code, at: _now()), ...current];
    _save(favoritesKey, next.map((e) => e.toJson()));
    return next;
  }

  // ----- зберігання -----

  List<T> _load<T>(String key, T Function(JsonMap json) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          fromJson(item as JsonMap),
      ];
    } on Object {
      // Пошкоджений запис: починаємо з чистого аркуша, а не падаємо.
      unawaited(_prefs.remove(key));
      return [];
    }
  }

  void _save(String key, Iterable<JsonMap> items) {
    unawaited(_prefs.setString(key, jsonEncode(items.toList())));
  }
}
