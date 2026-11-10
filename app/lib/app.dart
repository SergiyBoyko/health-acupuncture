import 'package:flutter/material.dart';

import 'core/l10n.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/content_gate.dart';

/// Кореневий віджет застосунку.
///
/// Маршрутизація підключається в наступному блоці плану; поки що застосунок
/// завантажує вміст і показує його обсяг.
class AcupointsApp extends StatelessWidget {
  const AcupointsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('uk'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ContentGate(
        builder: (context, repository) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(context.l10n.pointsCount(repository.points.length)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
