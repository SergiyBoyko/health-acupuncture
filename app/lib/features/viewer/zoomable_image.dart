import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/figure.dart';

/// Малюнок із масштабуванням щипком і подвійним дотиком.
///
/// Повідомляє через [onZoomChanged], чи збільшено малюнок: поки він
/// збільшений, горизонтальний рух пересуває малюнок, а не гортає сторінки.
class ZoomableImage extends StatefulWidget {
  const ZoomableImage({
    required this.figure,
    required this.onZoomChanged,
    super.key,
  });

  static const double maxScale = 5;
  static const double doubleTapScale = 2.5;

  final Figure figure;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<ZoomableImage> createState() => ZoomableImageState();
}

class ZoomableImageState extends State<ZoomableImage> {
  final TransformationController _controller = TransformationController();
  Offset _doubleTapPosition = Offset.zero;
  bool _zoomed = false;

  double get scale => _controller.value.getMaxScaleOnAxis();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransform);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTransform)
      ..dispose();
    super.dispose();
  }

  void _onTransform() {
    final zoomed = scale > 1.01;
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomChanged(zoomed);
  }

  void _onDoubleTap() {
    if (_zoomed) {
      _controller.value = Matrix4.identity();
      return;
    }
    // Збільшуємо навколо місця дотику.
    const scale = ZoomableImage.doubleTapScale;
    final position = _doubleTapPosition;
    _controller.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (scale - 1),
        -position.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        maxScale: ZoomableImage.maxScale,
        panEnabled: _zoomed,
        child: Center(
          child: AspectRatio(
            aspectRatio: widget.figure.aspectRatio,
            child: ColoredBox(
              color: colors.paper,
              child: Image.asset(
                widget.figure.asset,
                fit: BoxFit.contain,
                semanticLabel: widget.figure.caption,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colors.onPaper,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
