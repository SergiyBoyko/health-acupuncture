import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/content_gate.dart';
import 'data/user/user_providers.dart';
import 'features/settings/disclaimer_screen.dart';

/// Кореневий віджет застосунку: тема, локалізація, маршрутизація.
///
/// Екрани показуються лише після завантаження вмісту довідника і
/// підтвердження застереження.
class AcupointsApp extends ConsumerWidget {
  const AcupointsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disclaimerAccepted = ref.watch(disclaimerAcceptedProvider);
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('uk'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => ContentGate(
        // Перший запуск: спершу застереження, потім застосунок.
        builder: (context, repository) => disclaimerAccepted
            ? child!
            : DisclaimerScreen(
                onAccept: () =>
                    ref.read(disclaimerAcceptedProvider.notifier).accept(),
              ),
      ),
    );
  }
}
