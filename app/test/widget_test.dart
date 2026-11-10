import 'dart:async';

import 'package:acupoints/app.dart';
import 'package:acupoints/data/content_repository.dart';
import 'package:acupoints/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_content.dart';

void main() {
  Widget app(Future<ContentRepository> Function() load) => ProviderScope(
    overrides: [contentRepositoryProvider.overrideWith((ref) => load())],
    child: const AcupointsApp(),
  );

  testWidgets('показує вміст після завантаження', (tester) async {
    final repository = loadTestContent();
    await tester.pumpWidget(app(() async => repository));
    await tester.pump();

    expect(find.text('Точки надавлювання'), findsOneWidget);
    expect(find.text('119 точок'), findsOneWidget);
  });

  testWidgets('показує індикатор, поки вміст завантажується', (tester) async {
    final completer = Completer<ContentRepository>();
    await tester.pumpWidget(app(() => completer.future));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Точки надавлювання'), findsNothing);

    completer.complete(loadTestContent());
    await tester.pump();
    await tester.pump();
    expect(find.text('Точки надавлювання'), findsOneWidget);
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
    await tester.pump();

    expect(find.text('Не вдалося відкрити довідник'), findsOneWidget);

    await tester.tap(find.text('Спробувати ще'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('Точки надавлювання'), findsOneWidget);
  });
}
