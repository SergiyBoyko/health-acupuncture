import 'json_utils.dart';

enum FigureKind { overview, detail }

/// Малюнок із джерела.
class Figure {
  const Figure({
    required this.id,
    required this.asset,
    required this.kind,
    required this.caption,
    required this.sourcePage,
    required this.segmentId,
    required this.pointCodes,
    required this.width,
    required this.height,
  });

  factory Figure.fromJson(JsonMap json) => Figure(
    id: json['id'] as String,
    asset: json['asset'] as String,
    kind: FigureKind.values.byName(json['kind'] as String),
    caption: json['caption'] as String,
    sourcePage: json['sourcePage'] as int,
    segmentId: json['segmentId'] as String,
    pointCodes: stringList(json['pointCodes']),
    width: json['width'] as int,
    height: json['height'] as int,
  );

  final String id;
  final String asset;
  final FigureKind kind;
  final String caption;
  final int sourcePage;
  final String segmentId;
  final List<String> pointCodes;
  final int width;
  final int height;

  double get aspectRatio => width / height;
}
