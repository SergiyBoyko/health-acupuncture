import 'dart:async';

import 'package:acupoints/app.dart';
import 'package:acupoints/data/content_repository.dart';
import 'package:acupoints/data/providers.dart';
import 'package:acupoints/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_content.dart';

void main() {
  Widget app(Future<ContentRepository> Function() load) => ProviderScope(
    overrides: [contentRepositoryProvider.overrideWith((ref) => load())],
    child: const AcupointsApp(),
  );

  testWidgets('показує застосунок після завантаження вмісту', (tester) async {
    final repository = loadTestContent();
    await tester.pumpWidget(app(() async => repository));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('показує індикатор, поки вміст завантажується', (tester) async {
    final completer = Completer<ContentRepository>();
    await tester.pumpWidget(app(() => completer.future));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    completer.complete(loadTestContent());
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('показує помилку і дає спробувати ще', (tester) async {
    var attempts = 0;
    final repository = loadTestContent();
    await tester.pumpWidget(
      app(() async {
        attempts++;
        if (attempts == 1) throw const FormatException('broken');
        return repository;
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не вдалося відкрити довідник'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Спробувати ще'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
