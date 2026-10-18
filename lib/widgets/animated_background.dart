/// Soft drifting colour blobs behind the expressive surfaces.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/vouch_theme.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    required this.child,
    this.intensity = 1,
  });

  final Widget child;
  final double intensity;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final colors = dark
        ? <Color>[
            VouchColors.indigo.withValues(alpha: 0.30),
            VouchColors.coral.withValues(alpha: 0.16),
            VouchColors.lime.withValues(alpha: 0.10),
          ]
        : <Color>[
            VouchColors.indigo.withValues(alpha: 0.16),
            VouchColors.coral.withValues(alpha: 0.14),
            VouchColors.lime.withValues(alpha: 0.34),
          ];

    return ColoredBox(
      color: scheme.surface,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = reduced ? 0.0 : _controller.value * math.pi * 2;
                  return Stack(
                    children: <Widget>[
                      _Blob(
                        color: colors[0],
                        size: 360 * widget.intensity,
                        alignment: Alignment(
                          -0.9 + math.sin(t) * 0.18,
                          -0.75 + math.cos(t * 0.8) * 0.12,
                        ),
                      ),
                      _Blob(
                        color: colors[1],
                        size: 300 * widget.intensity,
                        alignment: Alignment(
                          0.95 + math.cos(t * 0.7) * 0.14,
                          0.25 + math.sin(t * 0.9) * 0.16,
                        ),
                      ),
                      _Blob(
                        color: colors[2],
                        size: 260 * widget.intensity,
                        alignment: Alignment(
                          -0.5 + math.cos(t * 0.5) * 0.20,
                          0.95 + math.sin(t * 1.1) * 0.08,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.size,
    required this.alignment,
  });

  final Color color;
  final double size;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
            stops: const <double>[0, 1],
          ),
        ),
      ),
    );
  }
}
