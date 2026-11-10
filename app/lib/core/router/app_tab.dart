import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Вкладки нижньої панелі. Порядок збігається з порядком гілок роутера.
enum AppTab {
  home('/'),
  body('/body'),
  symptoms('/symptoms'),
  saved('/saved');

  const AppTab(this.root);

  /// Шлях кореневого екрана вкладки.
  final String root;

  /// Шлях вкладеного екрана в цій вкладці: `point/12M` → `/body/point/12M`.
  String child(String subPath) => this == home ? '/$subPath' : '$root/$subPath';

  /// Вкладка, якій належить [path].
  static AppTab ofPath(String path) {
    for (final tab in const [body, symptoms, saved]) {
      if (path == tab.root || path.startsWith('${tab.root}/')) return tab;
    }
    return home;
  }
}

/// Код точки ↔ сегмент URL (`49½` не годиться для адреси).
abstract final class PointCodeUrl {
  static String encode(String code) => code.replaceAll('½', '-half');

  static String decode(String segment) => segment.replaceAll('-half', '½');
}

/// Переходи до спільних екранів. Екран відкривається в стеку поточної
/// вкладки, тож нижня панель лишається на місці, а «назад» веде туди,
/// звідки прийшли.
extension AppNavigation on BuildContext {
  AppTab get currentTab => AppTab.ofPath(GoRouterState.of(this).uri.path);

  void openPoint(String code) =>
      push(currentTab.child('point/${PointCodeUrl.encode(code)}'));

  void openSegment(String segmentId) =>
      push(currentTab.child('segment/$segmentId'));
}
