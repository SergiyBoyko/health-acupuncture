import 'package:acupoints/app.dart';
import 'package:acupoints/core/router/app_router.dart';
import 'package:acupoints/data/content_repository.dart';
import 'package:acupoints/data/providers.dart';
import 'package:acupoints/data/user/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_content.dart';

bool _preferencesReady = false;

extension PumpRouterApp on WidgetTester {
  /// Запускає весь застосунок зі справжнім вмістом і повертає його роутер.
  Future<GoRouter> pumpRouterApp({
    String initialLocation = '/',
    ContentRepository? repository,
    Size size = const Size(412, 915),
    double textScale = 1,
    Brightness brightness = Brightness.light,
    Map<String, Object>? stored,
    DateTime Function()? now,
  }) async {
    // Типовий телефон замість стандартного для тестів 800×600.
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    platformDispatcher.textScaleFactorTestValue = textScale;
    platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(view.reset);
    addTearDown(platformDispatcher.clearAllTestValues);

    // Без [stored] дані користувача лишаються від попереднього запуску в
    // цьому ж тесті — так перевіряється збереження між перезапусками.
    if (stored != null || !_preferencesReady) {
      SharedPreferences.setMockInitialValues(stored ?? {});
      _preferencesReady = true;
      addTearDown(() => _preferencesReady = false);
    }
    final preferences = await SharedPreferences.getInstance();
    final repo = repository ?? loadTestContent();
    final router = createRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);
    await pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWith((ref) async => repo),
          routerProvider.overrideWithValue(router),
          sharedPreferencesProvider.overrideWithValue(preferences),
          if (now != null) clockProvider.overrideWithValue(now),
        ],
        child: const AcupointsApp(),
      ),
    );
    await pumpAndSettle();
    return router;
  }
}
