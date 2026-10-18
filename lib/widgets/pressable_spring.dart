/// A springy press response for cards and custom buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motor/motor.dart';

import '../theme/vouch_motion.dart';

class PressableSpring extends StatefulWidget {
  const PressableSpring({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = true,
    this.pressedScale = 0.955,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool haptic;
  final double pressedScale;
  final bool enabled;

  @override
  State<PressableSpring> createState() => _PressableSpringState();
}

class _PressableSpringState extends State<PressableSpring> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (!widget.enabled) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onLongPress: widget.onLongPress,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) {
                HapticFeedback.selectionClick();
              }
              widget.onTap!();
            },
      child: reduced
          ? widget.child
          : SingleMotionBuilder(
              value: _pressed ? 1.0 : 0.0,
              motion: VouchMotion.spatialFast,
              builder: (context, value, child) {
                final v = value.clamp(0.0, 1.0).toDouble();
                return Transform.scale(
                  scale: 1 - (1 - widget.pressedScale) * v,
                  child: child,
                );
              },
              child: widget.child,
            ),
    );
  }
}
