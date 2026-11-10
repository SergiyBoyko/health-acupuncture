import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_tab.dart';
import '../../core/widgets/point_list_tile.dart';
import '../../data/providers.dart';
import '../shell/not_found_screen.dart';

/// Точки одного сегмента. Схеми, сортування й фільтр — блок 6 плану.
class SegmentScreen extends ConsumerWidget {
  const SegmentScreen({required this.segmentId, super.key});

  final String segmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(repositoryProvider);
    final segment = repository.segment(segmentId);
    if (segment == null) return const NotFoundScreen();

    final points = repository.pointsOfSegment(segmentId);
    return Scaffold(
      appBar: AppBar(title: Text(segment.title)),
      body: ListView.separated(
        itemCount: points.length,
        separatorBuilder: (context, index) => const Divider(indent: 16),
        itemBuilder: (context, index) {
          final point = points[index];
          final figures = repository.figuresOfPoint(point);
          return PointListTile(
            point: point,
            figure: figures.isEmpty ? null : figures.first,
            onTap: () => context.openPoint(point.code),
          );
        },
      ),
    );
  }
}
