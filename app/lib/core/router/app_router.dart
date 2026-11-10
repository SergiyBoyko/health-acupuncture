import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/body/body_screen.dart';
import '../../features/body/segment_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/point/point_screen.dart';
import '../../features/saved/saved_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/not_found_screen.dart';
import '../../features/symptoms/symptoms_screen.dart';
import 'app_tab.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter();
  ref.onDispose(router.dispose);
  return router;
});

/// Екрани, доступні з будь-якої вкладки. Кожна вкладка отримує власну копію
/// маршрутів, тому вони відкриваються в її стеку.
List<RouteBase> _sharedRoutes() => [
  GoRoute(
    path: 'point/:code',
    builder: (context, state) =>
        PointScreen(code: PointCodeUrl.decode(state.pathParameters['code']!)),
  ),
  GoRoute(
    path: 'segment/:id',
    builder: (context, state) =>
        SegmentScreen(segmentId: state.pathParameters['id']!),
  ),
];

StatefulShellBranch _branch(AppTab tab, Widget root) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: tab.root,
      builder: (context, state) => root,
      routes: _sharedRoutes(),
    ),
  ],
);

GoRouter createRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        _branch(AppTab.home, const HomeScreen()),
        _branch(AppTab.body, const BodyScreen()),
        _branch(AppTab.symptoms, const SymptomsScreen()),
        _branch(AppTab.saved, const SavedScreen()),
      ],
    ),
  ],
);
