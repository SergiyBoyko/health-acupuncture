import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/router/app_tab.dart';
import '../../core/widgets/section_header.dart';
import '../../data/user/user_providers.dart';

/// Налаштування: тема і відомості про джерело.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final current = ref.watch(themeModeProvider);

    final themes = [
      (ThemeMode.system, l10n.themeSystem, Icons.brightness_auto_outlined),
      (ThemeMode.light, l10n.themeLight, Icons.light_mode_outlined),
      (ThemeMode.dark, l10n.themeDark, Icons.dark_mode_outlined),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          SectionHeader(l10n.theme),
          for (final (mode, label, icon) in themes)
            Semantics(
              inMutuallyExclusiveGroup: true,
              selected: mode == current,
              child: ListTile(
                minTileHeight: 56,
                leading: Icon(icon),
                title: Text(label),
                trailing: mode == current
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () => ref.read(themeModeProvider.notifier).set(mode),
              ),
            ),
          const Divider(),
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutSource),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.openAbout(),
          ),
        ],
      ),
    );
  }
}
