import 'package:acupoints/app.dart';
import 'package:acupoints/core/router/app_router.dart';
import 'package:acupoints/data/content_repository.dart';
import 'package:acupoints/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'test_content.dart';

extension PumpRouterApp on WidgetTester {
  /// Запускає весь застосунок зі справжнім вмістом і повертає його роутер.
  Future<GoRouter> pumpRouterApp({
    String initialLocation = '/',
    ContentRepository? repository,
  }) async {
    final repo = repository ?? loadTestContent();
    final router = createRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);
    await pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWith((ref) async => repo),
          routerProvider.overrideWithValue(router),
        ],
        child: const AcupointsApp(),
      ),
    );
    await pumpAndSettle();
    return router;
  }
}
