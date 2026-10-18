/// Staggered spring entrance used across screens.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

import '../theme/vouch_motion.dart';

class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 28,
    this.scaleFrom = 0.96,
    this.motion = VouchMotion.spatialDefault,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final double scaleFrom;
  final Motion motion;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return widget.child;
    }

    return SingleMotionBuilder(
      value: _visible ? 1.0 : 0.0,
      from: 0.0,
      motion: widget.motion,
      builder: (context, value, child) {
        final v = value.clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - v)),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * v,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
