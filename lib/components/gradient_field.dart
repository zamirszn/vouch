/// Full-bleed atmospheric background: a state gradient, a slow breathing aura,
/// a soft horizon glow and a fine grain layer.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

import '../design/vouch_motion.dart';
import '../design/vouch_sequences.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';

class GradientField extends StatelessWidget {
  const GradientField({
    super.key,
    required this.tone,
    this.child,
    this.animate = true,
    this.light,
  });

  final VouchTone tone;
  final Widget? child;
  final bool animate;
  final bool? light;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final isDark = light == null ? theme.isDark : !light!;
    final reduce = VouchMotion.reduced(context);
    final colors = VouchGradients.forTone(tone, dark: isDark);
    final glow = VouchGradients.glowFor(tone, dark: isDark);

    Widget paint(double breath) => RepaintBoundary(
          child: CustomPaint(
            painter: _AtmospherePainter(
              colors: colors,
              glow: glow,
              breath: breath,
              grain: isDark ? 0.030 : 0.018,
              vignette: isDark ? 0.55 : 0.16,
            ),
            child: const SizedBox.expand(),
          ),
        );

    final staticField = paint(0.35);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (!animate || reduce)
          staticField
        else
          SequenceMotionBuilder<int, double>(
            sequence: VouchSequences.breath,
            converter: MotionConverter.single,
            playing: true,
            builder: (context, value, phase, _) => paint(value),
          ),
        ?child,
      ],
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter({
    required this.colors,
    required this.glow,
    required this.breath,
    required this.grain,
    required this.vignette,
  }) : _grainPoints = _buildGrain();

  final List<Color> colors;
  final Color glow;
  final double breath;
  final double grain;
  final double vignette;

  static const int _grainCount = 900;

  static List<Offset> _buildGrain() {
    final random = math.Random(19);
    return List<Offset>.generate(
      _grainCount,
      (_) => Offset(random.nextDouble(), random.nextDouble()),
      growable: false,
    );
  }

  final List<Offset> _grainPoints;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final base = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.15, 0),
        Offset(size.width * 0.9, size.height),
        <Color>[colors[0], colors[1], colors[2]],
        <double>[0, 0.52, 1],
      );
    canvas.drawRect(rect, base);

    // Breathing aura in the upper third.
    final auraCenter = Offset(
      size.width * (0.74 + breath * 0.05),
      size.height * (0.18 + breath * 0.03),
    );
    final auraRadius = size.longestSide * (0.62 + breath * 0.06);
    final aura = Paint()
      ..shader = ui.Gradient.radial(
        auraCenter,
        auraRadius,
        <Color>[
          glow.withValues(alpha: 0.34 - breath * 0.07),
          glow.withValues(alpha: 0.10 - breath * 0.03),
          glow.withValues(alpha: 0),
        ],
        <double>[0, 0.45, 1],
      );
    canvas.drawRect(rect, aura);

    // A second, cooler lift from the lower left.
    final lowCenter = Offset(size.width * 0.08, size.height * 0.86);
    final low = Paint()
      ..shader = ui.Gradient.radial(
        lowCenter,
        size.longestSide * 0.7,
        <Color>[
          glow.withValues(alpha: 0.10 + breath * 0.04),
          glow.withValues(alpha: 0),
        ],
      );
    canvas.drawRect(rect, low);

    // Grain.
    if (grain > 0) {
      final grainPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: grain)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      final points = <Offset>[
        for (final pt in _grainPoints)
          Offset(pt.dx * size.width, pt.dy * size.height),
      ];
      canvas.drawPoints(ui.PointMode.points, points, grainPaint);
    }

    // Bottom vignette anchors the content.
    final shade = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, size.height * 0.45),
        Offset(size.width / 2, size.height),
        <Color>[
          const Color(0x00000000),
          const Color(0xFF000000).withValues(alpha: vignette),
        ],
      );
    canvas.drawRect(rect, shade);
  }

  @override
  bool shouldRepaint(_AtmospherePainter old) =>
      old.breath != breath ||
      old.colors != colors ||
      old.glow != glow ||
      old.grain != grain ||
      old.vignette != vignette;
}
