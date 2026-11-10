import 'package:flutter/material.dart';

import 'core/widgets/content_gate.dart';

/// Кореневий віджет застосунку.
///
/// Тема, маршрутизація та локалізація підключаються в наступних блоках плану;
/// поки що застосунок завантажує вміст і показує його обсяг.
class AcupointsApp extends StatelessWidget {
  const AcupointsApp({super.key});

  static const Color seedColor = Color(0xFF2F6F62);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Точки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seedColor)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),
      home: ContentGate(
        builder: (context, repository) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Точки надавлювання',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Сегментів: ${repository.segments.length} · '
                  'точок: ${repository.points.length} · '
                  'симптомів: ${repository.symptoms.length}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
