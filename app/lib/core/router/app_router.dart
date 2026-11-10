import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/body/body_screen.dart';
import '../../features/body/segment_screen.dart';
import '../../features/glossary/glossary_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/point/point_screen.dart';
import '../../features/saved/saved_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/not_found_screen.dart';
import '../../features/symptoms/symptom_group_screen.dart';
import '../../features/symptoms/symptom_screen.dart';
import '../../features/symptoms/symptoms_screen.dart';
import '../../features/viewer/image_viewer_screen.dart';
import 'app_tab.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter();
  ref.onDispose(router.dispose);
  return router;
});

/// Сторінка повноекранного перегляду: поверх нижньої панелі, з плавною
/// появою замість зсуву.
CustomTransitionPage<void> _viewerPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      fullscreenDialog: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// Екрани, доступні з будь-якої вкладки. Кожна вкладка отримує власну копію
/// маршрутів, тому вони відкриваються в її стеку. Перегляд малюнків —
/// виняток: він іде в кореневий навігатор і закриває собою нижню панель.
List<RouteBase> _sharedRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    path: 'point/:code',
    builder: (context, state) =>
        PointScreen(code: PointCodeUrl.decode(state.pathParameters['code']!)),
    routes: [
      GoRoute(
        path: 'image/:figureId',
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _viewerPage(
          state,
          ImageViewerScreen.forPoint(
            code: PointCodeUrl.decode(state.pathParameters['code']!),
            figureId: state.pathParameters['figureId']!,
          ),
        ),
      ),
    ],
  ),
  GoRoute(
    path: 'symptom/:id',
    builder: (context, state) =>
        SymptomScreen(symptomId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: 'symptom-group/:id',
    builder: (context, state) =>
        SymptomGroupScreen(groupId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: 'search',
    builder: (context, state) =>
        SearchScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
  ),
  GoRoute(
    path: 'glossary',
    builder: (context, state) =>
        GlossaryScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
  ),
  GoRoute(
    path: 'segment/:id',
    builder: (context, state) =>
        SegmentScreen(segmentId: state.pathParameters['id']!),
    routes: [
      GoRoute(
        path: 'image/:figureId',
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _viewerPage(
          state,
          ImageViewerScreen.forSegment(
            segmentId: state.pathParameters['id']!,
            figureId: state.pathParameters['figureId']!,
          ),
        ),
      ),
    ],
  ),
];

GoRouter createRouter({String initialLocation = '/'}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  StatefulShellBranch branch(AppTab tab, Widget root) => StatefulShellBranch(
    routes: [
      GoRoute(
        path: tab.root,
        builder: (context, state) => tab == AppTab.saved
            ? SavedScreen(
                key: ValueKey(state.uri.queryParameters['tab']),
                initialTab: state.uri.queryParameters['tab'] == 'history'
                    ? SavedTab.history
                    : SavedTab.favorites,
              )
            : root,
        routes: _sharedRoutes(rootKey),
      ),
    ],
  );

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          branch(AppTab.home, const HomeScreen()),
          branch(AppTab.body, const BodyScreen()),
          branch(AppTab.symptoms, const SymptomsScreen()),
          branch(AppTab.saved, const SavedScreen()),
        ],
      ),
    ],
  );
}
