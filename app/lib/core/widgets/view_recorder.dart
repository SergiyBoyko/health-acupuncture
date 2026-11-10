import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user/user_models.dart';
import '../../data/user/user_providers.dart';

/// Записує відкриття екрана в історію переглядів.
///
/// Ставиться лише навколо знайденого вмісту, тож неіснуючі коди в
/// історію не потрапляють.
class ViewRecorder extends ConsumerStatefulWidget {
  const ViewRecorder({
    required this.type,
    required this.id,
    required this.child,
    super.key,
  });

  final ViewType type;
  final String id;
  final Widget child;

  @override
  ConsumerState<ViewRecorder> createState() => _ViewRecorderState();
}

class _ViewRecorderState extends ConsumerState<ViewRecorder> {
  @override
  void initState() {
    super.initState();
    _record();
  }

  @override
  void didUpdateWidget(ViewRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type || oldWidget.id != widget.id) _record();
  }

  void _record() {
    final type = widget.type;
    final id = widget.id;
    // Після кадру: стан провайдера не можна міняти під час побудови.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(viewHistoryProvider.notifier).add(type, id);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
