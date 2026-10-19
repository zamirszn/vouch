/// A tappable wrapper with a spring press. Every interactive surface in the
/// app uses this instead of Material's InkWell.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

import '../design/vouch_motion.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.972,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale reached while held.
  final double scale;
  final bool haptic;
  final HitTestBehavior behavior;
  final String? semanticLabel;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _live => widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _down(TapDownDetails _) {
    if (!_live) return;
    setState(() => _pressed = true);
  }

  void _up() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = VouchMotion.reduced(context);
    return Semantics(
      button: widget.onTap != null,
      enabled: _live,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _down,
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        onTap: _live
            ? () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap?.call();
              }
            : null,
        onLongPress: _live && widget.onLongPress != null
            ? () {
                if (widget.haptic) HapticFeedback.mediumImpact();
                widget.onLongPress?.call();
              }
            : null,
        child: reduce
            ? widget.child
            : SingleMotionBuilder(
                value: _pressed ? 1 : 0,
                motion: _pressed ? VouchMotion.press : VouchMotion.release,
                builder: (context, value, child) => Transform.scale(
                  scale: 1 - (1 - widget.scale) * value,
                  child: child,
                ),
                child: widget.child,
              ),
      ),
    );
  }
}
