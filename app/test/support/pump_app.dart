import 'package:acupoints/core/l10n.dart';
import 'package:acupoints/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  /// Показує [child] у темі та локалізації застосунку.
  Future<void> pumpApp(
    Widget child, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Size? size,
  }) async {
    if (size != null) {
      view.physicalSize = size;
      view.devicePixelRatio = 1;
      addTearDown(view.reset);
    }
    await pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? AppTheme.light()
            : AppTheme.dark(),
        locale: const Locale('uk'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: widget!,
        ),
        home: Scaffold(body: child),
      ),
    );
    await pump();
  }
}
