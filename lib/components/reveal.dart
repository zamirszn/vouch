/// Staggered entrance used by page sections.
library;

import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

import '../design/vouch_motion.dart';

class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
  });

  final Widget child;

  /// Position in the entrance stagger; each step adds ~70 ms.
  final int index;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 50 + widget.index * 70);
    Future<void>.delayed(delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (VouchMotion.reduced(context)) return widget.child;
    return SingleMotionBuilder(
      value: _shown ? 1 : 0,
      from: 0,
      motion: _shown ? VouchMotion.enter : VouchMotion.fade,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
