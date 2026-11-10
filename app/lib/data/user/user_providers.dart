import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_models.dart';
import 'user_store.dart';

/// Сховище налаштувань. Справжній екземпляр підставляється в `main`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in ProviderScope'),
);

/// Поточний час; у тестах підміняється.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final userStoreProvider = Provider<UserStore>(
  (ref) => UserStore(
    ref.watch(sharedPreferencesProvider),
    now: ref.watch(clockProvider),
  ),
);

class SearchHistoryNotifier extends Notifier<List<SearchEntry>> {
  UserStore get _store => ref.read(userStoreProvider);

  @override
  List<SearchEntry> build() => ref.watch(userStoreProvider).loadSearches();

  void add(String query) => state = _store.addSearch(query);

  void remove(String query) => state = _store.removeSearch(query);

  void clear() => state = _store.clearSearches();
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<SearchEntry>>(
      SearchHistoryNotifier.new,
    );

class ViewHistoryNotifier extends Notifier<List<ViewEntry>> {
  UserStore get _store => ref.read(userStoreProvider);

  @override
  List<ViewEntry> build() => ref.watch(userStoreProvider).loadViews();

  void add(ViewType type, String id) => state = _store.addView(type, id);

  void clear() => state = _store.clearViews();
}

final viewHistoryProvider =
    NotifierProvider<ViewHistoryNotifier, List<ViewEntry>>(
      ViewHistoryNotifier.new,
    );

class FavoritesNotifier extends Notifier<List<FavoriteEntry>> {
  @override
  List<FavoriteEntry> build() => ref.watch(userStoreProvider).loadFavorites();

  /// Повертає `true`, якщо точка тепер в обраному.
  bool toggle(String code) {
    state = ref.read(userStoreProvider).toggleFavorite(code);
    return state.any((e) => e.code == code);
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<FavoriteEntry>>(
      FavoritesNotifier.new,
    );

/// Коди обраних точок — для позначок у списках.
final favoriteCodesProvider = Provider<Set<String>>(
  (ref) => {for (final entry in ref.watch(favoritesProvider)) entry.code},
);
