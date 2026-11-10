import 'package:flutter/material.dart';

/// Кореневий віджет застосунку.
///
/// Тема, маршрутизація та локалізація підключаються в наступних блоках плану;
/// поки що це каркас, який підтверджує, що проєкт збирається.
class AcupointsApp extends StatelessWidget {
  const AcupointsApp({super.key});

  static const Color seedColor = Color(0xFF2F6F62);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Точки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(
        body: Center(child: Text('Точки надавлювання')),
      ),
    );
  }
}
