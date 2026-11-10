import 'package:flutter/material.dart';

/// Кольори, яких немає в [ColorScheme]: підкладка сканів і блок рукописних
/// нотаток.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.onPaper,
    required this.noteContainer,
    required this.onNoteContainer,
  });

  /// Підкладка під малюнками. Однакова в обох темах: скани мають жовтуватий
  /// папір і темні лінії, тож у темній темі їх не інвертуємо.
  static const Color paperColor = Color(0xFFF3E6C8);
  static const Color onPaperColor = Color(0xFF4A3B1C);

  static const AppColors light = AppColors(
    paper: paperColor,
    onPaper: onPaperColor,
    noteContainer: Color(0xFFFBEBC8),
    onNoteContainer: Color(0xFF4F3A00),
  );

  static const AppColors dark = AppColors(
    paper: paperColor,
    onPaper: onPaperColor,
    noteContainer: Color(0xFF4A3A10),
    onNoteContainer: Color(0xFFF7E2AE),
  );

  final Color paper;
  final Color onPaper;
  final Color noteContainer;
  final Color onNoteContainer;

  @override
  AppColors copyWith({
    Color? paper,
    Color? onPaper,
    Color? noteContainer,
    Color? onNoteContainer,
  }) => AppColors(
    paper: paper ?? this.paper,
    onPaper: onPaper ?? this.onPaper,
    noteContainer: noteContainer ?? this.noteContainer,
    onNoteContainer: onNoteContainer ?? this.onNoteContainer,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      onPaper: Color.lerp(onPaper, other.onPaper, t)!,
      noteContainer: Color.lerp(noteContainer, other.noteContainer, t)!,
      onNoteContainer: Color.lerp(onNoteContainer, other.onNoteContainer, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
