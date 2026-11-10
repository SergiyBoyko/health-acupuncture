import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import 'disclaimer_content.dart';

/// Застереження (повторно) і відомості про джерело.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final repository = ref.watch(repositoryProvider);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleMedium),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: [
          heading(l10n.disclaimerHeading),
          const DisclaimerContent(),
          heading(l10n.sourceHeading),
          Text(repository.meta.source, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.sourceContents(
              l10n.pointsCount(repository.points.length),
              l10n.symptomEntriesCount(repository.symptoms.length),
              l10n.termsCount(repository.glossary.length),
            ),
            style: muted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.sourceTranscription, style: muted),
          heading(l10n.privacyHeading),
          Text(l10n.privacyMessage, style: muted),
        ],
      ),
    );
  }
}
