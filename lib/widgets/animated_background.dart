/// The paper: a measured grid with a few oversized technical marks. Static
/// and graphic rather than soft — the content moves, the sheet stays put.
library;

import 'package:flutter/material.dart';

import '../theme/vouch_theme.dart';
import 'soul.dart';

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({
    super.key,
    required this.child,
    this.intensity = 1,
  });

  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final mark = scheme.onSurface.withValues(
      alpha: (dark ? 0.055 : 0.07) * intensity,
    );

    return ColoredBox(
      color: scheme.surface,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: GraphPaper(spacing: 22, alpha: 0.05)),
          Positioned(
            right: -110,
            top: 120,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: mark, width: 1.2),
                ),
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: 60,
            child: IgnorePointer(
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: mark, width: 1.2),
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 76,
            child: IgnorePointer(
              child: Text(
                '(FIG. 01)',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  letterSpacing: 1.4,
                  color: VouchColors.mist.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
